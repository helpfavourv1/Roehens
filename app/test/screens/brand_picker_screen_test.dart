import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/screens/brand_picker_screen.dart';

import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('choosing a brand returns it to the form', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    CameraBrandProfile? chosen;
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => GestureDetector(
          onTap: () async => chosen = await openBrandPicker(context),
          child: const Text('open'),
        ),
      ),
      providers: h.app,
      size: const Size(400, 1600),
    );
    await tester.tap(find.text('open'));
    await settle(tester, milliseconds: 800);

    expect(find.text('Brand'), findsOneWidget);
    await tester.tap(find.text('Generic RTSP'));
    await settle(tester, milliseconds: 800);

    expect(chosen?.displayName, 'Generic RTSP');
  });

  testWidgets('going back chooses nothing', (WidgetTester tester) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    CameraBrandProfile? chosen;
    bool done = false;
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => GestureDetector(
          onTap: () async {
            chosen = await openBrandPicker(context);
            done = true;
          },
          child: const Text('open'),
        ),
      ),
      providers: h.app,
    );
    await tester.tap(find.text('open'));
    await settle(tester, milliseconds: 800);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester, milliseconds: 800);

    expect(done, isTrue);
    expect(chosen, isNull);
  });
}
