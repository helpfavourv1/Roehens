import 'package:roehens/core/errors/app_error.dart';

/// Lifecycle of one playback session.
sealed class PlayerState {
  const PlayerState();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  /// True while the session holds a decoder or is trying to get one.
  bool get isActive {
    return switch (this) {
      PlayerConnecting() ||
      PlayerBuffering() ||
      PlayerPlaying() ||
      PlayerReconnecting() =>
        true,
      PlayerIdle() || PlayerError() || PlayerStopped() => false,
    };
  }
}

/// Created, nothing started.
final class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

final class PlayerConnecting extends PlayerState {
  const PlayerConnecting();
}

final class PlayerBuffering extends PlayerState {
  const PlayerBuffering();
}

final class PlayerPlaying extends PlayerState {
  const PlayerPlaying();
}

/// Lost the stream and retrying; [attempt] counts from 1.
final class PlayerReconnecting extends PlayerState {
  const PlayerReconnecting({required this.attempt});

  final int attempt;

  @override
  bool operator ==(Object other) {
    return other is PlayerReconnecting && other.attempt == attempt;
  }

  @override
  int get hashCode => attempt.hashCode;
}

/// Failed; [error] says why and whether a retry makes sense.
final class PlayerError extends PlayerState {
  const PlayerError(this.error);

  final AppError error;

  @override
  bool operator ==(Object other) {
    return other is PlayerError && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// Stopped on purpose (leaving the screen, pausing the app).
final class PlayerStopped extends PlayerState {
  const PlayerStopped();
}
