import 'package:flutter/widgets.dart';

/// Semantic color tokens (specification C2). Widgets read colors only through
/// these names; raw color literals are allowed only in this directory.
///
/// Status is never conveyed by color alone: every status pill pairs its color
/// with an icon and a text label.
class AppColors {
  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgElevated,
    required this.videoBackdrop,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.accent,
    required this.accentDim,
    required this.accentWash,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.error,
    required this.warning,
    required this.success,
    required this.scrim,
    required this.overlayOnVideo,
  });

  /// Scaffold background.
  final Color bgPrimary;

  /// Cards and list groups.
  final Color bgSecondary;

  /// Inputs, disabled surfaces and the row press tint.
  final Color bgTertiary;

  /// Sheets, dialogs and menus.
  final Color bgElevated;

  /// Behind every video surface, identical in both themes.
  final Color videoBackdrop;

  /// Hairlines and dividers.
  final Color borderSubtle;

  /// Inputs at rest and chips.
  final Color borderStrong;

  /// Focused input.
  final Color borderFocus;

  /// Primary action, active navigation and selection.
  final Color accent;

  /// Pressed state of the accent.
  final Color accentDim;

  /// Selected row and active chip fill.
  final Color accentWash;

  final Color textPrimary;
  final Color textSecondary;

  /// Hints, timestamps and disabled text.
  final Color textTertiary;

  /// Label on an accent fill.
  final Color textOnAccent;

  final Color error;
  final Color warning;
  final Color success;

  /// Behind sheets.
  final Color scrim;

  /// Label plates drawn over video.
  final Color overlayOnVideo;

  /// Text drawn on [overlayOnVideo]. Always white, in both themes.
  Color get onVideoText => const Color(0xFFFFFFFF);

  Color get streamLive => success;
  Color get streamConnecting => warning;
  Color get streamError => error;
  Color get streamOffline => textTertiary;

  static const AppColors dark = AppColors(
    bgPrimary: Color(0xFF0A0C0F),
    bgSecondary: Color(0xFF11141A),
    bgTertiary: Color(0xFF171B22),
    bgElevated: Color(0xFF1D222B),
    videoBackdrop: Color(0xFF050608),
    borderSubtle: Color(0xFF232933),
    borderStrong: Color(0xFF323A46),
    borderFocus: Color(0xFF5B9DFF),
    accent: Color(0xFF5B9DFF),
    accentDim: Color(0xFF3F7FE0),
    accentWash: Color(0x245B9DFF),
    textPrimary: Color(0xFFEDF0F4),
    textSecondary: Color(0xFFA4ADBA),
    textTertiary: Color(0xFF7C8695),
    textOnAccent: Color(0xFF061224),
    error: Color(0xFFFF6B6B),
    warning: Color(0xFFF5B84A),
    success: Color(0xFF4ADE80),
    scrim: Color(0x8F000000),
    overlayOnVideo: Color(0x7A000000),
  );

  static const AppColors light = AppColors(
    bgPrimary: Color(0xFFF4F6F9),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFECEFF3),
    bgElevated: Color(0xFFFFFFFF),
    videoBackdrop: Color(0xFF050608),
    borderSubtle: Color(0xFFDCE1E8),
    borderStrong: Color(0xFFC6CDD7),
    borderFocus: Color(0xFF2F6CDD),
    accent: Color(0xFF2F6CDD),
    accentDim: Color(0xFF2258BA),
    accentWash: Color(0x1A2F6CDD),
    textPrimary: Color(0xFF10141A),
    textSecondary: Color(0xFF465060),
    textTertiary: Color(0xFF636D7D),
    textOnAccent: Color(0xFFFFFFFF),
    error: Color(0xFFD13636),
    warning: Color(0xFF9A5B00),
    success: Color(0xFF17803D),
    scrim: Color(0x6610141A),
    overlayOnVideo: Color(0x7A000000),
  );
}
