import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/services/ptz_math.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Spoken names for the pad's controls, already translated.
class PtzPadLabels {
  const PtzPadLabels({
    required this.pad,
    required this.home,
    required this.zoomIn,
    required this.zoomOut,
  });

  final String pad;
  final String home;
  final String zoomIn;
  final String zoomOut;
}

/// The PTZ pad. Dragging from the middle pans and tilts: nothing happens inside
/// the dead zone, then speed rises smoothly to the edge. Lifting the finger
/// stops the camera. Arrow keys work too. Arrows are physical directions and do
/// not mirror in right-to-left layouts.
///
/// [onMove] gets pan and tilt in -1..1 (right and up are positive), rounded so
/// finger jitter does not flood the camera. [onStop] means "stop moving".
class PtzPad extends StatefulWidget {
  const PtzPad({
    super.key,
    required this.labels,
    required this.onMove,
    required this.onStop,
    required this.onZoom,
    required this.onHome,
    this.diameter = AppSizes.ptzPad,
    this.enabled = true,
  });

  final PtzPadLabels labels;
  final void Function(double pan, double tilt) onMove;
  final VoidCallback onStop;

  /// -1 zooms out, 1 zooms in, 0 stops the zoom.
  final ValueChanged<double> onZoom;
  final VoidCallback onHome;
  final double diameter;
  final bool enabled;

  @override
  State<PtzPad> createState() => _PtzPadState();
}

class _PtzPadState extends State<PtzPad> {
  static const double _keyboardSpeed = 0.8;

  final ValueNotifier<Offset> _thumb = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<PtzVelocity> _active = ValueNotifier<PtzVelocity>((
    pan: 0,
    tilt: 0,
    zoom: 0,
  ));
  final Set<LogicalKeyboardKey> _keys = <LogicalKeyboardKey>{};
  PtzVelocity _lastSent = (pan: 0, tilt: 0, zoom: 0);

  @override
  void dispose() {
    _thumb.dispose();
    _active.dispose();
    super.dispose();
  }

  double get _radius => widget.diameter / 2;

  void _drag(Offset local) {
    final double dx = local.dx - _radius;
    final double dy = local.dy - _radius;
    final ({double pan, double tilt}) raw = PtzMath.fromPad(
      dx: dx,
      dy: dy,
      radius: _radius,
    );
    _send(PtzMath.quantize(raw.pan), PtzMath.quantize(raw.tilt));
    final double reach = _radius - AppSizes.ptzThumb / 2;
    final double length = Offset(dx, dy).distance;
    _thumb.value = length <= reach || length == 0
        ? Offset(dx, dy)
        : Offset(dx, dy) * (reach / length);
  }

  void _send(double pan, double tilt) {
    final PtzVelocity next = (pan: pan, tilt: tilt, zoom: 0);
    _active.value = next;
    if (PtzMath.isStill(next)) {
      _stop();
      return;
    }
    if (PtzMath.isWorthSending(_lastSent, next)) {
      _lastSent = next;
      widget.onMove(pan, tilt);
    }
  }

  void _stop() {
    _active.value = (pan: 0, tilt: 0, zoom: 0);
    if (!PtzMath.isStill(_lastSent)) {
      _lastSent = (pan: 0, tilt: 0, zoom: 0);
      widget.onStop();
    }
  }

  void _release() {
    _thumb.value = Offset.zero;
    _stop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    const List<LogicalKeyboardKey> arrows = <LogicalKeyboardKey>[
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ];
    if (!arrows.contains(key)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      _keys.remove(key);
    } else {
      _keys.add(key);
    }
    final double pan =
        (_keys.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (_keys.contains(LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    final double tilt =
        (_keys.contains(LogicalKeyboardKey.arrowUp) ? 1 : 0) -
        (_keys.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0);
    _send(pan * _keyboardSpeed, tilt * _keyboardSpeed);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final double size = widget.diameter;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: widget.labels.pad,
          container: true,
          child: Focus(
            canRequestFocus: widget.enabled,
            onKeyEvent: _onKey,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: widget.enabled
                  ? (DragDownDetails d) => _drag(d.localPosition)
                  : null,
              onPanUpdate: widget.enabled
                  ? (DragUpdateDetails d) => _drag(d.localPosition)
                  : null,
              onPanEnd: widget.enabled ? (_) => _release() : null,
              onPanCancel: widget.enabled ? _release : null,
              child: SizedBox.square(
                dimension: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.borderStrong,
                      width: AppSizes.hairline * 2,
                    ),
                  ),
                  child: ValueListenableBuilder<PtzVelocity>(
                    valueListenable: _active,
                    builder:
                        (
                          BuildContext context,
                          PtzVelocity velocity,
                          Widget? _,
                        ) {
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              _arrow(
                                AppIconName.ptzArrowUp,
                                Alignment.topCenter,
                                velocity.tilt > 0,
                                colors,
                              ),
                              _arrow(
                                AppIconName.ptzArrowDown,
                                Alignment.bottomCenter,
                                velocity.tilt < 0,
                                colors,
                              ),
                              _arrow(
                                AppIconName.ptzArrowLeft,
                                const Alignment(-1, 0),
                                velocity.pan < 0,
                                colors,
                              ),
                              _arrow(
                                AppIconName.ptzArrowRight,
                                const Alignment(1, 0),
                                velocity.pan > 0,
                                colors,
                              ),
                              ValueListenableBuilder<Offset>(
                                valueListenable: _thumb,
                                builder:
                                    (
                                      BuildContext context,
                                      Offset offset,
                                      Widget? _,
                                    ) {
                                      return Transform.translate(
                                        offset: offset,
                                        child: SizedBox.square(
                                          dimension: AppSizes.ptzThumb,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: offset == Offset.zero
                                                  ? colors.bgTertiary
                                                  : colors.accentWash,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: offset == Offset.zero
                                                    ? colors.borderStrong
                                                    : colors.accent,
                                                width: AppSizes.hairline * 2,
                                              ),
                                            ),
                                            child: offset == Offset.zero
                                                ? Center(
                                                    child: AppIconButton(
                                                      icon: AppIconName.ptzHome,
                                                      semanticLabel:
                                                          widget.labels.home,
                                                      onPressed: widget.enabled
                                                          ? widget.onHome
                                                          : null,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ],
                          );
                        },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _HoldChip(
              icon: AppIconName.zoomOut,
              label: widget.labels.zoomOut,
              enabled: widget.enabled,
              onHold: () => widget.onZoom(-1),
              onRelease: () => widget.onZoom(0),
            ),
            const SizedBox(width: AppSpacing.lg),
            _HoldChip(
              icon: AppIconName.zoomIn,
              label: widget.labels.zoomIn,
              enabled: widget.enabled,
              onHold: () => widget.onZoom(1),
              onRelease: () => widget.onZoom(0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrow(
    AppIconName icon,
    Alignment alignment,
    bool active,
    AppColors colors,
  ) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: ExcludeSemantics(
          child: AppIcon(
            icon,
            size: AppSizes.iconPtz,
            color: active ? colors.accent : colors.textTertiary,
            weight: active ? AppIconWeight.fill : AppIconWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A button that acts while it is held: pressing starts the action and letting
/// go ends it. A screen-reader activation does a short pulse instead.
class _HoldChip extends StatefulWidget {
  const _HoldChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onHold,
    required this.onRelease,
  });

  final AppIconName icon;
  final String label;
  final bool enabled;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  State<_HoldChip> createState() => _HoldChipState();
}

class _HoldChipState extends State<_HoldChip> {
  static const Duration _pulse = Duration(milliseconds: 400);

  final ValueNotifier<bool> _held = ValueNotifier<bool>(false);
  Timer? _pulseTimer;

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _held.dispose();
    super.dispose();
  }

  void _down() {
    if (!widget.enabled) {
      return;
    }
    _held.value = true;
    widget.onHold();
  }

  void _up() {
    if (_held.value) {
      _held.value = false;
      widget.onRelease();
    }
  }

  void _pulseOnce() {
    _down();
    _pulseTimer?.cancel();
    _pulseTimer = Timer(_pulse, _up);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      onTap: widget.enabled ? _pulseOnce : null,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: SizedBox.square(
          dimension: AppSizes.touchTarget,
          child: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: _held,
              builder: (BuildContext context, bool held, Widget? _) {
                return SizedBox.square(
                  dimension: AppSizes.iconChip,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: held ? colors.accentWash : colors.bgTertiary,
                      borderRadius: AppRadius.allMd,
                    ),
                    child: Center(
                      child: AppIcon(
                        widget.icon,
                        size: AppSizes.iconNavBar,
                        color: widget.enabled
                            ? (held ? colors.accent : colors.textPrimary)
                            : colors.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
