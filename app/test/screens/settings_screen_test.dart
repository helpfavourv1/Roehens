import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/screens/settings_screen.dart';
import 'package:roehens/ui/components/app_toast.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester, {VoidCallback? onHelp}) async {
  final ScreenHarness h = await ScreenHarness.boot(
    tester,
    cameras: <Camera>[cameraWithSub(id: 'a', name: 'Porch')],
  );
  await pumpApp(
    tester,
    SettingsScreen(onOpenHelp: onHelp),
    providers: h.app,
    size: const Size(400, 3000),
  );
  await settle(tester, milliseconds: 300);
  return h;
}

void main() {
  testWidgets('shows the groups and the current choices', (
    WidgetTester tester,
  ) async {
    await open(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Import and export'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);
    // Privacy and Terms wait for the website (batch P7C).
    expect(find.text('Privacy'), findsNothing);
  });

  testWidgets('Help appears only when the app wires it in', (
    WidgetTester tester,
  ) async {
    await open(tester);
    expect(find.text('Help'), findsNothing);
  });

  testWidgets('Help opens what the app gives it', (WidgetTester tester) async {
    int opened = 0;
    await open(tester, onHelp: () => opened++);
    await tester.tap(find.text('Help'));
    expect(opened, 1);
  });

  testWidgets('a switch changes the saved setting', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    final bool before = h.app.settings.value.keepAwake;

    await tester.tap(find.text('Keep the screen on while viewing'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.keepAwake, !before);
  });

  testWidgets('auto-cycle shows its intervals only while on', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    expect(find.text('30 s'), findsNothing);

    await tester.tap(find.text('Auto-cycle'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.autoCycleEnabled, isTrue);
    await tester.tap(find.text('30 s'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.autoCycleSeconds, 30);
  });

  testWidgets('the transport choice is saved', (WidgetTester tester) async {
    final ScreenHarness h = await open(tester);
    await tester.tap(find.text('TCP'));
    await settle(tester, milliseconds: 300);
    expect(h.app.settings.value.defaultTransport, StreamTransport.tcp);
  });

  testWidgets('feedback asks before attaching diagnostics', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);

    await tester.tap(find.text('Send feedback'));
    await settle(tester, milliseconds: 600);
    expect(find.text('Attach diagnostics?'), findsOneWidget);
    await tester.tap(find.text('Send without'));
    await settle(tester, milliseconds: 600);
    expect(h.links.mails.single.to, 'stmakarios@gmail.com');
    expect(h.links.mails.single.body, isEmpty);

    await tester.tap(find.text('Send feedback'));
    await settle(tester, milliseconds: 600);
    await tester.tap(find.text('Attach diagnostics'));
    await settle(tester, milliseconds: 600);
    expect(h.links.mails.last.body, contains('diagnostics'));
    // Diagnostics never carry camera addresses or names.
    expect(h.links.mails.last.body, isNot(contains('192.168.1.10')));
    expect(h.links.mails.last.body, isNot(contains('Porch')));
  });

  testWidgets('cancelling the feedback dialog sends nothing', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    await tester.tap(find.text('Send feedback'));
    await settle(tester, milliseconds: 600);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester, milliseconds: 600);
    expect(h.links.mails, isEmpty);
  });

  testWidgets('delete all asks first, then removes everything', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    await tester.tap(find.text('Delete all local data'));
    await settle(tester, milliseconds: 600);
    expect(find.text('Delete everything on this phone?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await settle(tester, milliseconds: 600);
    expect(h.app.cameras.value.cameras.length, 1);

    await tester.tap(find.text('Delete all local data'));
    await settle(tester, milliseconds: 600);
    await tester.tap(find.text('Delete everything'));
    final StringBuffer timeline = StringBuffer();
    for (int i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      timeline.write(AppToast.isShowing ? 'T' : '.');
      timeline.write(h.app.cameras.value.cameras.isEmpty ? 'c' : '-');
      timeline.write(' ');
    }
    expect(h.app.cameras.value.cameras, isEmpty, reason: 'cameras');
    expect(h.app.settings.value.keepAwake, const AppSettings().keepAwake);
    expect(
      h.app.onboarding.needsOnboarding,
      isTrue,
      reason: 'onboarding reset',
    );
    expect(h.app.subscription.isAdFree, isFalse, reason: 'subscription reset');
    expect(AppToast.isShowing, isTrue, reason: 'timeline: $timeline');
    // Find out how long the toast takes, so a real delay is not hidden.
    int waited = 0;
    while (find.text('Everything was deleted.').evaluate().isEmpty &&
        waited < 10000) {
      await tester.pump(const Duration(milliseconds: 100));
      waited += 100;
    }
    expect(
      find.text('Everything was deleted.'),
      findsOneWidget,
      reason: 'toast not shown within ${waited + 2500} ms of the tap',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 5000);
  });

  testWidgets('restore checks the purchase', (WidgetTester tester) async {
    final ScreenHarness h = await open(tester);
    await tester.tap(find.text('Restore purchase'));
    await settle(tester, milliseconds: 600);
    expect(h.purchase.restoreCalls, 1);
    expect(find.text('Purchase checked.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 5000);
  });
}
