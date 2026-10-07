import 'dart:math';

import 'package:roehens/core/models/ptz_command.dart';

/// Pan, tilt and zoom as ONVIF velocities, each in -1..1.
typedef PtzVelocity = ({double pan, double tilt, double zoom});

/// Conversions between what the person does on the PTZ pad and what the camera
/// is told.
class PtzMath {
  PtzMath._();

  static double _clamp(double value, double low, double high) {
    return value < low ? low : (value > high ? high : value);
  }

  /// [value] scaled by the speed setting and kept within -1..1.
  static double scale(double value, double speed) {
    return _clamp(value * _clamp(speed, 0, 1), -1, 1);
  }

  /// The velocity a continuous command asks for; zero for every other kind.
  static PtzVelocity velocityFor(PtzCommand command) {
    if (command.kind != PtzCommandKind.continuous) {
      return (pan: 0, tilt: 0, zoom: 0);
    }
    return (
      pan: scale(command.pan, command.speed),
      tilt: scale(command.tilt, command.speed),
      zoom: scale(command.zoom, command.speed),
    );
  }

  /// Pan and tilt for a finger at ([dx], [dy]) pixels from the pad centre, on a
  /// pad of [radius] pixels. Screen y grows downward, so moving the finger up
  /// tilts up. Inside [deadZone] (a fraction of the radius) nothing moves; speed
  /// then rises smoothly to full at the edge.
  static ({double pan, double tilt}) fromPad({
    required double dx,
    required double dy,
    required double radius,
    double deadZone = 0.15,
  }) {
    if (radius <= 0) {
      return (pan: 0, tilt: 0);
    }
    final double distance = sqrt(dx * dx + dy * dy);
    final double magnitude = _clamp(distance / radius, 0, 1);
    if (magnitude <= deadZone || distance == 0) {
      return (pan: 0, tilt: 0);
    }
    final double strength = (magnitude - deadZone) / (1 - deadZone);
    return (pan: dx / distance * strength, tilt: -dy / distance * strength);
  }

  /// Rounds to a [step] so tiny finger jitter does not flood the camera.
  static double quantize(double value, {double step = 0.1}) {
    return (value / step).roundToDouble() * step;
  }

  /// Whether [next] differs enough from [previous] to be worth sending.
  static bool isWorthSending(
    PtzVelocity previous,
    PtzVelocity next, {
    double threshold = 0.05,
  }) {
    return (previous.pan - next.pan).abs() >= threshold ||
        (previous.tilt - next.tilt).abs() >= threshold ||
        (previous.zoom - next.zoom).abs() >= threshold;
  }

  /// True when all three velocities are zero.
  static bool isStill(PtzVelocity velocity) {
    return velocity.pan == 0 && velocity.tilt == 0 && velocity.zoom == 0;
  }
}
