import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/ptz_math.dart';

void main() {
  group('velocityFor', () {
    test('a continuous command is scaled by its speed', () {
      final PtzVelocity velocity = PtzMath.velocityFor(
        PtzCommand.continuous(pan: 1, tilt: -0.5, zoom: 0.4, speed: 0.5),
      );
      expect(velocity.pan, 0.5);
      expect(velocity.tilt, -0.25);
      expect(velocity.zoom, closeTo(0.2, 1e-9));
    });

    test('other command kinds ask for no movement', () {
      expect(PtzMath.isStill(PtzMath.velocityFor(const PtzCommand.stop())), isTrue);
      expect(PtzMath.isStill(PtzMath.velocityFor(const PtzCommand.home())), isTrue);
      expect(
        PtzMath.isStill(PtzMath.velocityFor(const PtzCommand.preset('3'))),
        isTrue,
      );
    });

    test('speed outside 0..1 cannot push a velocity past the limits', () {
      expect(PtzMath.scale(1, 5), 1);
      expect(PtzMath.scale(-1, 5), -1);
      expect(PtzMath.scale(1, -2), 0);
    });
  });

  group('fromPad', () {
    test('the centre and the dead zone do not move the camera', () {
      expect(PtzMath.fromPad(dx: 0, dy: 0, radius: 100), (pan: 0.0, tilt: 0.0));
      final ({double pan, double tilt}) small =
          PtzMath.fromPad(dx: 10, dy: 5, radius: 100);
      expect(small.pan, 0);
      expect(small.tilt, 0);
    });

    test('the edge of the pad is full speed in that direction', () {
      final ({double pan, double tilt}) right =
          PtzMath.fromPad(dx: 100, dy: 0, radius: 100);
      expect(right.pan, closeTo(1, 1e-9));
      expect(right.tilt, closeTo(0, 1e-9));

      final ({double pan, double tilt}) left =
          PtzMath.fromPad(dx: -100, dy: 0, radius: 100);
      expect(left.pan, closeTo(-1, 1e-9));
    });

    test('moving the finger up tilts up', () {
      final ({double pan, double tilt}) up =
          PtzMath.fromPad(dx: 0, dy: -100, radius: 100);
      expect(up.tilt, closeTo(1, 1e-9));
      final ({double pan, double tilt}) down =
          PtzMath.fromPad(dx: 0, dy: 100, radius: 100);
      expect(down.tilt, closeTo(-1, 1e-9));
    });

    test('past the edge is capped and speed rises smoothly', () {
      final ({double pan, double tilt}) far =
          PtzMath.fromPad(dx: 500, dy: 0, radius: 100);
      expect(far.pan, closeTo(1, 1e-9));
      final ({double pan, double tilt}) a =
          PtzMath.fromPad(dx: 40, dy: 0, radius: 100);
      final ({double pan, double tilt}) b =
          PtzMath.fromPad(dx: 70, dy: 0, radius: 100);
      expect(a.pan, greaterThan(0));
      expect(b.pan, greaterThan(a.pan));
    });

    test('a diagonal keeps both directions and never exceeds full speed', () {
      final ({double pan, double tilt}) diagonal =
          PtzMath.fromPad(dx: 100, dy: -100, radius: 100);
      expect(diagonal.pan, greaterThan(0));
      expect(diagonal.tilt, greaterThan(0));
      expect(
        diagonal.pan * diagonal.pan + diagonal.tilt * diagonal.tilt,
        lessThanOrEqualTo(1 + 1e-9),
      );
    });

    test('a pad with no size does nothing', () {
      expect(PtzMath.fromPad(dx: 5, dy: 5, radius: 0), (pan: 0.0, tilt: 0.0));
    });
  });

  group('throttling helpers', () {
    test('quantize rounds to the step', () {
      expect(PtzMath.quantize(0.34), closeTo(0.3, 1e-9));
      expect(PtzMath.quantize(0.36), closeTo(0.4, 1e-9));
      expect(PtzMath.quantize(-0.34), closeTo(-0.3, 1e-9));
    });

    test('only a meaningful change is worth sending', () {
      const PtzVelocity a = (pan: 0.5, tilt: 0.0, zoom: 0.0);
      expect(PtzMath.isWorthSending(a, (pan: 0.52, tilt: 0.0, zoom: 0.0)), isFalse);
      expect(PtzMath.isWorthSending(a, (pan: 0.6, tilt: 0.0, zoom: 0.0)), isTrue);
      expect(PtzMath.isWorthSending(a, (pan: 0.5, tilt: 0.0, zoom: 0.1)), isTrue);
    });
  });
}
