import 'package:flutter/animation.dart';

/// Durations and curves (specification C6). No springs and no framework
/// standard curves: both curves are defined here and nowhere else.
class AppMotion {
  AppMotion._();

  /// Fast out, slow in: screen transitions.
  static const Curve glide = Cubic(0.70, 0.00, 0.20, 1.00);

  /// Quick start, soft landing: sheets, press feedback, crossfades.
  static const Curve settle = Cubic(0.12, 0.90, 0.28, 1.00);

  /// Constant speed (this cubic is the identity curve).
  static const Curve linear = Cubic(0.0, 0.0, 1.0, 1.0);

  static const Duration screenPush = Duration(milliseconds: 350);
  static const Duration screenPop = Duration(milliseconds: 280);
  static const Duration sheetPresent = Duration(milliseconds: 400);
  static const Duration press = Duration(milliseconds: 120);
  static const Duration tileConnect = Duration(milliseconds: 200);
  static const Duration adSlot = Duration(milliseconds: 200);
  static const Duration controlsFade = Duration(milliseconds: 200);
  static const Duration autoCycle = Duration(milliseconds: 200);
  static const Duration themeToggle = Duration(milliseconds: 200);
  static const Duration livePulse = Duration(milliseconds: 1600);

  /// Idle time before fullscreen controls hide.
  static const Duration controlsIdle = Duration(seconds: 3);

  /// Horizontal slide distance of a pushed screen, in logical pixels.
  static const double pushSlideDistance = 20;

  /// Opacity of a pressed card, tile, button or chip. There is no scale.
  static const double pressedOpacity = 0.72;

  /// Lowest opacity of the live-pulse loop.
  static const double pulseMinOpacity = 0.45;

  /// Returns [Duration.zero] when the person asked to reduce motion.
  static Duration resolve(Duration duration, {required bool reduceMotion}) {
    return reduceMotion ? Duration.zero : duration;
  }
}
