import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_switch.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';

import '../../support/pump_app.dart';

void main() {
  group('AppPressable', () {
    testWidgets('taps call onTap and a disabled one does nothing', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            AppPressable(onTap: () => taps++, child: const SizedBox(key: Key('on'), width: 80, height: 80)),
            const AppPressable(child: SizedBox(key: Key('off'), width: 80, height: 80)),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('on')));
      await tester.tap(find.byKey(const Key('off')));
      expect(taps, 1);
    });

    testWidgets('fades while pressed and returns when released', (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppPressable(onTap: () {}, child: const SizedBox(key: Key('t'), width: 80, height: 80)),
      );
      double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

      expect(opacity(), 1);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('t'))));
      await tester.pump();
      expect(opacity(), AppMotion.pressedOpacity);
      await gesture.up();
      await tester.pump();
      expect(opacity(), 1);
    });

    testWidgets('never scales', (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppPressable(onTap: () {}, child: const SizedBox(key: Key('t'), width: 80, height: 80)),
      );
      final Size before = tester.getSize(find.byKey(const Key('t')));
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('t'))));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getSize(find.byKey(const Key('t'))), before);
      await gesture.up();
    });

    testWidgets('Enter and Space activate the focused element', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        AppPressable(onTap: () => taps++, child: const SizedBox(width: 80, height: 80)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
    });

    testWidgets('a small child still gets a 48 by 48 hit area', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        AppPressable(
          onTap: () => taps++,
          minHitSize: const Size.square(AppSizes.touchTarget),
          child: const SizedBox(key: Key('t'), width: 16, height: 16),
        ),
      );
      final Rect box = tester.getRect(find.byKey(const Key('t')));
      await tester.tapAt(box.center + const Offset(20, 20));
      expect(taps, 1);
    });

    testWidgets('a semantic label replaces the child text', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppPressable(
          onTap: () {},
          semanticLabel: 'Open camera',
          child: const Text('x'),
        ),
      );
      expect(find.bySemanticsLabel('Open camera'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppButton', () {
    testWidgets('every kind shows its label and fires', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            for (final AppButtonKind kind in AppButtonKind.values)
              AppButton(label: kind.name, kind: kind, onPressed: () => taps++),
          ],
        ),
      );
      for (final AppButtonKind kind in AppButtonKind.values) {
        await tester.tap(find.text(kind.name));
      }
      expect(taps, AppButtonKind.values.length);
    });

    testWidgets('is at least 48 high and expands on request', (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppButton(label: 'Save', onPressed: () {}, expand: true),
      );
      final Size size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(AppSizes.buttonMinHeight));
      expect(size.width, 400);
    });

    testWidgets('disabled and loading buttons ignore taps', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            const AppButton(label: 'Off', onPressed: null),
            AppButton(label: 'Busy', onPressed: () => taps++, isLoading: true),
          ],
        ),
      );
      await tester.tap(find.text('Off'));
      await tester.tap(find.text('Busy'));
      expect(taps, 0);
    });

    testWidgets('a long label wraps instead of overflowing at large text', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 200,
          child: AppButton(
            label: 'A very long button label that must wrap',
            onPressed: () {},
            expand: true,
          ),
        ),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppIconButton', () {
    testWidgets('draws a 40 chip inside a 48 hit area', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        AppIconButton(
          icon: AppIconName.settings,
          semanticLabel: 'Settings',
          onPressed: () => taps++,
        ),
      );
      expect(tester.getSize(find.byType(AppIconButton)), const Size.square(AppSizes.touchTarget));
      final Rect chip = tester.getRect(find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == AppSizes.iconChip && w.height == AppSizes.iconChip,
      ));
      expect(chip.size, const Size.square(AppSizes.iconChip));
      // The outer 4 pixels are still part of the hit area.
      await tester.tapAt(chip.topLeft - const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('is announced by its label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppIconButton(icon: AppIconName.close, semanticLabel: 'Close', onPressed: () {}),
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppChip', () {
    testWidgets('a chip with onTap is tappable and has a 48 hit area', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, AppChip(label: 'Retry', icon: AppIconName.refresh, onTap: () => taps++));
      expect(tester.getSize(find.byType(AppChip)).height, greaterThanOrEqualTo(AppSizes.touchTarget));
      await tester.tap(find.text('Retry'));
      expect(taps, 1);
    });

    testWidgets('without onTap it is a plain label', (WidgetTester tester) async {
      await pumpApp(tester, const AppChip(label: 'Label'));
      expect(find.byType(AppPressable), findsNothing);
    });

    testWidgets('selected and destructive chips build', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            AppChip(label: 'A', selected: true, onTap: () {}),
            AppChip(label: 'B', destructive: true, onTap: () {}),
          ],
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('AppSwitch', () {
    testWidgets('reports the opposite value when tapped', (WidgetTester tester) async {
      bool? received;
      await pumpApp(
        tester,
        AppSwitch(value: false, onChanged: (bool v) => received = v, semanticLabel: 'Haptics'),
      );
      await tester.tap(find.byType(AppSwitch));
      expect(received, isTrue);
    });

    testWidgets('exposes its state to accessibility', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Haptics'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Haptics')),
        isSemantics(hasToggledState: true, isToggled: true),
      );
      handle.dispose();
    });

    testWidgets('the thumb sits at the end, and mirrors in right-to-left', (WidgetTester tester) async {
      Future<double> thumbCenter(TextDirection direction) async {
        await pumpApp(
          tester,
          AppSwitch(value: true, onChanged: (_) {}, semanticLabel: 's'),
          direction: direction,
        );
        await tester.pumpAndSettle();
        final Finder thumb = find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == AppSizes.switchThumb - AppSizes.hairline * 4,
        );
        return tester.getCenter(thumb).dx;
      }

      final double ltr = await thumbCenter(TextDirection.ltr);
      final double rtl = await thumbCenter(TextDirection.rtl);
      expect(ltr, greaterThan(200));
      expect(rtl, lessThan(200));
    });

    testWidgets('disabled does nothing', (WidgetTester tester) async {
      await pumpApp(tester, const AppSwitch(value: false, onChanged: null, semanticLabel: 's'));
      await tester.tap(find.byType(AppSwitch));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('selecting a segment reports its value', (WidgetTester tester) async {
      String? chosen;
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppSegmentedControl<String>(
            selected: 'a',
            onChanged: (String v) => chosen = v,
            segments: const <AppSegment<String>>[
              AppSegment<String>(value: 'a', label: 'System'),
              AppSegment<String>(value: 'b', label: 'Light'),
              AppSegment<String>(value: 'c', label: 'Dark'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Dark'));
      expect(chosen, 'c');
    });

    testWidgets('segments are equally wide and tall enough to tap', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppSegmentedControl<int>(
            selected: 1,
            onChanged: (_) {},
            segments: const <AppSegment<int>>[
              AppSegment<int>(value: 1, label: 'One'),
              AppSegment<int>(value: 2, label: 'Two'),
            ],
          ),
        ),
      );
      final Size one = tester.getSize(find.byType(AppPressable).first);
      final Size two = tester.getSize(find.byType(AppPressable).last);
      expect(one.width, two.width);
      expect(one.height, greaterThanOrEqualTo(AppSizes.segmentedHeight));
    });
  });
}
