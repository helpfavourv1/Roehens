import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/stream_url_utils.dart';

/// Tuning of the video engine. Values come from device tests; change them here
/// and nowhere else.
class PlayerOptions {
  const PlayerOptions({
    this.hardwareDecoding = 'auto-safe',
    this.udpAvailable = false,
    this.networkTimeout = const Duration(seconds: 10),
    this.openTimeout = const Duration(seconds: 20),
    this.stallTimeout = const Duration(seconds: 8),
    this.pollInterval = const Duration(milliseconds: 500),
  });

  /// mpv `hwdec` value. `auto-safe` lets the engine pick; `mediacodec-copy`
  /// forces the Android hardware decoder with a copy back to memory.
  final String hardwareDecoding;

  /// Whether the bundled engine can do RTSP over UDP. False for the stock build.
  final bool udpAvailable;

  final Duration networkTimeout;

  /// No picture within this long after opening counts as a failed connection.
  final Duration openTimeout;

  /// A picture that stops advancing for this long counts as a dropped stream.
  final Duration stallTimeout;

  final Duration pollInterval;
}

/// A video-engine session for RTSP and other streams the engine can read.
///
/// Health comes from polling this player's own mpv properties, never from the
/// engine's error and log streams: those deliver messages from every player to
/// every listener, so trusting them would let one broken camera fail the
/// healthy ones.
class MediaKitPlayerSession implements PlayerSessionContract, FrameCapturable {
  MediaKitPlayerSession({
    this.options = const PlayerOptions(),
    this.clock = const SystemClock(),
    this.logger,
  }) : _player = Player(
          configuration: const PlayerConfiguration(logLevel: MPVLogLevel.error),
        ) {
    _controller = VideoController(_player);
  }

  final PlayerOptions options;
  final ClockContract clock;
  final LoggerContract? logger;

  final Player _player;
  late final VideoController _controller;

  final ValueNotifier<PlayerState> _state =
      ValueNotifier<PlayerState>(const PlayerIdle());
  final ValueNotifier<VideoSize?> _size = ValueNotifier<VideoSize?>(null);

  Timer? _timer;
  bool _polling = false;
  bool _disposed = false;
  DateTime _openedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastProgress = DateTime.fromMillisecondsSinceEpoch(0);
  double? _lastPosition;
  bool _sawPosition = false;

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  ValueListenable<VideoSize?> get videoSize => _size;

  @override
  Object? get viewHandle => _controller;

  NativePlayer get _native => _player.platform! as NativePlayer;

  @override
  Future<void> open(PlayerSource source) async {
    if (_disposed) {
      return;
    }
    _timer?.cancel();
    _size.value = null;
    _lastPosition = null;
    _sawPosition = false;
    _state.value = const PlayerConnecting();

    await _applyOptions(source);
    final Uri address =
        StreamUrlUtils.withCredentials(source.uri, source.credentials);
    await _player.open(Media(address.toString()));

    _openedAt = clock.now();
    _lastProgress = _openedAt;
    _timer = Timer.periodic(options.pollInterval, (Timer _) {
      unawaited(_poll());
    });
  }

  Future<void> _applyOptions(PlayerSource source) async {
    Future<void> set(String name, String value) async {
      try {
        await _native.setProperty(name, value);
      } catch (error) {
        logger?.warning('player', 'option $name not applied', error: error);
      }
    }

    await set('hwdec', options.hardwareDecoding);
    if (source.lowLatency) {
      await set('profile', 'low-latency');
    }
    await set('network-timeout', '${options.networkTimeout.inSeconds}');
    if (source.protocol == StreamProtocol.rtsp) {
      final String? transport = StreamUrlUtils.rtspTransportOption(
        source.transport,
        udpAvailable: options.udpAvailable,
      );
      await set(
        'demuxer-lavf-o',
        transport == null ? '' : 'rtsp_transport=$transport',
      );
    }
  }

  Future<String?> _read(String name) async {
    try {
      final String value = await _native.getProperty(name);
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _poll() async {
    if (_disposed || _polling) {
      return;
    }
    _polling = true;
    try {
      final int width = int.tryParse(await _read('video-params/w') ?? '') ?? 0;
      final int height = int.tryParse(await _read('video-params/h') ?? '') ?? 0;
      final double? position = double.tryParse(await _read('time-pos') ?? '');
      final bool atEnd = await _read('eof-reached') == 'yes';
      final bool waitingForData = await _read('paused-for-cache') == 'yes';
      if (_disposed) {
        return;
      }

      final DateTime now = clock.now();
      if (width > 0 && height > 0) {
        final VideoSize next = VideoSize(width, height);
        if (_size.value != next) {
          _size.value = next;
        }
      }
      if (position != null) {
        _sawPosition = true;
        final double? last = _lastPosition;
        if (last == null || position > last + 0.001) {
          _lastPosition = position;
          _lastProgress = now;
        }
      }

      if (atEnd) {
        _fail(const AppError(ErrorClass.streamDropped, detail: 'stream ended'));
        return;
      }
      final bool hasPicture = width > 0 && height > 0;
      if (!hasPicture) {
        if (now.difference(_openedAt) > options.openTimeout) {
          _fail(
            const AppError(
              ErrorClass.networkUnreachable,
              detail: 'no picture before the open timeout',
            ),
          );
        }
        return;
      }
      // Stall detection only when this stream reports a position at all.
      if (_sawPosition &&
          now.difference(_lastProgress) > options.stallTimeout) {
        _fail(
          const AppError(ErrorClass.streamDropped, detail: 'picture stopped'),
        );
        return;
      }
      final PlayerState next =
          waitingForData ? const PlayerBuffering() : const PlayerPlaying();
      if (_state.value != next) {
        _state.value = next;
      }
    } finally {
      _polling = false;
    }
  }

  void _fail(AppError error) {
    _timer?.cancel();
    _timer = null;
    _state.value = PlayerError(error);
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    await _player.setVolume(muted ? 0 : 100);
  }

  @override
  Future<Uint8List?> captureFrame() async {
    if (_disposed) {
      return null;
    }
    return _player.screenshot();
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    if (_disposed) {
      return;
    }
    await _player.stop();
    _state.value = const PlayerStopped();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await _player.dispose();
    _state.dispose();
    _size.dispose();
  }
}
