import 'package:flutter/widgets.dart';

/// Spacing on a 4px grid (specification C5).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Gap between video tiles.
  static const double gridGutterPhone = 4;
  static const double gridGutterTablet = 8;

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsetsDirectional horizontalMd =
      EdgeInsetsDirectional.symmetric(horizontal: md);
  static const EdgeInsetsDirectional verticalSm =
      EdgeInsetsDirectional.symmetric(vertical: sm);
  static const EdgeInsetsDirectional verticalMd =
      EdgeInsetsDirectional.symmetric(vertical: md);
}
