import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/widgets/fullscreen_controls.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

import '../support/pump_app.dart';

void main() {
  late int closes;
  late int activity;
  late List<String> pressed;

  Future<void> pump(WidgetTester tester, {Widget? panel}) async {
    closes = 0;
    activity = 0;
    pressed = <String>[];
    await pumpApp(
      tester,
      SizedBox(
        width: 400,
        height: 800,
        child: FullscreenControls(
          title: 'Front door',
          closeLabel: 'Close',
          onClose: () => closes++,
          onActivity: () => activity++,
          statusPill: const StreamStatusPill(status: StreamStatus.live, label: 'Live'),
          topActions: <FullscreenAction>[
            FullscreenAction(icon: AppIconName.volumeOff, label: 'Mute', onPressed: () => pressed.add('mute')),
          ],
          bottomActions: <FullscreenAction>[
            FullscreenAction(icon: AppIconName.snapshot, label: 'Snapshot', onPressed: () => pressed.add('snap')),
            FullscreenAction(icon: AppIconName.cameraPtz, label: 'PTZ', selected: true, onPressed: () => pressed.add('ptz')),
          ],
          panel: panel,
          child: const ColoredBox(key: Key('video'), color: Color(0xFF000000), child: SizedBox.expand()),
        ),
      ),
    );
  }

  double controlsOpacity(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(find.descendant(of: find.byType(FullscreenControls), matching: find.byType(AnimatedOpacity)).first)
        .opacity;
  }

  testWidgets('shows the title, status and action buttons', (WidgetTester tester) async {
    await pump(tester);
    expect(find.text('Front door'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Snapshot'));
    await tester.tap(find.bySemanticsLabel('Mute'));
    expect(pressed, <String>['snap', 'mute']);
  }, semanticsEnabled: true);

  testWidgets('the close button and Escape both close', (WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closes, 2);
  }, semanticsEnabled: true);

  testWidgets('fades out after three seconds without a touch', (WidgetTester tester) async {
    await pump(tester);
    expect(controlsOpacity(tester), 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));
    expect(controlsOpacity(tester), 0);
  });

  testWidgets('hidden controls do not take touches, a tap on the picture brings them back', (WidgetTester tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byKey(const Key('video')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(controlsOpacity(tester), 1);

    await tester.tap(find.byKey(const Key('video')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(controlsOpacity(tester), 0);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('any touch restarts the wait and reports activity', (WidgetTester tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 2));
    // Finger down on the picture, not released, so it is not a tap.
    final TestGesture gesture = await tester.startGesture(const Offset(200, 400));
    expect(activity, greaterThan(0));
    await tester.pump(const Duration(seconds: 2));
    expect(controlsOpacity(tester), 1);
    await gesture.cancel();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('with a screen reader on, the controls stay', (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(controlsOpacity(tester), 1);
  });

  testWidgets('shows a panel above the bottom row', (WidgetTester tester) async {
    await pump(tester, panel: const SizedBox(key: Key('panel'), width: 100, height: 100));
    expect(find.byKey(const Key('panel')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a long camera name does not overflow at large text', (WidgetTester tester) async {
    closes = 0;
    await pumpApp(
      tester,
      SizedBox(
        width: 400,
        height: 800,
        child: FullscreenControls(
          title: 'A very long camera name that goes on and on',
          closeLabel: 'Close',
          onClose: () {},
          child: const SizedBox.expand(),
        ),
      ),
      textScale: 3,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });
}
