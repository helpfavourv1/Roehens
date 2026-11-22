import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/screens/fullscreen_screen.dart';
import 'package:roehens/screens/home_screen.dart';

import 'package:roehens/core/models/camera.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

void main() {
  testWidgets('with no cameras it offers to add one or to find them', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    int added = 0;
    int found = 0;
    await pumpApp(
      tester,
      HomeScreen(
        isActive: true,
        onAddCamera: () => added++,
        onFindCameras: () => found++,
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester, milliseconds: 300);

    expect(find.text('No cameras yet'), findsOneWidget);
    await tester.tap(find.text('Find cameras on my network'));
    expect(found, 1);
    await tester.tap(find.text('Add camera'));
    expect(added, 1);
    // No camera, so nothing decodes.
    expect(h.sessions, isEmpty);
  });

  testWidgets('cameras show as tiles and only they decode', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[
        cameraWithSub(id: 'a', name: 'Porch'),
        cameraWithSub(id: 'b', name: 'Garage', sortIndex: 1),
      ],
    );
    await pumpApp(
      tester,
      HomeScreen(
        isActive: true,
        onAddCamera: () {},
        onFindCameras: () {},
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester);

    expect(find.text('Porch'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);
    expect(h.sessions.length, 2);
    for (final session in h.sessions) {
      expect(session.opened.single.uri.path, '/sub');
    }
  });

  testWidgets('a single page shows no page dots; two pages do', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[
        for (int i = 0; i < 5; i++)
          cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
      ],
    );
    await pumpApp(
      tester,
      HomeScreen(
        isActive: true,
        onAddCamera: () {},
        onFindCameras: () {},
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester);

    expect(find.bySemanticsLabel('Page 1 of 2'), findsOneWidget);
    // Page 1 holds four of the five cameras.
    expect(h.sessions.length, 4);
    semantics.dispose();
  });

  testWidgets('a swipe turns the page and a different camera decodes', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[
        for (int i = 0; i < 5; i++)
          cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
      ],
    );
    await pumpApp(
      tester,
      HomeScreen(
        isActive: true,
        onAddCamera: () {},
        onFindCameras: () {},
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester);

    await tester.fling(find.text('Cam 0'), const Offset(-300, 0), 1500);
    await settle(tester);

    expect(h.app.layout.page.value, 1);
    expect(find.text('Cam 4'), findsOneWidget);
  });

  testWidgets('tapping a tile opens it fullscreen and closing returns', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[cameraWithSub(id: 'a', name: 'Porch')],
    );
    await pumpApp(
      tester,
      HomeScreen(
        isActive: true,
        onAddCamera: () {},
        onFindCameras: () {},
        onEditCamera: (_) {},
      ),
      providers: h.app,
    );
    await settle(tester);

    await tester.tap(find.text('Porch'));
    await settle(tester);
    expect(find.byType(FullscreenScreen), findsOneWidget);
    expect(h.app.live.focusedId, 'a');

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 4000);
  });
}
