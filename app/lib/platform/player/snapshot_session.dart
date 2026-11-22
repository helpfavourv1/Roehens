import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/services/jpeg_info.dart';
import 'package:roehens/platform/network/mjpeg_client.dart';

/// A playback session for a camera that only serves still pictures over HTTP
/// (A3: "HTTP snapshot polling"). It fetches one JPEG every [interval] and
/// shows the newest, so the tile behaves like any other live tile.
///
/// A failed fetch ends in the error state; the player pool then reconnects
/// with its usual back-off by opening the session again.
class SnapshotSession implements PlayerSessionContract, FrameCapturable {
  SnapshotSession({
    MjpegClient? client,
    this.interval = const Duration(seconds: 1),
    this._mapper = const ErrorMapper(),
  }) : _client = client ?? MjpegClient();

  final MjpegClient _client;
  final Duration interval;
  final ErrorMapper _mapper;

  final ValueNotifier<PlayerState> _state = ValueNotifier<PlayerState>(
    const PlayerIdle(),
  );
  final ValueNotifier<VideoSize?> _size = ValueNotifier<VideoSize?>(null);
  final ValueNotifier<Uint8List?> _latest = ValueNotifier<Uint8List?>(null);

  Timer? _timer;
  int _generation = 0;
  bool _fetching = false;
  bool _disposed = false;

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  ValueListenable<VideoSize?> get videoSize => _size;

  /// Same handle type as the MJPEG session, so one video view draws both.
  @override
  Object? get viewHandle => _latest;

  @override
  Future<void> open(PlayerSource source) async {
    if (_disposed) {
      return;
    }
    _timer?.cancel();
    final int generation = ++_generation;
    _state.value = const PlayerConnecting();
    await _fetch(source, generation);
    if (_disposed || generation != _generation) {
      return;
    }
    if (_state.value is PlayerPlaying) {
      _timer = Timer.periodic(interval, (Timer _) {
        unawaited(_fetch(source, generation));
      });
    }
  }

  Future<void> _fetch(PlayerSource source, int generation) async {
    if (_fetching || _disposed || generation != _generation) {
      return;
    }
    _fetching = true;
    try {
      final Uint8List frame = await _client.fetchSnapshot(
        source.uri,
        credentials: source.credentials,
      );
      if (_disposed || generation != _generation) {
        return;
      }
      _latest.value = frame;
      final JpegSize? size = readJpegSize(frame);
      if (size != null) {
        final VideoSize next = VideoSize(size.width, size.height);
        if (_size.value != next) {
          _size.value = next;
        }
      }
      if (_state.value is! PlayerPlaying) {
        _state.value = const PlayerPlaying();
      }
    } catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _timer?.cancel();
      _timer = null;
      _state.value = PlayerError(
        error is AppError ? error : _mapper.fromException(error),
      );
    } finally {
      _fetching = false;
    }
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    // Still pictures carry no audio.
  }

  @override
  Future<Uint8List?> captureFrame() async => _latest.value;

  @override
  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    _timer = null;
    if (!_disposed) {
      _state.value = const PlayerStopped();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _generation++;
    _timer?.cancel();
    _timer = null;
    _disposed = true;
    _state.dispose();
    _size.dispose();
    _latest.dispose();
  }
}
