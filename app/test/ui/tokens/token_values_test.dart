import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/typography_tokens.dart';

double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final Map<String, AppColors> themes = <String, AppColors>{
    'dark': AppColors.dark,
    'light': AppColors.light,
  };

  for (final MapEntry<String, AppColors> entry in themes.entries) {
    final AppColors c = entry.value;
    group('${entry.key} contrast (WCAG AA, 4.5:1)', () {
      test('body text on the surfaces it sits on', () {
        expect(contrast(c.textPrimary, c.bgPrimary), greaterThanOrEqualTo(4.5));
        expect(
          contrast(c.textPrimary, c.bgSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.textPrimary, c.bgElevated),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.textSecondary, c.bgSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.textSecondary, c.bgTertiary),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('tertiary text on cards, scaffold and inputs', () {
        expect(
          contrast(c.textTertiary, c.bgSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.textTertiary, c.bgPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.textTertiary, c.bgTertiary),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('label on the accent fill and accent text on the scaffold', () {
        expect(contrast(c.textOnAccent, c.accent), greaterThanOrEqualTo(4.5));
        expect(contrast(c.accent, c.bgPrimary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.accent, c.bgSecondary), greaterThanOrEqualTo(4.5));
      });

      test('status colors on cards', () {
        expect(contrast(c.error, c.bgSecondary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.warning, c.bgSecondary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.success, c.bgSecondary), greaterThanOrEqualTo(4.5));
      });

      test('stream status tokens alias the status colors', () {
        expect(c.streamLive, c.success);
        expect(c.streamConnecting, c.warning);
        expect(c.streamError, c.error);
        expect(c.streamOffline, c.textTertiary);
      });
    });
  }

  test('video backdrop is identical in both themes', () {
    expect(AppColors.dark.videoBackdrop, AppColors.light.videoBackdrop);
  });

  group('typography', () {
    test('script factors follow the specification', () {
      expect(AppTypography.scriptFactorForLanguage('en'), 1.00);
      expect(AppTypography.scriptFactorForLanguage('ru'), 1.00);
      expect(AppTypography.scriptFactorForLanguage('he'), 1.05);
      expect(AppTypography.scriptFactorForLanguage('vi'), 1.10);
      expect(AppTypography.scriptFactorForLanguage('ja'), 1.10);
      expect(AppTypography.scriptFactorForLanguage('ar'), 1.20);
      expect(AppTypography.scriptFactorForLanguage('hi'), 1.20);
      expect(AppTypography.scriptFactorForLanguage('th'), 1.25);
    });

    test('line height is multiplied by the script factor', () {
      final AppTypography latin = AppTypography.forScript(1.0);
      final AppTypography thai = AppTypography.forScript(1.25);
      expect(latin.body.height, closeTo(1.45, 1e-9));
      expect(thai.body.height, closeTo(1.45 * 1.25, 1e-9));
    });

    test('uppercase applies only to cased scripts', () {
      expect(AppTypography.isCasedScript('en'), isTrue);
      expect(AppTypography.isCasedScript('ru'), isTrue);
      expect(AppTypography.isCasedScript('ar'), isFalse);
      expect(AppTypography.isCasedScript('zh'), isFalse);
    });

    test('changing numbers use tabular figures', () {
      final AppTypography t = AppTypography.forScript(1.0);
      expect(t.data.fontFeatures, isNotNull);
      expect(t.mono.fontFeatures, isNotNull);
    });
  });
}
