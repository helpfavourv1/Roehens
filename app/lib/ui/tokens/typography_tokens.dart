import 'package:flutter/widgets.dart';

/// The four typography roles. They are never interchangeable: buttons and the
/// tagline use [chrome], reading text uses [body], technical values use [mono].
enum AppTypeRole { display, chrome, body, mono }

/// Text styles (specification C3). System fonts only; the roles are realized
/// with weight, size, tracking and the platform monospace face.
///
/// Styles carry no color. Components apply a color token with `copyWith`.
class AppTypography {
  const AppTypography._({
    required this.scriptFactor,
    required this.display,
    required this.headline,
    required this.title1,
    required this.title2,
    required this.body,
    required this.callout,
    required this.footnote,
    required this.caption,
    required this.data,
    required this.overline,
    required this.mono,
  });

  /// Builds every style with line heights multiplied by [scriptFactor]
  /// (see [scriptFactorForLanguage]).
  factory AppTypography.forScript(double scriptFactor) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double letterSpacing = 0,
      bool tabular = false,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height * scriptFactor,
        letterSpacing: letterSpacing,
        fontFeatures:
            tabular ? const <FontFeature>[FontFeature.tabularFigures()] : null,
      );
    }

    return AppTypography._(
      scriptFactor: scriptFactor,
      display: style(34, FontWeight.w700, 1.10),
      headline: style(28, FontWeight.w600, 1.20),
      title1: style(22, FontWeight.w600, 1.30),
      title2: style(17, FontWeight.w600, 1.30),
      body: style(15, FontWeight.w400, 1.45),
      callout: style(15, FontWeight.w500, 1.40),
      footnote: style(13, FontWeight.w400, 1.40),
      caption: style(12, FontWeight.w400, 1.30),
      data: style(12, FontWeight.w500, 1.30, letterSpacing: 0.2, tabular: true),
      overline: style(11, FontWeight.w600, 1.20, letterSpacing: 0.8),
      mono: const TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: <String>['Menlo', 'Courier'],
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.40,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }

  final double scriptFactor;

  // Display role.
  final TextStyle display;
  final TextStyle headline;

  // Chrome role.
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle callout;
  final TextStyle overline;

  // Body role.
  final TextStyle body;
  final TextStyle footnote;
  final TextStyle caption;
  final TextStyle data;

  // Monospace role. Always rendered left-to-right by the widgets that use it.
  final TextStyle mono;

  /// Line-height multiplier per script. Tuned at Gate 2 on the cheapest device.
  /// Latin and Cyrillic 1.00, Hebrew 1.05, Vietnamese and CJK 1.10,
  /// Arabic, Persian, Urdu, Devanagari and Bengali 1.20, Thai 1.25.
  static double scriptFactorForLanguage(String languageCode) {
    switch (languageCode) {
      case 'he':
        return 1.05;
      case 'vi':
      case 'zh':
      case 'ja':
      case 'ko':
        return 1.10;
      case 'ar':
      case 'fa':
      case 'ur':
      case 'hi':
      case 'bn':
        return 1.20;
      case 'th':
        return 1.25;
      default:
        return 1.00;
    }
  }

  /// Whether the script has upper and lower case. The uppercase transform of
  /// [overline] applies only to cased scripts.
  static bool isCasedScript(String languageCode) {
    switch (languageCode) {
      case 'zh':
      case 'ja':
      case 'ko':
      case 'ar':
      case 'fa':
      case 'ur':
      case 'he':
      case 'hi':
      case 'bn':
      case 'th':
        return false;
      default:
        return true;
    }
  }
}
