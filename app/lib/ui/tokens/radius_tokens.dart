import 'package:flutter/widgets.dart';

/// Corner radii (specification C5). The video tile uses [md], the one recorded
/// exception to the card radius [lg] (C8.9).
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  /// Sheets round their top corners only.
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
}
