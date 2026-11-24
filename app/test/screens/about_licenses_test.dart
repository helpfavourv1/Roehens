import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/license_collector.dart';
import 'package:roehens/screens/about_screen.dart';
import 'package:roehens/screens/licenses_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('about: support mail and the plain statement', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(tester, const AboutScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    expect(find.text('Version'), findsOneWidget);
    expect(find.textContaining('while it is open on screen'), findsOneWidget);
    await tester.tap(find.text('stmakarios@gmail.com'));
    await settle(tester, milliseconds: 300);
    expect(h.links.mails.single.to, 'stmakarios@gmail.com');
  });

  testWidgets('about: a missing mail app is explained', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    h.links.canOpen = false;
    await pumpApp(tester, const AboutScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);
    await tester.tap(find.text('stmakarios@gmail.com'));
    await settle(tester, milliseconds: 400);
    expect(find.text('No mail app could be opened.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 5000);
  });

  testWidgets('licenses: packages, then the full text', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      LicensesScreen(
        loader: () async => const <PackageLicense>[
          PackageLicense(name: 'alpha', texts: <String>['Alpha text']),
          PackageLicense(name: 'beta', texts: <String>['One', 'Two']),
        ],
      ),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('2 licenses'), findsOneWidget);
    await tester.tap(find.text('alpha'));
    await settle(tester, milliseconds: 800);
    expect(find.text('Alpha text'), findsOneWidget);
  });

  testWidgets('licenses: none is said in words', (WidgetTester tester) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      LicensesScreen(loader: () async => const <PackageLicense>[]),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);
    expect(find.text('No license information is available.'), findsOneWidget);
  });

  test('the collector groups by package, sorts and drops repeats', () async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(<String>['zeta'], 'Z text');
      yield const LicenseEntryWithLineBreaks(<String>['Alpha'], 'A text');
      yield const LicenseEntryWithLineBreaks(<String>['Alpha'], 'A text');
      yield const LicenseEntryWithLineBreaks(<String>['Alpha', 'zeta'], 'Both');
    });
    final List<PackageLicense> all = await LicenseCollector.collect();
    final List<String> names = all.map((PackageLicense p) => p.name).toList();
    expect(names.indexOf('Alpha'), lessThan(names.indexOf('zeta')));
    expect(
      all.firstWhere((PackageLicense p) => p.name == 'Alpha').texts,
      <String>['A text', 'Both'],
    );
    expect(
      all.firstWhere((PackageLicense p) => p.name == 'zeta').texts,
      <String>['Z text', 'Both'],
    );
  });
}
