import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/screens/camera_edit_screen.dart';

import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  Camera? camera,
  DiscoveryResult? prefill,
  VoidCallback? onTroubleshoot,
  Size size = const Size(400, 2400),
}) async {
  final ScreenHarness h = await ScreenHarness.boot(
    tester,
    cameras: camera == null ? const <Camera>[] : <Camera>[camera],
  );
  if (camera != null) {
    await tester.runAsync(
      () => h.app.repository.updateCamera(
        camera,
        credentials: const CameraCredentials(username: 'admin', password: 'pw'),
      ),
    );
  }
  await pumpApp(
    tester,
    CameraEditScreen(
      camera: camera,
      prefill: prefill,
      onOpenTroubleshooter: onTroubleshoot,
    ),
    providers: h.app,
    size: size,
  );
  await settle(tester, milliseconds: 300);
  return h;
}

EditableText editable(WidgetTester tester, int index) {
  return tester.widgetList<EditableText>(find.byType(EditableText)).elementAt(index);
}

void main() {
  testWidgets('saving with nothing filled in names every problem', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    await tester.tap(find.text('Save'));
    await settle(tester, milliseconds: 300);

    expect(find.text('Give the camera a name.'), findsOneWidget);
    expect(
      find.text('Enter an IP address or host name, without spaces or slashes.'),
      findsOneWidget,
    );
    expect(h.app.cameras.value.cameras, isEmpty);
  });

  testWidgets('a filled form saves a camera with its password in the vault', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    // Fields in order: stream address, name, host, port, username, password,
    // main path, sub path.
    await tester.enterText(find.byType(EditableText).at(1), 'Porch');
    await tester.enterText(find.byType(EditableText).at(2), '192.168.1.20');
    await tester.enterText(find.byType(EditableText).at(4), 'admin');
    await tester.enterText(find.byType(EditableText).at(5), 's3cret');
    await tester.enterText(find.byType(EditableText).at(6), 'stream0');
    await tester.tap(find.text('Save'));
    await settle(tester, milliseconds: 500);

    final List<Camera> saved = h.app.cameras.value.cameras;
    expect(saved.length, 1);
    expect(saved.single.name, 'Porch');
    expect(saved.single.host, '192.168.1.20');
    expect(saved.single.mainPath, '/stream0');
    final creds = (await tester.runAsync(
      () => h.app.repository.credentialsFor(saved.single.id),
    ))!.valueOrNull!;
    expect(creds.username, 'admin');
    expect(creds.password, 's3cret');
  });

  testWidgets('pasting a whole address fills the fields and clears the box', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byType(EditableText).first,
      'rtsp://admin:pw@10.0.0.7:8554/live/ch0',
    );
    await settle(tester, milliseconds: 300);

    expect(editable(tester, 0).controller.text, isEmpty);
    expect(editable(tester, 2).controller.text, '10.0.0.7');
    expect(editable(tester, 3).controller.text, '8554');
    expect(editable(tester, 4).controller.text, 'admin');
    expect(editable(tester, 6).controller.text, '/live/ch0');
  });

  testWidgets('an address that makes no sense says so on submit', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(EditableText).first, 'not an address');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, milliseconds: 300);
    expect(find.text("That address couldn't be read."), findsOneWidget);
  });

  testWidgets('a discovered camera starts the form', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      prefill: const DiscoveryResult(
        host: '10.0.0.9',
        port: 8000,
        source: DiscoverySource.onvif,
        name: 'Garage',
      ),
    );
    expect(editable(tester, 1).controller.text, 'Garage');
    expect(editable(tester, 2).controller.text, '10.0.0.9');
    expect(editable(tester, 3).controller.text, '554');
  });

  testWidgets('editing loads the saved password and keeps the camera id', (
    WidgetTester tester,
  ) async {
    final Camera existing = cameraWithSub(id: 'keep', name: 'Porch');
    final ScreenHarness h = await open(tester, camera: existing);

    expect(find.text('Edit camera'), findsOneWidget);
    // No stream address box when editing: name is the first field.
    expect(editable(tester, 0).controller.text, 'Porch');
    expect(editable(tester, 3).controller.text, 'admin');

    await tester.enterText(find.byType(EditableText).at(0), 'Gate');
    await tester.tap(find.text('Save'));
    await settle(tester, milliseconds: 500);
    final Camera after = h.app.cameras.value.byId('keep')!;
    expect(after.name, 'Gate');
    expect(after.protocol, StreamProtocol.rtsp);
  });

  testWidgets('the connection test runs and explains a failure', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester, camera: cameraWithSub(id: 'x'));
    h.probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));

    await tester.ensureVisible(find.text('Test connection'));
    await tester.tap(find.text('Test connection'));
    await settle(tester, milliseconds: 600);

    expect(find.text("The connection didn't work."), findsOneWidget);
    expect(find.text("Can't reach the camera"), findsWidgets);
    expect(
      find.text('Make sure this phone and the camera are on the same Wi-Fi.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed test offers the troubleshooter when one exists', (
    WidgetTester tester,
  ) async {
    int opened = 0;
    final ScreenHarness h = await open(
      tester,
      camera: cameraWithSub(id: 'x'),
      onTroubleshoot: () => opened++,
    );
    h.probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));
    await tester.ensureVisible(find.text('Test connection'));
    await tester.tap(find.text('Test connection'));
    await settle(tester, milliseconds: 600);

    await tester.ensureVisible(find.text('Open troubleshooter'));
    await tester.tap(find.text('Open troubleshooter'));
    expect(opened, 1);
  });

  testWidgets('the type changes the default port', (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.text('MJPEG'));
    await settle(tester, milliseconds: 300);
    expect(editable(tester, 3).controller.text, '80');
    expect(find.text('Transport'), findsNothing);
  });
}
