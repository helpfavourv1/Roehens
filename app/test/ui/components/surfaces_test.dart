
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_bottom_bar.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_dialog.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_error_state.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_letter_header.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_sheet.dart';
import 'package:roehens/ui/components/app_slider.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';

import '../../support/pump_app.dart';

void main() {
  group('AppNavBar', () {
    testWidgets('is 56 high with a title, a back button and actions', (WidgetTester tester) async {
      int backs = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: AppNavBar(
            title: 'Settings',
            onBack: () => backs++,
            backLabel: 'Back',
            actions: <Widget>[
              AppIconButton(icon: AppIconName.more, semanticLabel: 'More', onPressed: () {}),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppNavBar)).height, AppSizes.navBarHeight + AppSizes.hairline);
      expect(find.text('Settings'), findsOneWidget);
      await tester.tap(find.byType(AppIconButton).first);
      expect(backs, 1);
      expect(find.byType(AppIconButton), findsNWidgets(2));
    });

    testWidgets('a long title is cut with an ellipsis, not wrapped', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 200, child: AppNavBar(title: 'A very long screen title that cannot fit')),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
    });

    test('a back button without a label is a programming error', () {
      expect(() => AppNavBar(onBack: () {}), throwsAssertionError);
    });

    testWidgets('a custom leading widget replaces the back button', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 400, child: AppNavBar(leading: Text('Roehens'), title: 'x')),
      );
      expect(find.text('Roehens'), findsOneWidget);
      expect(find.byType(AppIconButton), findsNothing);
    });
  });

  group('AppBottomBar', () {
    final List<AppBottomBarItem> items = <AppBottomBarItem>[
      const AppBottomBarItem(icon: AppIconName.cameraDome, label: 'Live'),
      const AppBottomBarItem(icon: AppIconName.cameraDome, label: 'Cameras', badge: '3'),
      const AppBottomBarItem(icon: AppIconName.settings, label: 'Settings'),
    ];

    testWidgets('reports the tapped destination', (WidgetTester tester) async {
      int? picked;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: AppBottomBar(items: items, selectedIndex: 0, onSelected: (int i) => picked = i),
        ),
      );
      await tester.tap(find.text('Settings'));
      expect(picked, 2);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('is 64 high, plus the bottom safe area', (WidgetTester tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      await pumpApp(
        tester,
        SizedBox(width: 400, child: AppBottomBar(items: items, selectedIndex: 1, onSelected: (_) {})),
      );
      expect(tester.getSize(find.byType(AppBottomBar)).height, AppSizes.bottomBarHeight + 34 + AppSizes.hairline);
    });

    testWidgets('the selected destination is announced as selected', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        SizedBox(width: 400, child: AppBottomBar(items: items, selectedIndex: 1, onSelected: (_) {})),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Cameras')), isSemantics(isSelected: true));
      handle.dispose();
    });

    testWidgets('labels stay on one line at large text', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(width: 400, child: AppBottomBar(items: items, selectedIndex: 0, onSelected: (_) {})),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppBottomBar)).height, AppSizes.bottomBarHeight + AppSizes.hairline);
    });
  });

  group('AppScaffold', () {
    Widget screen() {
      return AppScaffold(
        navBar: const AppNavBar(title: 'Title'),
        body: const SizedBox.expand(key: Key('body')),
        bottomEmbed: const SizedBox(key: Key('embed'), height: 60),
        bottomBar: AppBottomBar(
          items: const <AppBottomBarItem>[AppBottomBarItem(icon: AppIconName.cameraDome, label: 'Live')],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );
    }

    testWidgets('stacks nav bar, body, embed and bar, and respects the safe areas', (WidgetTester tester) async {
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPadding);
      await pumpApp(tester, SizedBox(width: 400, height: 800, child: screen()));

      final Rect nav = tester.getRect(find.byType(AppNavBar));
      final Rect body = tester.getRect(find.byKey(const Key('body')));
      final Rect embed = tester.getRect(find.byKey(const Key('embed')));
      final Rect bar = tester.getRect(find.byType(AppBottomBar));
      expect(nav.top, 24);
      expect(body.top, nav.bottom);
      expect(embed.top, body.bottom);
      expect(bar.top, embed.bottom);
      expect(bar.bottom, 800);
    });

    testWidgets('the whole bottom stack collapses under the keyboard and returns', (WidgetTester tester) async {
      await pumpApp(tester, SizedBox(width: 400, height: 800, child: screen()));
      final double normalBody = tester.getSize(find.byKey(const Key('body'))).height;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppBottomBar)).height, 0);
      expect(find.byKey(const Key('embed')).hitTestable(), findsNothing);
      expect(tester.getSize(find.byKey(const Key('body'))).height, lessThan(normalBody + 200));

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('body'))).height, normalBody);
    });

    testWidgets('immersive mode ignores the safe areas', (WidgetTester tester) async {
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPadding);
      await pumpApp(
        tester,
        const SizedBox(width: 400, height: 800, child: AppScaffold(immersive: true, body: SizedBox.expand(key: Key('b')))),
      );
      expect(tester.getRect(find.byKey(const Key('b'))), const Rect.fromLTWH(0, 0, 400, 800));
    });
  });

  group('AppPageRoute', () {
    Future<void> openScreen(WidgetTester tester, {bool reduce = false}) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Open',
            onPressed: () {
              Navigator.of(context).push<void>(
                AppPageRoute<void>(
                  reduceMotion: reduce,
                  builder: (BuildContext _) => const Text('Second screen'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
    }

    testWidgets('fades and slides in over 350 ms', (WidgetTester tester) async {
      await openScreen(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Second screen'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getTopLeft(find.text('Second screen')).dx, lessThan(5));
    });

    testWidgets('with reduced motion the screen is there at once', (WidgetTester tester) async {
      await openScreen(tester, reduce: true);
      await tester.pump();
      expect(find.text('Second screen'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Second screen')).dx, 0);
    });
  });

  group('showAppSheet and showAppDialog', () {
    Future<void> pumpOpener(
      WidgetTester tester,
      void Function(BuildContext context) open,
    ) async {
      await pumpApp(
        tester,
        Builder(builder: (BuildContext context) => AppButton(label: 'Open', onPressed: () => open(context))),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a sheet shows its title and content and closes on a tap outside', (WidgetTester tester) async {
      await pumpOpener(
        tester,
        (BuildContext c) => showAppSheet<void>(
          c,
          dismissLabel: 'Close',
          title: 'Layout',
          builder: (BuildContext _) => const Text('Sheet body'),
        ),
      );
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Sheet body'), findsOneWidget);

      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
    });

    testWidgets('Escape closes a sheet', (WidgetTester tester) async {
      await pumpOpener(
        tester,
        (BuildContext c) => showAppSheet<void>(c, dismissLabel: 'Close', builder: (BuildContext _) => const Text('Sheet body')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
    });

    testWidgets('a sheet is never taller than 90 percent of the screen', (WidgetTester tester) async {
      await pumpOpener(
        tester,
        (BuildContext c) => showAppSheet<void>(
          c,
          dismissLabel: 'Close',
          builder: (BuildContext _) => ListView(children: <Widget>[for (int i = 0; i < 100; i++) const SizedBox(height: 60)]),
        ),
      );
      expect(tester.getSize(find.byType(AppSheet)).height, lessThanOrEqualTo(800 * AppSheet.maxHeightFactor + 1));
    });

    testWidgets('a dialog returns the value of the chosen action', (WidgetTester tester) async {
      String? result;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Open',
            onPressed: () async {
              result = await showAppDialog<String>(
                context,
                dismissLabel: 'Cancel',
                builder: (BuildContext dialogContext) => AppDialog(
                  title: 'Delete camera?',
                  message: 'It will be removed from this phone.',
                  actions: <AppDialogAction>[
                    AppDialogAction(label: 'Delete', kind: AppButtonKind.destructive, onPressed: () => Navigator.of(dialogContext).pop('delete')),
                    AppDialogAction(label: 'Keep', onPressed: () => Navigator.of(dialogContext).pop('keep')),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete camera?'), findsOneWidget);
      // Buttons are stacked, one under the other.
      expect(tester.getTopLeft(find.text('Keep')).dy, greaterThan(tester.getTopLeft(find.text('Delete')).dy));

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(result, 'keep');
    });

    testWidgets('a dialog that is not dismissible ignores outside taps', (WidgetTester tester) async {
      await pumpOpener(
        tester,
        (BuildContext c) => showAppDialog<void>(
          c,
          dismissLabel: 'x',
          dismissible: false,
          builder: (BuildContext _) => const AppDialog(title: 'Wait', actions: <AppDialogAction>[]),
        ),
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Wait'), findsOneWidget);
    });

    testWidgets('a dialog with long text and large type scrolls instead of overflowing', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Open',
            onPressed: () => showAppDialog<void>(
              context,
              dismissLabel: 'x',
              builder: (BuildContext _) => AppDialog(
                title: 'A fairly long dialog title',
                message: 'A long message that goes on for several lines to be sure the dialog copes.',
                actions: <AppDialogAction>[AppDialogAction(label: 'OK', onPressed: () {})],
              ),
            ),
          ),
        ),
        textScale: 3,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('AppToast', () {
    Future<void> openToast(
      WidgetTester tester, {
      String? actionLabel,
      VoidCallback? onAction,
      Duration duration = const Duration(seconds: 4),
    }) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Go',
            onPressed: () => AppToast.show(
              context,
              message: 'Camera deleted',
              actionLabel: actionLabel,
              onAction: onAction,
              duration: duration,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    }

    testWidgets('shows the message and goes away by itself', (WidgetTester tester) async {
      await openToast(tester);
      expect(find.text('Camera deleted'), findsOneWidget);
      expect(AppToast.isShowing, isTrue);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Camera deleted'), findsNothing);
      expect(AppToast.isShowing, isFalse);
    });

    testWidgets('the Undo pill runs its action and closes the toast', (WidgetTester tester) async {
      int undone = 0;
      await openToast(tester, actionLabel: 'Undo', onAction: () => undone++);
      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(undone, 1);
      expect(find.text('Camera deleted'), findsNothing);
    });

    testWidgets('a new toast replaces the old one', (WidgetTester tester) async {
      await openToast(tester);
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('Camera deleted'), findsOneWidget);
      AppToast.dismiss(immediately: true);
    });

    testWidgets('is announced as a live region', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openToast(tester);
      expect(find.bySemanticsLabel('Camera deleted'), findsOneWidget);
      AppToast.dismiss(immediately: true);
      handle.dispose();
    });
  });

  group('AppBanner', () {
    testWidgets('every tone shows its message with an icon', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: Column(
            children: <Widget>[
              for (final AppBannerTone tone in AppBannerTone.values) AppBanner(message: tone.name, tone: tone),
            ],
          ),
        ),
      );
      for (final AppBannerTone tone in AppBannerTone.values) {
        expect(find.text(tone.name), findsOneWidget);
      }
    });

    testWidgets('its action is a pill that fires', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppBanner(message: 'Storage problem', actionLabel: 'Export', onAction: () => taps++),
        ),
      );
      await tester.tap(find.text('Export'));
      expect(taps, 1);
    });
  });

  group('AppLetterHeader', () {
    testWidgets('stays pinned at the top while its group scrolls', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CustomScrollView(
            slivers: <Widget>[
              AppLetterHeader.sliver('A'),
              SliverList.builder(itemCount: 10, itemBuilder: (BuildContext c, int i) => const SizedBox(height: 100)),
              AppLetterHeader.sliver('B'),
              SliverList.builder(itemCount: 10, itemBuilder: (BuildContext c, int i) => const SizedBox(height: 100)),
            ],
          ),
        ),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expect(tester.getTopLeft(find.text('A')).dy, lessThan(AppLetterHeader.height));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('the next letter pushes the previous one away', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CustomScrollView(
            slivers: <Widget>[
              AppLetterHeader.sliver('A'),
              SliverList.builder(itemCount: 3, itemBuilder: (BuildContext c, int i) => const SizedBox(height: 100)),
              AppLetterHeader.sliver('B'),
              SliverList.builder(itemCount: 30, itemBuilder: (BuildContext c, int i) => const SizedBox(height: 100)),
            ],
          ),
        ),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      expect(tester.getTopLeft(find.text('B')).dy, lessThan(AppLetterHeader.height));
    });
  });

  group('AppEmptyState and AppErrorState', () {
    testWidgets('an empty state shows icon, title, message and one action', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: AppEmptyState(
            icon: AppIconName.cameraAdd,
            title: 'No cameras yet',
            message: 'Add your first camera.',
            actionLabel: 'Add camera',
            onAction: () => taps++,
          ),
        ),
      );
      expect(find.text('No cameras yet'), findsOneWidget);
      await tester.tap(find.text('Add camera'));
      expect(taps, 1);
    });

    testWidgets('an empty state with no action has no button', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 400, height: 800, child: AppEmptyState(icon: AppIconName.search, title: 'No results')),
      );
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('an error state has retry and a second action', (WidgetTester tester) async {
      int retried = 0;
      int edited = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: AppErrorState(
            title: "Can't reach the camera",
            message: 'Check that the phone is on the same Wi-Fi.',
            primaryLabel: 'Retry',
            onPrimary: () => retried++,
            secondaryLabel: 'Edit camera',
            onSecondary: () => edited++,
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Edit camera'));
      expect(retried, 1);
      expect(edited, 1);
    });

    testWidgets('both survive very large text without overflowing', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          height: 800,
          child: AppErrorState(
            title: 'Something went wrong here',
            message: 'A longer explanation of what happened and what to try next.',
            primaryLabel: 'Retry',
            onPrimary: () {},
          ),
        ),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSlider', () {
    Widget slider({
      required ValueChanged<double>? onChanged,
      double value = 0,
      int? divisions,
      ValueChanged<double>? onChangeEnd,
    }) {
      return SizedBox(
        width: 300,
        child: AppSlider(
          value: value,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          divisions: divisions,
          semanticLabel: 'Speed',
        ),
      );
    }

    testWidgets('a tap sets the value by position', (WidgetTester tester) async {
      double? value;
      await pumpApp(tester, slider(onChanged: (double v) => value = v));
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(150, 24));
      expect(value, closeTo(0.5, 0.02));
    });

    testWidgets('dragging follows the finger and reports the end', (WidgetTester tester) async {
      final List<double> values = <double>[];
      double? ended;
      await pumpApp(tester, slider(onChanged: values.add, onChangeEnd: (double v) => ended = v));
      final Offset start = tester.getTopLeft(find.byType(AppSlider)) + const Offset(20, 24);
      final TestGesture gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(100, 0));
      await gesture.moveBy(const Offset(100, 0));
      await gesture.up();
      expect(values, isNotEmpty);
      expect(values.last, greaterThan(values.first));
      expect(ended, isNotNull);
    });

    testWidgets('divisions snap the value', (WidgetTester tester) async {
      double? value;
      await pumpApp(tester, slider(onChanged: (double v) => value = v, divisions: 4));
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(165, 24));
      expect(value, 0.5);
    });

    testWidgets('in a right-to-left layout the high end is on the left', (WidgetTester tester) async {
      double? value;
      await pumpApp(tester, slider(onChanged: (double v) => value = v), direction: TextDirection.rtl, size: const Size(300, 800));
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(20, 24));
      expect(value, greaterThan(0.9));
    });

    testWidgets('arrow keys move it by a step', (WidgetTester tester) async {
      final List<double> values = <double>[];
      await pumpApp(tester, slider(value: 0.5, onChanged: values.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(values, hasLength(2));
      expect(values.first, greaterThan(0.5));
      expect(values.last, lessThan(0.5));
    });

    testWidgets('a disabled slider ignores touches', (WidgetTester tester) async {
      await pumpApp(tester, slider(onChanged: null));
      await tester.tapAt(tester.getTopLeft(find.byType(AppSlider)) + const Offset(150, 24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is exposed to accessibility as an adjustable value', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, slider(value: 0.25, onChanged: (_) {}));
      expect(tester.getSemantics(find.bySemanticsLabel('Speed')), isSemantics(isSlider: true, value: '25%'));
      handle.dispose();
    });

    testWidgets('has a 48 high touch area', (WidgetTester tester) async {
      await pumpApp(tester, slider(onChanged: (_) {}));
      expect(tester.getSize(find.byType(AppSlider)).height, AppSizes.touchTarget);
    });
  });
}
