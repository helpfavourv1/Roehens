import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/screens/fatal_error_screen.dart';
import 'package:roehens/screens/local_network_rationale_screen.dart';
import 'package:roehens/screens/onboarding_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('onboarding: three pages, the name only on the first', (
    WidgetTester tester,
  ) async {
    int finished = 0;
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      OnboardingScreen(onFinished: () => finished++),
      providers: h.app,
      size: const Size(400, 1000),
    );
    await settle(tester, milliseconds: 400);
    expect(find.text('Roehens'), findsOneWidget);
    expect(find.text('All your cameras in one place'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settle(tester, milliseconds: 500);
    expect(find.text('Made for your home network'), findsOneWidget);
    expect(find.text('Roehens'), findsNothing);
    expect(
      find.text('Works while Roehens is open on screen'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await settle(tester, milliseconds: 500);
    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Get started'));
    await settle(tester, milliseconds: 500);
    expect(finished, 1);
    expect(
      h.app.onboarding.value.completedVersion,
      AppConstants.onboardingVersion,
    );
  });

  testWidgets('onboarding: skip finishes at once', (WidgetTester tester) async {
    int finished = 0;
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      OnboardingScreen(onFinished: () => finished++),
      providers: h.app,
      size: const Size(400, 1000),
    );
    await settle(tester, milliseconds: 400);
    await tester.tap(find.text('Skip'));
    await settle(tester, milliseconds: 500);
    expect(finished, 1);
    expect(h.app.onboarding.needsOnboarding, isFalse);
  });

  test('the rationale is only needed where the system asks', () {
    expect(
      LocalNetworkRationaleScreen.isNeeded(PermissionStatus.notRequired),
      isFalse,
    );
    expect(
      LocalNetworkRationaleScreen.isNeeded(PermissionStatus.granted),
      isFalse,
    );
    expect(
      LocalNetworkRationaleScreen.isNeeded(PermissionStatus.unknown),
      isTrue,
    );
    expect(
      LocalNetworkRationaleScreen.isNeeded(PermissionStatus.denied),
      isTrue,
    );
  });

  testWidgets('rationale: explains first, then asks, then moves on', (
    WidgetTester tester,
  ) async {
    int done = 0;
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      permission: PermissionStatus.unknown,
      afterRequest: PermissionStatus.granted,
    );
    await pumpApp(
      tester,
      LocalNetworkRationaleScreen(onDone: () => done++),
      providers: h.app,
      size: const Size(400, 1000),
    );
    await settle(tester, milliseconds: 300);
    expect(find.text('Find cameras on your network'), findsOneWidget);
    expect(h.permissionFake.status, PermissionStatus.unknown);

    await tester.tap(find.text('Continue'));
    await settle(tester, milliseconds: 400);
    expect(h.permissionFake.status, PermissionStatus.granted);
    expect(h.app.onboarding.value.localNetworkRationaleSeen, isTrue);
    expect(done, 1);
  });

  testWidgets('rationale: a refusal turns into the way back to Settings', (
    WidgetTester tester,
  ) async {
    int done = 0;
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      permission: PermissionStatus.unknown,
      afterRequest: PermissionStatus.permanentlyDenied,
    );
    await pumpApp(
      tester,
      LocalNetworkRationaleScreen(onDone: () => done++),
      providers: h.app,
      size: const Size(400, 1000),
    );
    await settle(tester, milliseconds: 300);
    await tester.tap(find.text('Continue'));
    await settle(tester, milliseconds: 400);

    expect(find.text('Local network access is off'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(done, 0);
    await tester.tap(find.text('Not now'));
    expect(done, 1);
  });

  testWidgets('fatal error: retry and report', (WidgetTester tester) async {
    int retried = 0;
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      FatalErrorScreen(onRetry: () => retried++),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retried, 1);

    await tester.tap(find.text('Report this'));
    await settle(tester, milliseconds: 600);
    await tester.tap(find.text('Send without'));
    await settle(tester, milliseconds: 600);
    expect(h.links.mails.single.subject, 'Roehens problem report');

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 5000);
  });
}
