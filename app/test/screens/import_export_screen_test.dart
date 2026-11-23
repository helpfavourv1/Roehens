import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/file_transfer_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/screens/import_export_screen.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

Uint8List listOf(List<Camera> cameras, ScreenHarness h) {
  return h.app.exporter.build(cameras).bytes;
}

void main() {
  testWidgets('export shares the list without passwords', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[cameraWithSub(id: 'a', name: 'Porch')],
    );
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    expect(find.text('1 camera, without its password'), findsOneWidget);
    await tester.tap(find.text('Export camera list'));
    await settle(tester, milliseconds: 300);

    expect(h.files.shared.length, 1);
    final String text = utf8.decode(h.files.shared.single.bytes);
    expect(text, contains('Porch'));
    expect(text, isNot(contains('password')));
    expect(h.files.shared.single.mimeType, 'application/json');
  });

  testWidgets('with no cameras there is nothing to export', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    expect(find.text('No cameras to export'), findsOneWidget);
    await tester.tap(find.text('Export camera list'));
    await settle(tester, milliseconds: 300);
    expect(h.files.shared, isEmpty);
  });

  testWidgets('import previews the file, then adds the new cameras', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    h.files.toPick = PickedFile(
      name: 'cameras.json',
      bytes: listOf(<Camera>[
        cameraWithSub(id: 'p', name: 'Porch', host: '10.0.0.5'),
        cameraWithSub(id: 'g', name: 'Garage', host: '10.0.0.6'),
      ], h),
    );
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    await tester.tap(find.text('Import from a file'));
    await settle(tester, milliseconds: 300);
    expect(find.text('2 CAMERAS IN THE FILE'), findsOneWidget);
    expect(find.text('New'), findsNWidgets(2));
    // Nothing exists yet, so there is no conflict to decide.
    expect(find.text('WHEN A CAMERA ALREADY EXISTS'), findsNothing);

    await tester.tap(find.text('Import'));
    await settle(tester, milliseconds: 500);

    expect(h.app.cameras.value.cameras.length, 2);
    expect(
      find.text('Added 2, replaced 0, skipped 0, failed 0.'),
      findsOneWidget,
    );
  });

  testWidgets('a camera that already exists asks what to do', (
    WidgetTester tester,
  ) async {
    final Camera saved = cameraWithSub(
      id: 'a',
      name: 'Porch',
      host: '10.0.0.5',
    );
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[saved],
    );
    h.files.toPick = PickedFile(
      name: 'cameras.json',
      bytes: listOf(<Camera>[saved], h),
    );
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    await tester.tap(find.text('Import from a file'));
    await settle(tester, milliseconds: 300);
    expect(find.text('Already saved'), findsOneWidget);
    expect(find.text('WHEN A CAMERA ALREADY EXISTS'), findsOneWidget);

    // The default is to skip: importing changes nothing.
    await tester.tap(find.text('Import'));
    await settle(tester, milliseconds: 500);
    expect(h.app.cameras.value.cameras.length, 1);
    expect(
      find.text('Added 0, replaced 0, skipped 1, failed 0.'),
      findsOneWidget,
    );
  });

  testWidgets('keeping both adds a second camera', (WidgetTester tester) async {
    final Camera saved = cameraWithSub(
      id: 'a',
      name: 'Porch',
      host: '10.0.0.5',
    );
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[saved],
    );
    h.files.toPick = PickedFile(
      name: 'cameras.json',
      bytes: listOf(<Camera>[saved], h),
    );
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    await tester.tap(find.text('Import from a file'));
    await settle(tester, milliseconds: 300);
    await tester.tap(find.text('Keep both'));
    await settle(tester, milliseconds: 200);
    await tester.tap(find.text('Import'));
    await settle(tester, milliseconds: 500);

    expect(h.app.cameras.value.cameras.length, 2);
  });

  testWidgets('a file that is not a camera list shows an error', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(tester);
    h.files.toPick = PickedFile(
      name: 'x.json',
      bytes: Uint8List.fromList(utf8.encode('{"hello": 1}')),
    );
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    await tester.tap(find.text('Import from a file'));
    await settle(tester, milliseconds: 300);
    expect(find.text("That file isn't a Roehens camera list"), findsOneWidget);
    expect(find.text('Import'), findsNothing);
  });

  testWidgets('a share failure is shown, not swallowed', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await ScreenHarness.boot(
      tester,
      cameras: <Camera>[cameraWithSub(id: 'a', name: 'Porch')],
    );
    h.files.failure = const AppError(ErrorClass.transferFailed);
    await pumpApp(tester, const ImportExportScreen(), providers: h.app);
    await settle(tester, milliseconds: 300);

    await tester.tap(find.text('Export camera list'));
    await settle(tester, milliseconds: 300);
    expect(find.text("The file couldn't be shared or opened"), findsOneWidget);
  });
}
