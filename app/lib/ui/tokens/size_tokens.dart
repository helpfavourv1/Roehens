/// Fixed sizes (specification C1.5, C3, C5 and C8.4).
class AppSizes {
  AppSizes._();

  /// Minimum hit area of any tappable element.
  static const double touchTarget = 48;

  /// Visible chip inside the hit area of an icon button.
  static const double iconChip = 40;

  /// Hairline border width.
  static const double hairline = 0.5;

  static const double buttonMinHeight = 48;
  static const double navBarHeight = 56;
  static const double bottomBarHeight = 64;

  static const double ptzPad = 176;
  static const double ptzPadTablet = 208;

  /// Icon sizes by role.
  static const double iconNavBar = 24;
  static const double iconRowLeading = 24;
  static const double iconRowTrailing = 20;
  static const double iconChipGlyph = 16;
  static const double iconBottomBar = 24;
  static const double iconPtz = 28;
  static const double iconHero = 48;

  /// Below this tile width the status pill shows its icon only and a tap opens
  /// a sheet with the full message (D5).
  static const double tileIconOnlyWidth = 120;

  /// Upper bound of the reserved banner-ad height (C8.4).
  static const double bannerMaxHeight = 100;

  /// Shortest screen side from which the tablet layout applies.
  static const double tabletShortestSide = 600;

  /// Text scaling: layouts reflow up to this factor; tile overlays are clamped.
  static const double maxTextScale = 3.1;
  static const double tileOverlayMaxTextScale = 1.3;
}
