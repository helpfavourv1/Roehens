import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_text_selection_toolbar.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/widgets/camera_tile.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

import '../../support/pump_app.dart';

/// Checks written after the first look at the design on a real phone.
void main() {
  group('copy and paste in text fields', () {
    late String? clipboard;

    setUp(() {
      clipboard = 'pasted text';
    });

    void mockClipboard(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          switch (call.method) {
            case 'Clipboard.getData':
              return <String, Object?>{'text': clipboard};
            case 'Clipboard.hasStrings':
              return <String, Object?>{
                'value': clipboard != null && clipboard!.isNotEmpty,
              };
            case 'Clipboard.setData':
              clipboard =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
              return null;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    Future<TextEditingController> pumpField(WidgetTester tester) async {
      mockClipboard(tester);
      final TextEditingController controller = TextEditingController(
        text: 'Garden',
      );
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.only(top: 200),
            child: AppTextField(controller: controller, label: 'Name'),
          ),
        ),
      );
      return controller;
    }

    testWidgets('a long press shows cut, copy, paste and select all', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();

      expect(find.byType(AppTextSelectionToolbar), findsOneWidget);
      for (final String word in <String>[
        'Cut',
        'Copy',
        'Paste',
        'Select all',
      ]) {
        expect(find.text(word), findsOneWidget);
      }
    });

    testWidgets('paste puts the clipboard text into the field', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();
      await tester.tap(find.text('Paste'));
      await tester.pump();

      expect(controller.text, contains('pasted text'));
    });

    testWidgets('copy puts the selected word on the clipboard', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();
      await tester.tap(find.text('Copy'));
      await tester.pump();

      expect(clipboard, 'Garden');
    });

    testWidgets('select all selects the whole text', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();
      await tester.tap(find.text('Select all'));
      await tester.pump();

      expect(controller.selection.start, 0);
      expect(controller.selection.end, controller.text.length);
    });

    testWidgets('the toolbar stays inside the screen', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();

      final Rect bar = tester.getRect(find.byType(AppTextSelectionToolbar));
      expect(bar.left, greaterThanOrEqualTo(0));
      expect(bar.right, lessThanOrEqualTo(400));
      expect(
        tester.getRect(find.text('Paste')).left,
        greaterThanOrEqualTo(AppSpacing.sm),
      );
    });

    testWidgets('each button has a 48 high touch area', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      await tester.longPress(find.byType(EditableText));
      await tester.pump();

      expect(
        tester.getSize(find.byType(AppTextSelectionToolbar)).height,
        greaterThanOrEqualTo(AppSizes.touchTarget),
      );
    });
  });

  group('system bars', () {
    Future<SystemUiOverlayStyle> styleFor(
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          height: 800,
          child: AppScaffold(body: SizedBox.expand()),
        ),
        brightness: brightness,
      );
      return tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .value;
    }

    testWidgets('a dark screen gets light bar icons, a light screen dark ones', (
      WidgetTester tester,
    ) async {
      final SystemUiOverlayStyle dark = await styleFor(tester, Brightness.dark);
      expect(dark.statusBarIconBrightness, Brightness.light);
      expect(dark.systemNavigationBarIconBrightness, Brightness.light);

      final SystemUiOverlayStyle light = await styleFor(
        tester,
        Brightness.light,
      );
      expect(light.statusBarIconBrightness, Brightness.dark);
      expect(light.systemNavigationBarIconBrightness, Brightness.dark);
    });

    testWidgets('the bars are transparent so the app shows through', (
      WidgetTester tester,
    ) async {
      final SystemUiOverlayStyle style = await styleFor(
        tester,
        Brightness.dark,
      );
      expect(style.statusBarColor!.a, 0);
      expect(style.systemNavigationBarColor!.a, 0);
    });
  });

  group('status pill colors', () {
    testWidgets('use the bright colors in the light theme too', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const StreamStatusPill(status: StreamStatus.live, label: 'Live'),
        brightness: Brightness.light,
      );
      final AppIcon icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(icon.color, AppColors.dark.streamLive);
      expect(icon.color, isNot(AppColors.light.streamLive));
    });

    testWidgets('a pill without a plate is just the icon', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const StreamStatusPill(
          status: StreamStatus.error,
          label: 'Error',
          iconOnly: true,
          plate: false,
        ),
      );
      expect(
        tester.getSize(find.byType(StreamStatusPill)).width,
        AppSizes.iconChipGlyph,
      );
    });
  });

  group('the smallest tile', () {
    testWidgets('fits its overlay at the real 16-up size on a phone', (
      WidgetTester tester,
    ) async {
      // 360 wide, 16 either side, three 4 gaps, four columns: about 79 x 44.
      const double width = (360 - 32 - 12) / 4;
      await pumpApp(
        tester,
        SizedBox(
          width: width,
          height: width / AppSizes.tileAspectRatio,
          child: const CameraTile(
            name: 'Cam 12',
            status: StreamStatus.live,
            statusLabel: 'Live',
            resolutionLabel: '1920x1080',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Cam 12'), findsOneWidget);
      expect(find.text('1920x1080'), findsNothing);
    });

    testWidgets('keeps the name legible for a long camera name', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 79,
          height: 44,
          child: CameraTile(
            name: 'A camera with a very long name',
            status: StreamStatus.error,
            statusLabel: 'Error',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('nav bar', () {
    testWidgets('leaves a gap between the brand and the title', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          child: AppNavBar(leading: Text('Roehens'), title: 'Design check'),
        ),
      );
      final double gap =
          tester.getRect(find.text('Design check')).left -
          tester.getRect(find.text('Roehens')).right;
      expect(gap, greaterThanOrEqualTo(AppSpacing.md));
    });
  });
}
