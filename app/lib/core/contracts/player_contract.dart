import 'package:flutter/foundation.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// What to play. [uri] never contains credentials; they travel separately so
/// logs and diagnostics cannot leak them.
class PlayerSource {
  const PlayerSource({
    required this.uri,
    required this.protocol,
    this.transport = StreamTransport.auto,
    this.credentials = CameraCredentials.none,
    this.lowLatency = true,
  });

  final Uri uri;
  final StreamProtocol protocol;
  final StreamTransport transport;
  final CameraCredentials credentials;
  final bool lowLatency;
}

/// Pixel size of the decoded video.
class VideoSize {
  const VideoSize(this.width, this.height);

  final int width;
  final int height;

  @override
  bool operator ==(Object other) {
    return other is VideoSize && other.width == width && other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

/// What the chosen engine can do beyond plain playback. Recorded at the player
/// spike (checkpoint CP1).
class PlayerCapabilities {
  const PlayerCapabilities({required this.pictureInPictureSurface});

  /// The engine exposes a video surface Android picture-in-picture can keep.
  final bool pictureInPictureSurface;
}

/// One playback session. A `PlayerPool` owns every session and disposes them
/// deterministically.
abstract interface class PlayerSessionContract {
  ValueListenable<PlayerState> get state;

  /// Null until the first frame is decoded.
  ValueListenable<VideoSize?> get videoSize;

  /// Handle the engine's view widget needs; opaque to everything else.
  Object? get viewHandle;

  Future<void> open(PlayerSource source);

  Future<void> setMuted({required bool muted});

  Future<void> stop();

  Future<void> dispose();
}

/// The playback engine.
abstract interface class PlayerContract {
  PlayerCapabilities get capabilities;

  PlayerSessionContract createSession();
}
