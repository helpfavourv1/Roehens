import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/screens/cameras_screen.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  List<Camera>? cameras,
  void Function(Camera)? onEdit,
  VoidCallback? onAdd,
}) async {
  final ScreenHarness h = await ScreenHarness.boot(
    tester,
    cameras:
        cameras ??
        <Camera>[
          cameraWithSub(id: 'a', name: 'Porch', host: '10.0.0.5'),
          cameraWithSub(id: 'b', name: 'Garage', sortIndex: 1, host: '10.0.0.6'),
        ],
  );
  await pumpApp(
    tester,
    CamerasScreen(
      onAddCamera: onAdd ?? () {},
      onEditCamera: onEdit ?? (_) {},
    ),
    providers: h.app,
  );
  await settle(tester, milliseconds: 300);
  return h;
}

void main() {
  testWidgets('lists every camera with its address', (
    WidgetTester tester,
  ) async {
    await open(tester);
    expect(find.text('Porch'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);
    expect(find.textContaining('10.0.0.5'), findsOneWidget);
  });

  testWidgets('an empty list invites adding the first camera', (
    WidgetTester tester,
  ) async {
    int added = 0;
    await open(tester, cameras: <Camera>[], onAdd: () => added++);
    expect(find.text('No cameras yet'), findsOneWidget);
    await tester.tap(find.text('Add camera'));
    expect(added, 1);
  });

  testWidgets('search narrows the list and says when nothing matches', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);

    h.app.cameras.query.value = 'gar';
    await settle(tester, milliseconds: 200);
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('Porch'), findsNothing);

    h.app.cameras.query.value = 'zzz';
    await settle(tester, milliseconds: 200);
    expect(find.text('No matching cameras'), findsOneWidget);
  });

  testWidgets('long press offers edit and delete; delete can be undone', (
    WidgetTester tester,
  ) async {
    Camera? edited;
    final ScreenHarness h = await open(tester, onEdit: (Camera c) => edited = c);

    await tester.longPress(find.text('Porch'));
    await settle(tester, milliseconds: 600);
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await settle(tester, milliseconds: 600);
    expect(edited?.id, 'a');

    await tester.longPress(find.text('Porch'));
    await settle(tester, milliseconds: 600);
    await tester.tap(find.text('Delete'));
    await settle(tester, milliseconds: 600);

    expect(h.app.cameras.value.byId('a'), isNull);
    expect(find.text('Deleted Porch'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester, milliseconds: 600);
    expect(h.app.cameras.value.byId('a'), isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, milliseconds: 9000);
  });
}
