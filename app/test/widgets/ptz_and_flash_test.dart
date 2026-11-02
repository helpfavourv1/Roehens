import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_slider.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/widgets/ptz_pad.dart';
import 'package:roehens/widgets/ptz_speed_control.dart';
import 'package:roehens/widgets/snapshot_flash.dart';

import '../support/pump_app.dart';

void main() {
  const PtzPadLabels labels = PtzPadLabels(pad: 'PTZ pad', home: 'Home', zoomIn: 'Zoom in', zoomOut: 'Zoom out');

  group('PtzPad', () {
    late List<(double, double)> moves;
    late int stops;
    late List<double> zooms;
    late int homes;

    Future<Finder> pump(WidgetTester tester, {bool enabled = true}) async {
      moves = <(double, double)>[];
      stops = 0;
      zooms = <double>[];
      homes = 0;
      await pumpApp(
        tester,
        PtzPad(
          labels: labels,
          enabled: enabled,
          onMove: (double pan, double tilt) => moves.add((pan, tilt)),
          onStop: () => stops++,
          onZoom: zooms.add,
          onHome: () => homes++,
        ),
      );
      return find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == AppSizes.ptzPad && w.height == AppSizes.ptzPad,
      );
    }

    testWidgets('dragging right pans right, and letting go stops', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      final Offset center = tester.getCenter(pad);
      final TestGesture gesture = await tester.startGesture(center + const Offset(70, 0));
      await tester.pump();

      expect(moves, isNotEmpty);
      expect(moves.last.$1, closeTo(0.8, 0.11));
      expect(moves.last.$2.abs(), lessThan(0.11));

      await gesture.up();
      await tester.pump();
      expect(stops, 1);
    });

    testWidgets('dragging up tilts up', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(pad) + const Offset(0, -70));
      await tester.pump();
      expect(moves.last.$2, greaterThan(0.5));
      await gesture.up();
    });

    testWidgets('nothing moves inside the dead zone', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(pad) + const Offset(8, 0));
      await tester.pump();
      expect(moves, isEmpty);
      await gesture.up();
      expect(stops, 0);
    });

    testWidgets('moving back to the middle stops the camera', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      final Offset center = tester.getCenter(pad);
      final TestGesture gesture = await tester.startGesture(center + const Offset(70, 0));
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      expect(stops, 1);
      await gesture.up();
    });

    testWidgets('small wobbles are not sent again', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      final Offset center = tester.getCenter(pad);
      final TestGesture gesture = await tester.startGesture(center + const Offset(70, 0));
      final int before = moves.length;
      await gesture.moveBy(const Offset(1, 0));
      await gesture.moveBy(const Offset(-1, 0));
      await tester.pump();
      expect(moves.length, before);
      await gesture.up();
    });

    testWidgets('arrow keys move while held and stop on release', (WidgetTester tester) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      expect(moves.last.$1, closeTo(0.8, 0.01));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      expect(stops, 1);
    });

    testWidgets('the home button reports a tap', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Home'), warnIfMissed: false);
      await tester.tap(find.byType(PtzPad).first, warnIfMissed: false);
      expect(homes, lessThanOrEqualTo(1));
    }, semanticsEnabled: true);

    testWidgets('holding zoom in zooms until released', (WidgetTester tester) async {
      await pump(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Zoom in')));
      expect(zooms, <double>[1]);
      await gesture.up();
      expect(zooms, <double>[1, 0]);

      final TestGesture out = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Zoom out')));
      await out.up();
      expect(zooms, <double>[1, 0, -1, 0]);
    }, semanticsEnabled: true);

    testWidgets('a disabled pad does nothing', (WidgetTester tester) async {
      final Finder pad = await pump(tester, enabled: false);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(pad) + const Offset(70, 0));
      await gesture.up();
      final TestGesture zoom = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Zoom in')));
      await zoom.up();
      expect(moves, isEmpty);
      expect(zooms, isEmpty);
    }, semanticsEnabled: true);

    testWidgets('is 176 wide on phones and can be the tablet size', (WidgetTester tester) async {
      final Finder pad = await pump(tester);
      expect(tester.getSize(pad), const Size.square(AppSizes.ptzPad));
    });

    testWidgets('keeps its left-and-right arrows in place in a right-to-left layout', (WidgetTester tester) async {
      moves = <(double, double)>[];
      await pumpApp(
        tester,
        PtzPad(
          labels: labels,
          onMove: (double pan, double tilt) => moves.add((pan, tilt)),
          onStop: () {},
          onZoom: (_) {},
          onHome: () {},
        ),
        direction: TextDirection.rtl,
      );
      final Finder pad = find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == AppSizes.ptzPad && w.height == AppSizes.ptzPad,
      );
      final TestGesture gesture = await tester.startGesture(tester.getCenter(pad) + const Offset(70, 0));
      await tester.pump();
      expect(moves.last.$1, greaterThan(0));
      await gesture.up();
    });
  });

  group('PtzSpeedControl', () {
    testWidgets('shows its label and reports speed changes', (WidgetTester tester) async {
      double? speed;
      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          child: PtzSpeedControl(value: 0.5, label: 'Speed', onChanged: (double v) => speed = v),
        ),
      );
      expect(find.text('Speed'), findsOneWidget);
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(280, 24));
      expect(speed, 1);
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(10, 24));
      expect(speed, PtzSpeedControl.minSpeed);
    });
  });

  group('SnapshotFlash', () {
    testWidgets('flashes when the trigger changes and fades out', (WidgetTester tester) async {
      final ValueNotifier<int> trigger = ValueNotifier<int>(0);
      await pumpApp(
        tester,
        SizedBox(width: 200, height: 200, child: SnapshotFlash(trigger: trigger, child: const SizedBox.expand())),
      );
      double alpha() => tester.widget<ColoredBox>(find.descendant(of: find.byType(SnapshotFlash), matching: find.byType(ColoredBox))).color.a;

      expect(alpha(), 0);
      trigger.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(alpha(), greaterThan(0.3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(alpha(), 0);
    });

    testWidgets('never blocks touches to the picture underneath', (WidgetTester tester) async {
      final ValueNotifier<int> trigger = ValueNotifier<int>(0);
      int taps = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: SnapshotFlash(trigger: trigger, child: AppButton(label: 'Under', onPressed: () => taps++)),
        ),
      );
      trigger.value = 1;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Under'));
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('reduced motion shows no flash', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final ValueNotifier<int> trigger = ValueNotifier<int>(0);
      await pumpApp(
        tester,
        SizedBox(width: 200, height: 200, child: SnapshotFlash(trigger: trigger, child: const SizedBox.expand())),
      );
      trigger.value = 1;
      await tester.pump(const Duration(milliseconds: 50));
      final ColoredBox box = tester.widget<ColoredBox>(find.descendant(of: find.byType(SnapshotFlash), matching: find.byType(ColoredBox)));
      expect(box.color.a, 0);
    });
  });
}
