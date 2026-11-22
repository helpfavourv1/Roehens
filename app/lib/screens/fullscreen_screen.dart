import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/app/live_sessions.dart';
import 'package:roehens/core/contracts/snapshot_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/zoom_math.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/fullscreen_controls.dart';
import 'package:roehens/widgets/ptz_pad.dart';
import 'package:roehens/widgets/ptz_speed_control.dart';
import 'package:roehens/widgets/snapshot_flash.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// Opens [cameraId] fullscreen. [fromLive] is true when the grid is behind
/// it, so auto-cycle goes back to the grid when the viewer closes.
Future<void> openFullscreen(
  BuildContext context,
  String cameraId, {
  required bool fromLive,
}) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) =>
          FullscreenScreen(cameraId: cameraId, fromLive: fromLive),
    ),
  );
}

/// The immersive viewer: one camera, digital zoom, PTZ, mute, snapshot,
/// quality, picture-in-picture, and a swipe or button to the next camera.
class FullscreenScreen extends StatefulWidget {
  const FullscreenScreen({
    super.key,
    required this.cameraId,
    required this.fromLive,
  });

  final String cameraId;
  final bool fromLive;

  @override
  State<FullscreenScreen> createState() => _FullscreenScreenState();
}

class _FullscreenScreenState extends State<FullscreenScreen> {
  late String _cameraId = widget.cameraId;
  final ValueNotifier<ZoomState> _zoom = ValueNotifier<ZoomState>(
    ZoomState.reset,
  );
  final ValueNotifier<bool> _muted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _lowQuality = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _ptzShown = ValueNotifier<bool>(false);
  final ValueNotifier<double> _ptzSpeed = ValueNotifier<double>(0.5);
  final ValueNotifier<int> _flash = ValueNotifier<int>(0);
  final ValueNotifier<PlayerState> _noSession = ValueNotifier<PlayerState>(
    const PlayerConnecting(),
  );

  final Map<String, CameraCredentials> _credentials =
      <String, CameraCredentials>{};
  final Map<String, bool> _ptzSupport = <String, bool>{};
  Camera? _lastPtzCamera;
  Offset _gestureStart = Offset.zero;
  double _swipe = 0;
  double _lastScale = 1;
  int _pointers = 0;
  bool _started = false;
  late AppProviders _app;
  VoidCallback? _tickListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _app = AppScope.of(context);
    unawaited(_app.orientation.setImmersive(immersive: true));
    if (_app.settings.value.keepAwake) {
      unawaited(_app.wake.setAwake(true));
    }
    _app.autoCycle.setViewing(viewing: true);
    _tickListener = () => _step(1);
    _app.autoCycle.ticks.addListener(_tickListener!);
    _app.live.focus(_cameraId);
  }

  @override
  void dispose() {
    final VoidCallback? listener = _tickListener;
    if (listener != null) {
      _app.autoCycle.ticks.removeListener(listener);
      // Back to the grid, or stop cycling when there is no grid behind.
      _app.autoCycle.setViewing(viewing: widget.fromLive);
      _app.live.focus(null);
      unawaited(_app.orientation.setImmersive(immersive: false));
      unawaited(_app.wake.setAwake(false));
      final Camera? moved = _lastPtzCamera;
      if (moved != null) {
        // Stop any motion; the viewer is closing, so a failure is not shown.
        unawaited(
          _app.ptz.execute(
            camera: moved,
            credentials: _credentials[moved.id] ?? CameraCredentials.none,
            command: const PtzCommand.stop(),
          ),
        );
      }
    }
    for (final ChangeNotifier notifier in <ChangeNotifier>[
      _zoom,
      _muted,
      _lowQuality,
      _ptzShown,
      _ptzSpeed,
      _flash,
      _noSession,
      _rebuild,
    ]) {
      notifier.dispose();
    }
    super.dispose();
  }

  List<String> get _order {
    return _app.layout.orderedIds(_app.cameras.value.cameras);
  }

  void _step(int direction) {
    final List<String> ids = _order;
    if (ids.length < 2 || !mounted) {
      return;
    }
    final int index = ids.indexOf(_cameraId);
    final String next = ids[(index + direction + ids.length) % ids.length];
    _zoom.value = ZoomState.reset;
    _ptzShown.value = false;
    _lowQuality.value = false;
    _muted.value = false;
    _cameraId = next;
    _app.live.focus(next);
    _app.autoCycle.userInteracted();
    _rebuild.value++;
  }

  final ValueNotifier<int> _rebuild = ValueNotifier<int>(0);

  Future<CameraCredentials> _credentialsOf(Camera camera) async {
    final CameraCredentials? known = _credentials[camera.id];
    if (known != null) {
      return known;
    }
    final CameraCredentials fetched =
        (await _app.repository.credentialsFor(camera.id)).valueOrNull ??
        CameraCredentials.none;
    _credentials[camera.id] = fetched;
    return fetched;
  }

  Future<void> _sendPtz(Camera camera, PtzCommand command) async {
    _lastPtzCamera = camera;
    final Result<void> result = await _app.ptz.execute(
      camera: camera,
      credentials: await _credentialsOf(camera),
      command: command,
    );
    final AppError? error = result.errorOrNull;
    if (error != null && mounted) {
      AppToast.show(
        context,
        message: errorMessage(AppLocalizations.of(context), error),
        bottomOffset: AppSpacing.xl,
      );
    }
  }

  Future<void> _togglePtz(Camera camera) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_ptzShown.value) {
      _ptzShown.value = false;
      return;
    }
    if (!camera.onvifEnabled) {
      AppToast.show(
        context,
        message: l10n.ptzNeedsOnvif,
        bottomOffset: AppSpacing.xl,
      );
      return;
    }
    bool? supported = _ptzSupport[camera.id];
    if (supported == null) {
      final Result<bool> result = await _app.ptz.supportsPtz(
        camera: camera,
        credentials: await _credentialsOf(camera),
      );
      if (!mounted) {
        return;
      }
      final AppError? error = result.errorOrNull;
      if (error != null) {
        AppToast.show(
          context,
          message: errorMessage(l10n, error),
          bottomOffset: AppSpacing.xl,
        );
        return;
      }
      supported = result.valueOrNull ?? false;
      _ptzSupport[camera.id] = supported;
    }
    if (!supported) {
      AppToast.show(
        context,
        message: l10n.ptzNotSupported,
        bottomOffset: AppSpacing.xl,
      );
      return;
    }
    _ptzShown.value = true;
  }

  Future<void> _snapshot(Camera camera) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    unawaited(_app.haptics.light());
    final Result<SnapshotImage> captured = await _app.frameCapture.capture(
      camera.id,
    );
    if (!mounted) {
      return;
    }
    final SnapshotImage? image = captured.valueOrNull;
    if (image == null) {
      unawaited(_app.haptics.warning());
      AppToast.show(
        context,
        message: l10n.fullscreenSnapshotFailed,
        bottomOffset: AppSpacing.xl,
      );
      return;
    }
    _flash.value++;
    unawaited(_app.haptics.success());
    final Result<void> shared = await _app.fileTransfer.shareBytes(
      bytes: image.bytes,
      fileName: _fileName(camera, image),
      mimeType: image.mimeType,
    );
    final AppError? error = shared.errorOrNull;
    if (error != null && mounted) {
      AppToast.show(
        context,
        message: errorMessage(l10n, error),
        bottomOffset: AppSpacing.xl,
      );
    }
  }

  String _fileName(Camera camera, SnapshotImage image) {
    final String safe = camera.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final DateTime t = image.capturedAt;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${safe.isEmpty ? 'camera' : safe}-${t.year}${two(t.month)}'
        '${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}.jpg';
  }

  void _close() {
    unawaited(_app.haptics.light());
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _rebuild,
        _app.cameras,
        _app.live,
      ]),
      builder: (BuildContext context, Widget? _) {
        final Camera? camera = _app.cameras.value.byId(_cameraId);
        if (camera == null) {
          // The camera was deleted while it was open.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
          return const SizedBox.shrink();
        }
        return AppScaffold(
          immersive: true,
          body: ColoredBox(
            color: context.colors.videoBackdrop,
            child: SnapshotFlash(
              trigger: _flash,
              child: _viewer(context, l10n, camera),
            ),
          ),
        );
      },
    );
  }

  Widget _viewer(BuildContext context, AppLocalizations l10n, Camera camera) {
    final LiveSession? pooled = _app.live.sessionFor(camera.id);
    final bool ptzAllowed = _app.flags.isEnabled('ptz');
    return ValueListenableBuilder<PlayerState>(
      valueListenable:
          pooled?.state ?? _noSession,
      builder: (BuildContext context, PlayerState state, Widget? _) {
        final StreamStatus status = StreamStatus.fromPlayerState(state);
        final AppError? error = state is PlayerError ? state.error : null;
        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _muted,
            _lowQuality,
            _ptzShown,
            _zoom,
          ]),
          builder: (BuildContext context, Widget? _) {
            final bool hasSub = camera.hasSubstream;
            return FullscreenControls(
              title: camera.name,
              closeLabel: l10n.actionClose,
              onClose: _close,
              onActivity: _app.autoCycle.userInteracted,
              statusPill: StreamStatusPill(
                status: status,
                label: streamStatusLabel(l10n, status),
                plate: true,
              ),
              topActions: <FullscreenAction>[
                FullscreenAction(
                  icon: _muted.value
                      ? AppIconName.volumeOff
                      : AppIconName.volumeOn,
                  label: _muted.value
                      ? l10n.fullscreenUnmute
                      : l10n.fullscreenMute,
                  onPressed: () {
                    _muted.value = !_muted.value;
                    unawaited(
                      pooled?.setMuted(muted: _muted.value) ??
                          Future<void>.value(),
                    );
                  },
                ),
                FullscreenAction(
                  icon: AppIconName.snapshot,
                  label: l10n.fullscreenSnapshot,
                  onPressed: _app.flags.isEnabled('snapshots')
                      ? () => unawaited(_snapshot(camera))
                      : null,
                ),
                if (hasSub)
                  FullscreenAction(
                    icon: AppIconName.sliders,
                    label: _lowQuality.value
                        ? l10n.fullscreenQualityHigh
                        : l10n.fullscreenQualityLow,
                    selected: _lowQuality.value,
                    onPressed: () {
                      _lowQuality.value = !_lowQuality.value;
                      _app.live.setLowQuality(lowQuality: _lowQuality.value);
                    },
                  ),
                if (_app.pip.isSupported && _app.flags.isEnabled('pip'))
                  FullscreenAction(
                    icon: AppIconName.pip,
                    label: l10n.fullscreenPip,
                    onPressed: () => unawaited(_app.pip.enter()),
                  ),
              ],
              bottomActions: <FullscreenAction>[
                if (_order.length > 1)
                  FullscreenAction(
                    icon: AppIconName.chevronLeft,
                    label: l10n.fullscreenPreviousCamera,
                    onPressed: () => _step(-1),
                  ),
                if (ptzAllowed)
                  FullscreenAction(
                    icon: AppIconName.cameraPtz,
                    label: l10n.fullscreenPtz,
                    selected: _ptzShown.value,
                    onPressed: () => unawaited(_togglePtz(camera)),
                  ),
                if (_zoom.value.isZoomed)
                  FullscreenAction(
                    icon: AppIconName.zoomOut,
                    label: l10n.fullscreenZoomReset,
                    onPressed: () => _zoom.value = ZoomState.reset,
                  ),
                if (_order.length > 1)
                  FullscreenAction(
                    icon: AppIconName.chevronRight,
                    label: l10n.fullscreenNextCamera,
                    onPressed: () => _step(1),
                  ),
              ],
              panel: _ptzShown.value ? _ptzPanel(l10n, camera) : null,
              child: _picture(context, l10n, camera, pooled, state, error),
            );
          },
        );
      },
    );
  }

  Widget _ptzPanel(AppLocalizations l10n, Camera camera) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PtzPad(
          labels: PtzPadLabels(
            pad: l10n.ptzPad,
            home: l10n.ptzHome,
            zoomIn: l10n.ptzZoomIn,
            zoomOut: l10n.ptzZoomOut,
          ),
          diameter: context.isTablet ? 208 : 176,
          onMove: (double pan, double tilt) => unawaited(
            _sendPtz(
              camera,
              PtzCommand.continuous(
                pan: pan,
                tilt: tilt,
                speed: _ptzSpeed.value,
              ),
            ),
          ),
          onStop: () => unawaited(_sendPtz(camera, const PtzCommand.stop())),
          onZoom: (double z) => unawaited(
            _sendPtz(
              camera,
              z == 0
                  ? const PtzCommand.stop()
                  : PtzCommand.continuous(zoom: z, speed: _ptzSpeed.value),
            ),
          ),
          onHome: () => unawaited(_sendPtz(camera, const PtzCommand.home())),
        ),
        ValueListenableBuilder<double>(
          valueListenable: _ptzSpeed,
          builder: (BuildContext context, double speed, Widget? _) {
            return PtzSpeedControl(
              value: speed,
              label: l10n.ptzSpeed,
              onChanged: (double v) => _ptzSpeed.value = v,
            );
          },
        ),
      ],
    );
  }

  Widget _picture(
    BuildContext context,
    AppLocalizations l10n,
    Camera camera,
    LiveSession? pooled,
    PlayerState state,
    AppError? error,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final Size viewport = box.biggest;
        final ZoomState zoom = _zoom.value;
        final Widget video = pooled == null
            ? const SizedBox.expand()
            : _app.videoBuilder(
                pooled.viewHandle,
                fit: BoxFit.contain,
                backdrop: context.colors.videoBackdrop,
              );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (ScaleStartDetails d) {
            _gestureStart = d.focalPoint;
            _swipe = 0;
            _lastScale = 1;
            _pointers = d.pointerCount;
          },
          onScaleUpdate: (ScaleUpdateDetails d) {
            _pointers = d.pointerCount;
            if (d.pointerCount >= 2) {
              final double factor = d.scale / _lastScale;
              _lastScale = d.scale;
              _zoom.value = ZoomMath.zoomAround(
                _zoom.value,
                factor,
                d.localFocalPoint,
                viewport,
              );
            } else if (_zoom.value.isZoomed) {
              _zoom.value = ZoomMath.panBy(
                _zoom.value,
                d.focalPointDelta,
                viewport,
              );
            } else {
              _swipe = d.focalPoint.dx - _gestureStart.dx;
            }
          },
          onScaleEnd: (ScaleEndDetails d) {
            if (!_zoom.value.isZoomed &&
                _pointers < 2 &&
                ZoomMath.isSwitchSwipe(_swipe, viewport.width)) {
              _step(_swipe < 0 ? 1 : -1);
            }
            _swipe = 0;
          },
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(zoom.dx, zoom.dy, 0, 1)
                    ..scaleByDouble(zoom.scale, zoom.scale, 1, 1),
                  alignment: Alignment.center,
                  child: video,
                ),
                if (error != null)
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        errorMessage(l10n, error),
                        textAlign: TextAlign.center,
                        style: context.type.body.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                if (zoom.isZoomed)
                  PositionedDirectional(
                    start: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Semantics(
                      label: l10n.fullscreenZoomLevel(
                        ZoomMath.levelLabel(zoom.scale),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          l10n.fullscreenZoomLevel(
                            ZoomMath.levelLabel(zoom.scale),
                          ),
                          style: context.type.data.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
