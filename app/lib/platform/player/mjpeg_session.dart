import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/services/jpeg_info.dart';
import 'package:roehens/platform/network/mjpeg_client.dart';

/// A playback session for an MJPEG camera, driven by [MjpegClient] instead of
/// the video engine. [viewHandle] is a [ValueListenable] of the latest JPEG
/// frame; the video view draws whatever it currently holds.
class MjpegSession implements PlayerSessionContract, FrameCapturable {
  MjpegSession({MjpegClient? client, this._mapper = const ErrorMapper()})
      : _client = client ?? MjpegClient();

  final MjpegClient _client;
  final ErrorMapper _mapper;

  final ValueNotifier<PlayerState> _state =
      ValueNotifier<PlayerState>(const PlayerIdle());
  final ValueNotifier<VideoSize?> _size = ValueNotifier<VideoSize?>(null);
  final ValueNotifier<Uint8List?> _latest = ValueNotifier<Uint8List?>(null);

  StreamSubscription<Uint8List>? _subscription;
  int _generation = 0;
  bool _disposed = false;

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  ValueListenable<VideoSize?> get videoSize => _size;

  /// The latest frame; null before the first one arrives.
  ValueListenable<Uint8List?> get latestFrame => _latest;

  @override
  Object? get viewHandle => _latest;

  @override
  Future<void> open(PlayerSource source) async {
    if (_disposed) {
      return;
    }
    // Show "connecting" at once; the old stream is cancelled right after.
    final StreamSubscription<Uint8List>? previous = _subscription;
    _subscription = null;
    final int generation = ++_generation;
    _state.value = const PlayerConnecting();
    await previous?.cancel();
    if (_disposed || generation != _generation) {
      return;
    }
    _subscription = _client
        .frames(source.uri, credentials: source.credentials)
        .listen(
      (Uint8List frame) {
        if (generation != _generation || _disposed) {
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
      },
      onError: (Object error) {
        if (generation != _generation || _disposed) {
          return;
        }
        _state.value = PlayerError(
          error is AppError ? error : _mapper.fromException(error),
        );
      },
      onDone: () {
        if (generation != _generation || _disposed) {
          return;
        }
        if (_state.value is! PlayerError) {
          _state.value = const PlayerError(AppError(ErrorClass.streamDropped));
        }
      },
      cancelOnError: true,
    );
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    // MJPEG carries no audio.
  }

  @override
  Future<Uint8List?> captureFrame() async => _latest.value;

  Future<void> _cancel() async {
    _generation++;
    final StreamSubscription<Uint8List>? subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  @override
  Future<void> stop() async {
    await _cancel();
    if (!_disposed) {
      _state.value = const PlayerStopped();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await _cancel();
    _disposed = true;
    _state.dispose();
    _size.dispose();
    _latest.dispose();
  }
}
