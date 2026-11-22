import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/contracts/snapshot_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/core/providers/layout_provider.dart';
import 'package:roehens/core/providers/settings_provider.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/core/services/grid_planner.dart';
import 'package:roehens/core/services/url_builder.dart';
import 'package:roehens/platform/player/player_pool.dart';

/// Fetches one still picture of a camera that is not decoding right now.
/// Returns null when the camera cannot give one.
typedef PosterFetcher =
    Future<Uint8List?> Function(
      Camera camera,
      CameraCredentials credentials,
      StreamKind kind,
    );

/// What a screen may know about a decoding camera: its state, size, the
/// handle its video view draws, and mute. The pool and the engine stay hidden.
class LiveSession {
  LiveSession(this._pooled);

  final PooledSession _pooled;

  ValueListenable<PlayerState> get state => _pooled.state;
  ValueListenable<VideoSize?> get videoSize => _pooled.videoSize;
  Object? get viewHandle => _pooled.viewHandle;

  Future<void> setMuted({required bool muted}) {
    return _pooled.session.setMuted(muted: muted);
  }
}

/// The last picture of a tile that stopped decoding.
class PosterFrame {
  const PosterFrame({required this.bytes, required this.capturedAt});

  final Uint8List bytes;
  final DateTime capturedAt;
}

/// Decides which cameras decode, and keeps the player pool in step with it.
///
/// The Live screen asks for the cameras on its page; a fullscreen viewer asks
/// for one camera. Everything else releases its decoder and shows the last
/// picture (D3). Screens never see the pool's inner workings: they ask for a
/// camera's session with [sessionFor] and rebuild when this object notifies.
class LiveSessions extends ChangeNotifier {
  LiveSessions({
    required this.pool,
    required this.planner,
    required this.cameras,
    required this.layout,
    required this.settings,
    required this.repository,
    required this.snapshots,
    required this.logger,
    this.posterFetcher,
    this.now = DateTime.now,
  }) {
    cameras.addListener(_changed);
    layout.addListener(_changed);
    layout.page.addListener(_changed);
    settings.addListener(_changed);
  }

  final PlayerPool pool;
  final GridPlanner planner;
  final CamerasProvider cameras;
  final LayoutProvider layout;
  final SettingsProvider settings;
  final CameraRepository repository;
  final SnapshotContract snapshots;
  final LoggerContract logger;
  final PosterFetcher? posterFetcher;
  final DateTime Function() now;

  static const String _tag = 'live';

  final Map<String, PosterFrame> _posters = <String, PosterFrame>{};
  final Map<String, CameraCredentials> _credentials =
      <String, CameraCredentials>{};
  final Map<String, DateTime> _credentialsFor = <String, DateTime>{};
  GridPlan _plan = const GridPlan(<TilePlan>[]);

  bool _foreground = true;
  bool _viewingGrid = false;
  bool _isTablet = false;
  String? _focusId;
  bool _focusLowQuality = false;
  bool _focusSettled = false;
  Timer? _settleTimer;
  Timer? _posterTimer;

  bool _running = false;
  bool _dirty = false;
  bool _disposed = false;

  /// What the grid decided for the cameras on the current page.
  GridPlan get plan => _plan;

  /// The camera shown fullscreen, if any.
  String? get focusedId => _focusId;

  /// True while the fullscreen viewer plays the main stream (not the
  /// substream used while it settles or when low quality was chosen).
  bool get focusIsMainStream => _focusId != null && _focusMain(_focusId!);

  /// The pooled session of [cameraId], or null if it is not decoding.
  LiveSession? sessionFor(String cameraId) {
    final PooledSession? pooled = pool.sessionFor(cameraId);
    return pooled == null ? null : LiveSession(pooled);
  }

  /// The last picture of [cameraId], if one was kept.
  PosterFrame? posterFor(String cameraId) => _posters[cameraId];

  /// The Live screen is showing (true) or not (false).
  void setViewingGrid({required bool viewing, bool? isTablet}) {
    final bool tablet = isTablet ?? _isTablet;
    if (viewing == _viewingGrid && tablet == _isTablet) {
      return;
    }
    _viewingGrid = viewing;
    _isTablet = tablet;
    _changed();
  }

  /// The app is in the foreground (true) or left the screen (false). Leaving
  /// disposes every player; the person returns to staggered restarts.
  void setForeground({required bool foreground}) {
    if (foreground == _foreground) {
      return;
    }
    _foreground = foreground;
    _changed();
  }

  /// Plays one camera fullscreen, or goes back to the grid with null. The
  /// stream starts on the substream and moves to the main stream after the
  /// settle time (D3), so flipping through cameras does not open a heavy
  /// stream for each one.
  void focus(String? cameraId, {bool lowQuality = false}) {
    if (cameraId == _focusId && lowQuality == _focusLowQuality) {
      return;
    }
    _settleTimer?.cancel();
    _focusId = cameraId;
    _focusLowQuality = lowQuality;
    _focusSettled = false;
    if (cameraId != null && !lowQuality) {
      _settleTimer = Timer(Limits.mainStreamSettle, () {
        _focusSettled = true;
        _changed();
      });
    }
    _changed();
  }

  /// Switches the fullscreen stream between main and sub.
  void setLowQuality({required bool lowQuality}) {
    final String? id = _focusId;
    if (id != null) {
      focus(id, lowQuality: lowQuality);
    }
  }

  /// Asks a tile to start again after a failure.
  Future<void> retry(String cameraId) => pool.retry(cameraId);

  bool _focusMain(String id) {
    final Camera? camera = cameras.value.byId(id);
    if (camera == null || !camera.hasSubstream) {
      return true;
    }
    return !_focusLowQuality && _focusSettled;
  }

  void _changed() {
    if (_disposed) {
      return;
    }
    _dirty = true;
    if (!_running) {
      unawaited(_reconcile());
    }
  }

  Future<void> _reconcile() async {
    _running = true;
    try {
      while (_dirty && !_disposed) {
        _dirty = false;
        await _applyOnce();
      }
    } catch (error) {
      logger.warning(_tag, 'could not update the players', error: error);
    } finally {
      _running = false;
    }
  }

  Future<void> _applyOnce() async {
    final CamerasState state = cameras.value;
    final Map<String, PlayerSource> desired = <String, PlayerSource>{};
    GridPlan plan = const GridPlan(<TilePlan>[]);

    if (_foreground && state.isLoaded) {
      final String? focus = _focusId;
      if (focus != null && state.byId(focus) != null) {
        final Camera camera = state.byId(focus)!;
        final StreamKind kind = _focusMain(focus)
            ? StreamKind.main
            : StreamKind.sub;
        final PlayerSource? source = await _sourceFor(camera, kind);
        if (source != null) {
          desired[camera.id] = source;
        }
      } else if (_viewingGrid) {
        final List<Camera> visible = layout.camerasOnPage(state.cameras);
        plan = planner.plan(
          visible: visible,
          decoderBudget: GridPlanner.budgetFor(isTablet: _isTablet),
          preferSubstream: settings.value.gridSubstreamDefault,
        );
        for (final TilePlan tile in plan.tiles) {
          if (tile.mode != TileMode.live) {
            continue;
          }
          final Camera? camera = state.byId(tile.cameraId);
          if (camera == null) {
            continue;
          }
          final PlayerSource? source = await _sourceFor(camera, tile.streamKind);
          if (source != null) {
            desired[camera.id] = source;
          }
        }
      }
    }

    // Keep the last picture of everything that is about to stop decoding.
    for (final String key in pool.keys.toList()) {
      if (!desired.containsKey(key)) {
        await _keepPoster(key);
      }
    }

    _plan = plan;
    if (_foreground) {
      await pool.resume();
      await pool.reconcile(desired);
    } else {
      await pool.pause();
    }
    _schedulePosterRefresh();
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _keepPoster(String key) async {
    final PooledSession? pooled = pool.sessionFor(key);
    if (pooled == null || pooled.state.value is! PlayerPlaying) {
      return;
    }
    final Result<SnapshotImage> result = await snapshots.capture(key);
    final SnapshotImage? image = result.valueOrNull;
    if (image != null) {
      _posters[key] = PosterFrame(
        bytes: image.bytes,
        capturedAt: image.capturedAt,
      );
    }
  }

  Future<PlayerSource?> _sourceFor(Camera camera, StreamKind kind) async {
    final Uri? uri = UrlBuilder.streamUri(camera, kind: kind);
    if (uri == null) {
      return null;
    }
    final CameraCredentials credentials = await _credentialsOf(camera);
    final AppSettings current = settings.value;
    return PlayerSource(
      uri: uri,
      protocol: camera.protocol,
      transport: camera.transport == StreamTransport.auto
          ? current.defaultTransport
          : camera.transport,
      credentials: credentials,
    );
  }

  Future<CameraCredentials> _credentialsOf(Camera camera) async {
    final CameraCredentials? cached = _credentials[camera.id];
    if (cached != null && _credentialsFor[camera.id] == camera.updatedAt) {
      return cached;
    }
    final Result<CameraCredentials> result = await repository.credentialsFor(
      camera.id,
    );
    final CameraCredentials credentials =
        result.valueOrNull ?? CameraCredentials.none;
    _credentials[camera.id] = credentials;
    _credentialsFor[camera.id] = camera.updatedAt;
    return credentials;
  }

  // Poster refresh: tiles that gave up their decoder show a recent picture
  // when the camera can supply one cheaply (D3).
  void _schedulePosterRefresh() {
    final PosterFetcher? fetch = posterFetcher;
    final bool needed =
        fetch != null &&
        _foreground &&
        _viewingGrid &&
        _focusId == null &&
        _plan.tiles.any((TilePlan t) => t.refreshPoster);
    if (!needed) {
      _posterTimer?.cancel();
      _posterTimer = null;
      return;
    }
    _posterTimer ??= Timer.periodic(Limits.posterRefresh, (Timer _) {
      unawaited(_refreshPosters());
    });
  }

  bool _refreshing = false;

  Future<void> _refreshPosters() async {
    final PosterFetcher? fetch = posterFetcher;
    if (fetch == null || _refreshing || _disposed) {
      return;
    }
    _refreshing = true;
    try {
      bool changed = false;
      for (final TilePlan tile in _plan.tiles.toList()) {
        if (!tile.refreshPoster) {
          continue;
        }
        final Camera? camera = cameras.value.byId(tile.cameraId);
        if (camera == null || _disposed) {
          continue;
        }
        try {
          final Uint8List? bytes = await fetch(
            camera,
            await _credentialsOf(camera),
            tile.streamKind,
          );
          if (bytes != null && bytes.isNotEmpty) {
            _posters[camera.id] = PosterFrame(bytes: bytes, capturedAt: now());
            changed = true;
          }
        } catch (error) {
          logger.debug(_tag, 'no poster for ${camera.id}: ${error.runtimeType}');
        }
      }
      if (changed && !_disposed) {
        notifyListeners();
      }
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _settleTimer?.cancel();
    _posterTimer?.cancel();
    cameras.removeListener(_changed);
    layout.removeListener(_changed);
    layout.page.removeListener(_changed);
    settings.removeListener(_changed);
    super.dispose();
  }
}
