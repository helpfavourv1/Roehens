import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/screens/main_shell.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('three tabs; each keeps its own state', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[cameraWithSub(id: 'a', name: 'Porch')],
    );
    await pumpApp(
      tester,
      MainShell(
        settingsBuilder: (BuildContext _) => const Text('settings body'),
        onAddCamera: () {},
        onFindCameras: () {},
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester);

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Cameras'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('settings body'), findsNothing);
    expect(h.sessions, isNotEmpty);

    await tester.tap(find.text('Settings'));
    await settle(tester, milliseconds: 300);
    expect(find.text('settings body'), findsOneWidget);

    await tester.tap(find.text('Cameras'));
    await settle(tester, milliseconds: 300);
    expect(find.text('Search cameras'), findsOneWidget);

    // Leaving Live releases its decoders.
    await settle(tester, milliseconds: 600);
    expect(h.app.live.plan.tiles, isEmpty);
  });
}
