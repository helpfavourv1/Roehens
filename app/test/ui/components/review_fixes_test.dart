import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/core/providers/persistence_health_provider.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_bottom_bar.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_selection_controls.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_text_selection_toolbar.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/widgets/banner_ad_slot.dart';
import 'package:roehens/widgets/camera_tile.dart';
import 'package:roehens/widgets/persistence_warning_banner.dart';
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
        text: 'Garden gate',
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
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
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
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
      await tester.pump();
      await tester.tap(find.text('Paste'));
      await tester.pump();

      expect(controller.text, contains('pasted text'));
    });

    testWidgets('copy puts the selected word on the clipboard', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
      await tester.pump();
      await tester.tap(find.text('Copy'));
      await tester.pump();

      expect(clipboard, 'Garden');
    });

    testWidgets('select all selects the whole text', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = await pumpField(tester);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
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
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
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
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
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

    testWidgets(
      'a dark screen gets light bar icons, a light screen dark ones',
      (WidgetTester tester) async {
        final SystemUiOverlayStyle dark = await styleFor(
          tester,
          Brightness.dark,
        );
        expect(dark.statusBarIconBrightness, Brightness.light);
        expect(dark.systemNavigationBarIconBrightness, Brightness.light);

        final SystemUiOverlayStyle light = await styleFor(
          tester,
          Brightness.light,
        );
        expect(light.statusBarIconBrightness, Brightness.dark);
        expect(light.systemNavigationBarIconBrightness, Brightness.dark);
      },
    );

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

  group('with animations switched off', () {
    void switchAnimationsOff(WidgetTester tester) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    testWidgets('the bottom stack changes size without an error', (
      WidgetTester tester,
    ) async {
      switchAnimationsOff(tester);
      final ValueNotifier<bool> showEmbed = ValueNotifier<bool>(false);
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: ValueListenableBuilder<bool>(
            valueListenable: showEmbed,
            builder: (BuildContext context, bool show, Widget? _) {
              return AppScaffold(
                body: const SizedBox.expand(),
                bottomEmbed: show ? const SizedBox(height: 60) : null,
                bottomBar: const SizedBox(height: 64),
              );
            },
          ),
        ),
      );
      showEmbed.value = true;
      await tester.pump();
      expect(tester.takeException(), isNull);
      showEmbed.value = false;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ad slot appears and collapses without an error', (
      WidgetTester tester,
    ) async {
      switchAnimationsOff(tester);
      final ValueNotifier<AdSlotState> state = ValueNotifier<AdSlotState>(
        AdSlotState.collapsed,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: BannerAdSlot(
            state: state,
            viewBuilder: (Object view) => const SizedBox(),
          ),
        ),
      );
      state.value = AdSlotState(height: 60, view: Object());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 76);
      state.value = AdSlotState.collapsed;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 0);
    });

    testWidgets('the storage warning appears and goes without an error', (
      WidgetTester tester,
    ) async {
      switchAnimationsOff(tester);
      final ValueNotifier<PersistenceIssue> issue =
          ValueNotifier<PersistenceIssue>(PersistenceIssue.none);
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: PersistenceWarningBanner(
            issue: issue,
            degradedMessage: 'Cameras may not be saved.',
            updateMessage: 'Update the app.',
          ),
        ),
      );
      issue.value = PersistenceIssue.degraded;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Cameras may not be saved.'), findsOneWidget);
      issue.value = PersistenceIssue.none;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('large text', () {
    Widget segments() {
      return SizedBox(
        width: 328,
        child: AppSegmentedControl<String>(
          selected: 'a',
          onChanged: (_) {},
          segments: const <AppSegment<String>>[
            AppSegment<String>(value: 'a', label: 'System'),
            AppSegment<String>(value: 'b', label: 'Light'),
            AppSegment<String>(value: 'c', label: 'Dark'),
          ],
        ),
      );
    }

    testWidgets('three segments stay in a row at normal text', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, segments());
      expect(
        tester.getTopLeft(find.text('System')).dy,
        tester.getTopLeft(find.text('Dark')).dy,
      );
    });

    testWidgets('three segments stack, one per line, at large text', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        segments(),
        textScale: 2,
        size: const Size(400, 1600),
      );
      final double system = tester.getTopLeft(find.text('System')).dy;
      final double light = tester.getTopLeft(find.text('Light')).dy;
      final double dark = tester.getTopLeft(find.text('Dark')).dy;
      expect(system, lessThan(light));
      expect(light, lessThan(dark));
      expect(tester.takeException(), isNull);
    });

    testWidgets('two segments stay in a row at large text', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 328,
          child: AppSegmentedControl<int>(
            selected: 1,
            onChanged: (_) {},
            segments: const <AppSegment<int>>[
              AppSegment<int>(value: 1, label: 'On'),
              AppSegment<int>(value: 2, label: 'Off'),
            ],
          ),
        ),
        textScale: 2,
      );
      expect(
        tester.getTopLeft(find.text('On')).dy,
        tester.getTopLeft(find.text('Off')).dy,
      );
    });

    testWidgets('the nav bar text stops growing at 130 percent', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          child: AppNavBar(leading: Text('Roehens'), title: 'Design check'),
        ),
        textScale: 2,
      );
      for (final String text in <String>['Roehens', 'Design check']) {
        expect(
          MediaQuery.textScalerOf(tester.element(find.text(text))).scale(10),
          closeTo(13, 0.01),
        );
      }
    });

    testWidgets('a count badge on a bottom bar icon does not grow', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: AppBottomBar(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const <AppBottomBarItem>[
              AppBottomBarItem(
                icon: AppIconName.cameraDome,
                label: 'Cameras',
                badge: '3',
              ),
            ],
          ),
        ),
        textScale: 3,
      );
      expect(
        tester.widget<Text>(find.text('3')).textScaler,
        TextScaler.noScaling,
      );
    });

    testWidgets('a banner icon sits on the first line of its text', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 360,
          child: AppBanner(
            message: 'Storage is not working. Cameras may not be saved.',
          ),
        ),
        textScale: 2,
        size: const Size(400, 2000),
      );
      final double firstLineCenter =
          tester.getTopLeft(find.byType(Text)).dy +
          MediaQuery.textScalerOf(tester.element(find.byType(Text)))
                  .scale(15 * 1.45) /
              2;
      expect(
        tester.getCenter(find.byType(AppIcon)).dy,
        closeTo(firstLineCenter, 1.5),
      );
    });
  });

  group('selection handles', () {
    testWidgets('a selected word has a handle at each end', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.only(top: 200),
            child: AppTextField(
              controller: TextEditingController(text: 'Garden gate'),
              label: 'Name',
            ),
          ),
        ),
      );
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
      await tester.pump();
      expect(find.byKey(AppSelectionControls.handleKey), findsNWidgets(2));
    });
  });

  group('DEBUG handle geometry (temporary)', () {
    testWidgets('report where the handles are', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.only(top: 200),
            child: AppTextField(
              controller: TextEditingController(text: 'Garden gate'),
              label: 'Name',
            ),
          ),
        ),
      );
      final Rect field = tester.getRect(find.byType(EditableText));
      await tester.longPressAt(field.topLeft + const Offset(20, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final List<String> handles = <String>[];
      for (final Element e in find.byKey(AppSelectionControls.handleKey).evaluate()) {
        final Finder here = find.byElementPredicate((Element x) => x == e);
        final Iterable<FadeTransition> fades = tester.widgetList<FadeTransition>(
          find.ancestor(of: here, matching: find.byType(FadeTransition)),
        );
        handles.add(
          '${tester.getRect(here)} opacity=${fades.map((FadeTransition f) => f.opacity.value).toList()}',
        );
      }
      final Rect toolbar = tester.getRect(find.byType(AppTextSelectionToolbar));
      fail('field=$field handles=$handles toolbar=$toolbar screen=400x800');
    });
  });

  group('fullscreen system bars', () {
    testWidgets('a light theme still gets light icons over fullscreen video', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          height: 800,
          child: AppScaffold(immersive: true, body: SizedBox.expand()),
        ),
        brightness: Brightness.light,
      );
      final SystemUiOverlayStyle style = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .value;
      expect(style.statusBarIconBrightness, Brightness.light);
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
