import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/screens/fullscreen_screen.dart';

import '../support/fake_player.dart';
import '../support/live_fakes.dart';
import '../support/pump_app.dart';
import '../support/screen_harness.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  bool onvif = false,
  bool ptzSupported = true,
}) async {
  final ScreenHarness h = await ScreenHarness.boot(
    tester,
    ptzSupported: ptzSupported,
    cameras: <Camera>[
      cameraWithSub(id: 'a', name: 'Porch', onvif: onvif),
      cameraWithSub(id: 'b', name: 'Garage', sortIndex: 1),
    ],
  );
  await pumpApp(
    tester,
    const FullscreenScreen(cameraId: 'a', fromLive: false),
    providers: h.app,
  );
  await settle(tester, milliseconds: 600);
  return h;
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester, milliseconds: 4000);
}

void main() {
  testWidgets('opens the camera on the substream, then the main stream', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    expect(h.app.live.focusedId, 'a');
    expect(find.text('Porch'), findsOneWidget);
    expect(h.sessions.first.opened.first.uri.path, '/sub');

    await settle(tester, milliseconds: 800);
    expect(h.app.live.focusIsMainStream, isTrue);
    expect(h.sessions.last.opened.last.uri.path, '/main');
    await close(tester);
    expect(h.app.live.focusedId, isNull);
  });

  testWidgets('mute and unmute reach the player', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester);
    final FakePlayerSession session = h.sessions.first;

    await tester.tap(find.bySemanticsLabel('Mute'));
    await settle(tester, milliseconds: 200);
    expect(session.lastMuted, isTrue);
    await tester.tap(find.bySemanticsLabel('Unmute'));
    await settle(tester, milliseconds: 200);
    expect(session.lastMuted, isFalse);

    semantics.dispose();
    await close(tester);
  });

  testWidgets('next and previous camera move focus', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester);

    await tester.tap(find.bySemanticsLabel('Next camera'));
    await settle(tester, milliseconds: 600);
    expect(h.app.live.focusedId, 'b');
    expect(find.text('Garage'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Previous camera'));
    await settle(tester, milliseconds: 600);
    expect(h.app.live.focusedId, 'a');

    semantics.dispose();
    await close(tester);
  });

  testWidgets('low quality keeps the substream', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester);

    await tester.tap(find.bySemanticsLabel('Use low quality'));
    await settle(tester, milliseconds: 1200);
    expect(h.app.live.focusIsMainStream, isFalse);
    expect(find.bySemanticsLabel('Use high quality'), findsOneWidget);

    semantics.dispose();
    await close(tester);
  });

  testWidgets('pan and tilt needs ONVIF and says so', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await open(tester);

    await tester.tap(find.bySemanticsLabel('Pan and tilt'));
    await settle(tester, milliseconds: 600);
    expect(
      find.text('Turn on ONVIF for this camera to use pan and tilt.'),
      findsOneWidget,
    );

    semantics.dispose();
    await close(tester);
  });

  testWidgets('with ONVIF the pad appears and a home tap is sent', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(tester, onvif: true);

    await tester.tap(find.bySemanticsLabel('Pan and tilt'));
    await settle(tester, milliseconds: 600);
    expect(find.bySemanticsLabel('Pan and tilt pad'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Home position'));
    await settle(tester, milliseconds: 300);
    expect(h.ptz.commands.last.kind, PtzCommandKind.home);

    semantics.dispose();
    await close(tester);
  });

  testWidgets('a camera without pan and tilt says so', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ScreenHarness h = await open(
      tester,
      onvif: true,
      ptzSupported: false,
    );

    await tester.tap(find.bySemanticsLabel('Pan and tilt'));
    await settle(tester, milliseconds: 600);
    expect(find.bySemanticsLabel('Pan and tilt pad'), findsNothing);
    expect(
      find.text("This camera doesn't report pan and tilt control."),
      findsOneWidget,
    );
    expect(h.ptz.commands, isEmpty);

    semantics.dispose();
    await close(tester);
  });

  testWidgets('an error shows its message over the picture', (
    WidgetTester tester,
  ) async {
    final ScreenHarness h = await open(tester);
    h.sessions.first.emit(const PlayerError(AppError(ErrorClass.authFailed)));
    await settle(tester, milliseconds: 300);

    expect(find.text('Check the username or password'), findsOneWidget);
    await close(tester);
  });
}
