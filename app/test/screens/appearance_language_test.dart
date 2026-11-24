import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/languages.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/screens/appearance_screen.dart';
import 'package:roehens/screens/language_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('appearance: choosing a theme saves it', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(tester, const AppearanceScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Light'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.themeMode, AppThemeMode.light);
    await tester.tap(find.text('Dark'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.themeMode, AppThemeMode.dark);
  });

  testWidgets('language: lists all 24 by their own names', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      const LanguageScreen(),
      providers: h.app,
      size: const Size(400, 4000),
    );
    await settle(tester, milliseconds: 300);

    expect(find.text('System default'), findsOneWidget);
    for (final AppLanguage l in appLanguages) {
      expect(find.text(l.nativeName), findsOneWidget, reason: l.code);
    }
  });

  test('language search matches the native name or the code', () {
    expect(
      LanguageScreenSearch.matching('fran').map((AppLanguage l) => l.code),
      <String>['fr'],
    );
    expect(
      LanguageScreenSearch.matching('pt_').map((AppLanguage l) => l.code),
      <String>['pt_BR'],
    );
    expect(LanguageScreenSearch.matching('  '), appLanguages);
    expect(LanguageScreenSearch.matching('zzz'), isEmpty);
  });

  testWidgets('language: choosing one saves the code and goes back', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext c) => GestureDetector(
          onTap: () => openLanguage(c),
          child: const Text('open'),
        ),
      ),
      providers: h.app,
      size: const Size(400, 4000),
    );
    await tester.tap(find.text('open'));
    await settle(tester, milliseconds: 800);

    await tester.tap(find.text('Français'));
    await settle(tester, milliseconds: 800);
    expect(h.app.settings.value.localeCode, 'fr');
    expect(find.text('Français'), findsNothing);
  });

  testWidgets('language: an unknown search says nothing matches', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      const LanguageScreen(),
      providers: h.app,
      size: const Size(400, 1000),
    );
    await settle(tester, milliseconds: 300);
    await tester.enterText(find.byType(EditableText), 'qqq');
    await settle(tester, milliseconds: 300);
    expect(find.text('No language matches'), findsOneWidget);
  });
}
