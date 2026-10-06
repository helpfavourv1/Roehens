import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/models/player_state.dart';

/// A session the test drives by hand with [emit].
class FakePlayerSession implements PlayerSessionContract, FrameCapturable {
  final ValueNotifier<PlayerState> _state =
      ValueNotifier<PlayerState>(const PlayerIdle());
  final ValueNotifier<VideoSize?> _size = ValueNotifier<VideoSize?>(null);

  final List<PlayerSource> opened = <PlayerSource>[];
  int stops = 0;
  bool disposed = false;
  Object? openError;
  Uint8List? frame;
  bool? lastMuted;

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  ValueListenable<VideoSize?> get videoSize => _size;

  @override
  Object? get viewHandle => this;

  void emit(PlayerState next) => _state.value = next;

  void setSize(int width, int height) => _size.value = VideoSize(width, height);

  @override
  Future<void> open(PlayerSource source) async {
    final Object? error = openError;
    if (error != null) {
      throw error;
    }
    opened.add(source);
    _state.value = const PlayerConnecting();
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    lastMuted = muted;
  }

  @override
  Future<Uint8List?> captureFrame() async => frame;

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// A session that cannot produce still frames.
class NonCapturableSession implements PlayerSessionContract {
  final ValueNotifier<PlayerState> _state =
      ValueNotifier<PlayerState>(const PlayerIdle());
  final ValueNotifier<VideoSize?> _size = ValueNotifier<VideoSize?>(null);

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  ValueListenable<VideoSize?> get videoSize => _size;

  @override
  Object? get viewHandle => null;

  @override
  Future<void> open(PlayerSource source) async {}

  @override
  Future<void> setMuted({required bool muted}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
