import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/screens/layout_sheet.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  Future<ScreenHarness> open(WidgetTester tester) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[
        for (int i = 0; i < 3; i++)
          cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
      ],
    );
    await pumpApp(
      tester,
      const LayoutSheetContent(),
      providers: h.app,
      size: const Size(400, 1400),
    );
    await settle(tester, milliseconds: 300);
    return h;
  }

  testWidgets('choosing a size changes the grid', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester);
    expect(h.app.layout.value.pageSize, 4);

    await tester.tap(find.text('9'));
    await settle(tester, milliseconds: 300);

    expect(h.app.layout.value.pageSize, 9);
    expect(find.text('9 cameras per page'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('cameras can be moved up and down; the ends cannot', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester);

    await tester.tap(find.bySemanticsLabel('Move Cam 1 up'));
    await settle(tester, milliseconds: 300);
    expect(h.app.layout.value.cameraIds, <String>['c1', 'c0', 'c2']);

    await tester.tap(find.bySemanticsLabel('Move Cam 0 down'));
    await settle(tester, milliseconds: 300);
    expect(h.app.layout.value.cameraIds, <String>['c1', 'c2', 'c0']);
    semantics.dispose();
  });

  testWidgets('the auto-cycle interval is per layout, with a default', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    expect(h.app.layout.value.autoCycleSeconds, isNull);

    await tester.tap(find.text('30 s'));
    await settle(tester, milliseconds: 300);
    expect(h.app.layout.value.autoCycleSeconds, 30);

    await tester.tap(find.text('Use default'));
    await settle(tester, milliseconds: 300);
    expect(h.app.layout.value.autoCycleSeconds, isNull);
  });
}
