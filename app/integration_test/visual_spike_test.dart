// Runs the visual spike on a real Android emulator (workflow `emulator_check`).
// These are the checks that widget tests cannot make: the real engine, the real
// text input and the real clipboard.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roehens/ui/components/app_selection_controls.dart';
import 'package:roehens/spike/visual_spike_main.dart' as spike;

Finder _fieldWithText(String text) {
  return find.byWidgetPredicate(
    (Widget w) => w is EditableText && w.controller.text == text,
  );
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (Widget w) => w is Scrollable && w.axis == Axis.vertical,
  );
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long-press in a text field offers cut, copy, paste and select all, and paste works', (
    WidgetTester tester,
  ) async {
    spike.main();
    await tester.pumpAndSettle();
    await Clipboard.setData(
      const ClipboardData(text: 'rtsp://192.168.1.50:554/stream1'),
    );

    final Finder name = _fieldWithText('Garden gate');
    await tester.scrollUntilVisible(
      name,
      300,
      scrollable: _verticalScrollable().first,
    );
    final EditableText field = tester.widget<EditableText>(name);

    await tester.longPressAt(tester.getTopLeft(name) + const Offset(20, 10));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_selection_with_toolbar');
    expect(find.text('Select all'), findsOneWidget, reason: 'the toolbar must appear');
    expect(
      find.byKey(AppSelectionControls.handleKey),
      findsNWidgets(2),
      reason: 'a selected word has a handle at each end',
    );
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(field.controller.text, contains('rtsp://192.168.1.50:554/stream1'));
    expect(find.text('Paste'), findsNothing, reason: 'the toolbar closes after use');
  });

  testWidgets('copy puts the selected text on the clipboard', (WidgetTester tester) async {
    spike.main();
    await tester.pumpAndSettle();
    await Clipboard.setData(const ClipboardData(text: 'before'));

    final Finder name = _fieldWithText('Garden gate');
    await tester.scrollUntilVisible(
      name,
      300,
      scrollable: _verticalScrollable().first,
    );
    await tester.longPressAt(tester.getTopLeft(name) + const Offset(20, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    expect(data?.text, 'Garden');
  });

  testWidgets('every section builds in dark, light and right-to-left without a layout error', (
    WidgetTester tester,
  ) async {
    spike.main();
    await tester.pumpAndSettle();

    for (final String look in <String>['Dark', 'Light', 'RTL']) {
      await tester.ensureVisible(find.text(look).first);
      await tester.tap(find.text(look).first);
      await tester.pumpAndSettle();
      for (final String section in <String>[
        'Components',
        'Tiles',
        'PTZ',
        'Brands',
        'Overlays',
        'Arabic',
      ]) {
        await tester.ensureVisible(find.text(section).first);
        await tester.tap(find.text(section).first);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$section in $look must lay out without an error',
        );
      }
    }
  });

  testWidgets('the sixteen-tile grid fits its overlays on a real phone screen', (
    WidgetTester tester,
  ) async {
    spike.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiles').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cam 16'),
      300,
      scrollable: _verticalScrollable().first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('screenshots of every section, dark and light, at normal and large text', (
    WidgetTester tester,
  ) async {
    spike.main();
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> open(String chip) async {
      await tester.ensureVisible(find.text(chip).first);
      await tester.tap(find.text(chip).first);
      await tester.pumpAndSettle();
    }

    await shot('10_dark_components');
    await open('Tiles');
    await shot('11_dark_tiles');
    await open('PTZ');
    await shot('12_dark_ptz');
    await open('Overlays');
    await shot('13_dark_overlays');
    await open('Light');
    await open('Components');
    await shot('20_light_components');
    await open('Tiles');
    await shot('21_light_tiles');
    await open('2.0x');
    await open('Components');
    await shot('30_large_text_components');
    await tester.scrollUntilVisible(
      find.text('System'),
      200,
      scrollable: _verticalScrollable().first,
    );
    await shot('31_large_text_segmented');
    await open('Arabic');
    await shot('40_large_text_arabic');
    expect(tester.takeException(), isNull);
  });
}
