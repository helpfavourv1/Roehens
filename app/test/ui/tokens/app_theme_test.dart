import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/tokens/app_theme.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';

void main() {
  group('AppTheme', () {
    test('builds a dark and a light token set', () {
      expect(AppTheme.dark().isDark, isTrue);
      expect(AppTheme.light().isDark, isFalse);
      expect(
        AppTheme.dark().colors.bgPrimary,
        isNot(AppTheme.light().colors.bgPrimary),
      );
    });

    test('a script factor makes lines taller for scripts that need it', () {
      final double latin = AppTheme.dark().typography.body.height!;
      final double thai = AppTheme.dark(scriptFactor: 1.25)
          .typography
          .body
          .height!;
      expect(thai, closeTo(latin * 1.25, 0.001));
    });

    test('the base text style has no underline and the primary text color', () {
      final AppTokensData tokens = AppTheme.dark();
      final TextStyle style = AppTheme.baseTextStyle(tokens);
      expect(style.decoration, TextDecoration.none);
      expect(style.color, tokens.colors.textPrimary);
    });

    test(
      'system bars are transparent and their icons contrast with the theme',
      () {
        final SystemUiOverlayStyle dark = AppTheme.overlayStyle(
          AppTheme.dark(),
        );
        final SystemUiOverlayStyle light = AppTheme.overlayStyle(
          AppTheme.light(),
        );
        expect(dark.statusBarColor!.a, 0);
        expect(dark.systemNavigationBarColor!.a, 0);
        expect(dark.statusBarIconBrightness, Brightness.light);
        expect(light.statusBarIconBrightness, Brightness.dark);
      },
    );
  });

  group('AppScrollBehavior', () {
    testWidgets('lists use clamping physics and show no overscroll glow', (
      WidgetTester tester,
    ) async {
      const AppScrollBehavior behavior = AppScrollBehavior();
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox();
          },
        ),
      );
      expect(behavior.getScrollPhysics(captured), isA<ClampingScrollPhysics>());
      const SizedBox child = SizedBox();
      expect(
        behavior.buildOverscrollIndicator(
          captured,
          child,
          const ScrollableDetails(
            direction: AxisDirection.down,
            controller: null,
            physics: null,
          ),
        ),
        same(child),
      );
    });
  });
}
