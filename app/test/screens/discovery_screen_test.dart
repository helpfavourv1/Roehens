import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/screens/discovery_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('results appear as cameras answer and a tap picks one', (
    WidgetTester tester,
  ) async {
    DiscoveryResult? picked;
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      DiscoveryScreen(onPick: (DiscoveryResult r) => picked = r, onManual: () {}),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);
    expect(find.text('Looking for cameras on your network…'), findsOneWidget);

    h.discovery.controller.add(
      const DiscoveryFound(
        DiscoveryResult(
          host: '10.0.0.8',
          port: 80,
          source: DiscoverySource.onvif,
          name: 'Garage',
          model: 'X1',
        ),
      ),
    );
    h.discovery.controller.add(const DiscoveryFinished());
    await settle(tester, milliseconds: 300);

    expect(find.text('1 camera found'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('ONVIF'), findsOneWidget);
    await tester.tap(find.text('Garage'));
    expect(picked?.host, '10.0.0.8');
  });

  testWidgets('finding nothing says what to check and offers manual entry', (
    WidgetTester tester,
  ) async {
    int manual = 0;
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(
      tester,
      DiscoveryScreen(onPick: (_) {}, onManual: () => manual++),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);
    h.discovery.controller.add(const DiscoveryFinished());
    await settle(tester, milliseconds: 300);

    expect(find.text('No cameras found'), findsOneWidget);
    await tester.tap(find.text('Add a camera by hand'));
    expect(manual, 1);
  });

  testWidgets('a refused permission explains and points to Settings', (
    WidgetTester tester,
  ) async {
    int manual = 0;
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      permission: PermissionStatus.permanentlyDenied,
    );
    await pumpApp(
      tester,
      DiscoveryScreen(onPick: (_) {}, onManual: () => manual++),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);

    expect(find.text('Local network access is off'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(h.discovery.runs, 0);
    await tester.tap(find.text('Add a camera by hand'));
    expect(manual, 1);
  });
}
