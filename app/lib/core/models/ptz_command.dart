/// What a PTZ command asks the camera to do.
enum PtzCommandKind { continuous, stop, home, preset }

double _clamp(double value, double low, double high) {
  if (value < low) {
    return low;
  }
  if (value > high) {
    return high;
  }
  return value;
}

/// A pan, tilt and zoom request. Pan, tilt and zoom are normalized to -1..1
/// and [speed] to 0..1; the constructors clamp out-of-range input.
class PtzCommand {
  const PtzCommand._({
    required this.kind,
    required this.pan,
    required this.tilt,
    required this.zoom,
    required this.speed,
    this.presetToken,
  });

  /// Move while held: positive pan is right, positive tilt is up, positive zoom
  /// zooms in.
  factory PtzCommand.continuous({
    double pan = 0,
    double tilt = 0,
    double zoom = 0,
    double speed = 0.5,
  }) {
    return PtzCommand._(
      kind: PtzCommandKind.continuous,
      pan: _clamp(pan, -1, 1),
      tilt: _clamp(tilt, -1, 1),
      zoom: _clamp(zoom, -1, 1),
      speed: _clamp(speed, 0, 1),
    );
  }

  const PtzCommand.stop()
      : kind = PtzCommandKind.stop,
        pan = 0,
        tilt = 0,
        zoom = 0,
        speed = 0,
        presetToken = null;

  const PtzCommand.home()
      : kind = PtzCommandKind.home,
        pan = 0,
        tilt = 0,
        zoom = 0,
        speed = 0,
        presetToken = null;

  const PtzCommand.preset(String token)
      : kind = PtzCommandKind.preset,
        pan = 0,
        tilt = 0,
        zoom = 0,
        speed = 0,
        presetToken = token;

  factory PtzCommand.fromJson(Map<String, Object?> json) {
    final PtzCommandKind kind =
        PtzCommandKind.values.byName(json['kind']! as String);
    switch (kind) {
      case PtzCommandKind.stop:
        return const PtzCommand.stop();
      case PtzCommandKind.home:
        return const PtzCommand.home();
      case PtzCommandKind.preset:
        return PtzCommand.preset(json['presetToken']! as String);
      case PtzCommandKind.continuous:
        return PtzCommand.continuous(
          pan: (json['pan']! as num).toDouble(),
          tilt: (json['tilt']! as num).toDouble(),
          zoom: (json['zoom']! as num).toDouble(),
          speed: (json['speed']! as num).toDouble(),
        );
    }
  }

  final PtzCommandKind kind;
  final double pan;
  final double tilt;
  final double zoom;
  final double speed;

  /// Set only for [PtzCommandKind.preset].
  final String? presetToken;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'pan': pan,
      'tilt': tilt,
      'zoom': zoom,
      'speed': speed,
      'presetToken': presetToken,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is PtzCommand &&
        other.kind == kind &&
        other.pan == pan &&
        other.tilt == tilt &&
        other.zoom == zoom &&
        other.speed == speed &&
        other.presetToken == presetToken;
  }

  @override
  int get hashCode => Object.hash(kind, pan, tilt, zoom, speed, presetToken);
}
