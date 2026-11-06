// Runs the visual spike on a real Android emulator (workflow `emulator_check`).
// These are the checks that widget tests cannot make: the real engine, the real
// text input and the real clipboard.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long-press in a text field offers cut, copy, paste and select all, and paste works', (
    WidgetTester tester,
  ) async {
    spike.main();
    await tester.pumpAndSettle();
    await Clipboard.setData(
      const ClipboardData(text: 'rtsp://192.168.1.50:554/stream1'),
    );

    final Finder name = _fieldWithText('Garden');
    await tester.scrollUntilVisible(
      name,
      300,
      scrollable: _verticalScrollable().first,
    );
    final EditableText field = tester.widget<EditableText>(name);

    await tester.longPressAt(tester.getTopLeft(name) + const Offset(20, 10));
    await tester.pumpAndSettle();
    expect(find.text('Select all'), findsOneWidget, reason: 'the toolbar must appear');
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

    final Finder name = _fieldWithText('Garden');
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
}
