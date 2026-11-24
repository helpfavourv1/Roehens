import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/screens/upgrade_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('shows the store price and buys', (WidgetTester tester) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await tester.runAsync(h.app.subscription.init);
    await pumpApp(tester, const UpgradeScreen(), providers: h.app);
    await settle(tester, milliseconds: 500);

    expect(find.text(r'Remove ads for $2.99'), findsOneWidget);
    await tester.tap(find.text(r'Remove ads for $2.99'));
    await settle(tester, milliseconds: 300);
    expect(h.purchase.buyCalls, 1);
    // Restore is always on screen.
    expect(find.text('Restore purchase'), findsOneWidget);
  });

  testWidgets('without a price the buy button waits and says why', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    h.purchase.product = null;
    await tester.runAsync(h.app.subscription.init);
    await pumpApp(tester, const UpgradeScreen(), providers: h.app);
    await settle(tester, milliseconds: 500);

    expect(find.text('The price is not available right now.'), findsOneWidget);
    await tester.tap(find.text('Remove ads for '));
    expect(h.purchase.buyCalls, 0);
  });

  testWidgets('an owner sees thanks, not a buy button', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    h.purchase.current = Entitlement(
      tier: EntitlementTier.adFree,
      source: EntitlementSource.purchase,
      verifiedAt: DateTime.utc(2026, 10, 4),
    );
    await tester.runAsync(h.app.subscription.init);
    await pumpApp(tester, const UpgradeScreen(), providers: h.app);
    await settle(tester, milliseconds: 500);

    expect(
      find.text('Ads are removed. Thank you for supporting Roehens.'),
      findsOneWidget,
    );
    expect(find.textContaining('Remove ads for'), findsNothing);
  });

  testWidgets('a failed purchase says so in words', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await tester.runAsync(h.app.subscription.init);
    await pumpApp(tester, const UpgradeScreen(), providers: h.app);
    await settle(tester, milliseconds: 500);

    h.purchase.failureController.add(const AppError(ErrorClass.purchaseFailed));
    await settle(tester, milliseconds: 300);
    expect(find.text("The purchase didn't go through"), findsOneWidget);
  });
}
