import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/core/providers/persistence_health_provider.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/widgets/banner_ad_slot.dart';
import 'package:roehens/widgets/brand_picker.dart';
import 'package:roehens/widgets/camera_list_row.dart';
import 'package:roehens/widgets/connection_test_panel.dart';
import 'package:roehens/widgets/discovery_result_row.dart';
import 'package:roehens/widgets/error_boundary_view.dart';
import 'package:roehens/widgets/onboarding_page.dart';
import 'package:roehens/widgets/permission_rationale_view.dart';
import 'package:roehens/widgets/persistence_warning_banner.dart';
import 'package:roehens/widgets/pro_badge.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

import '../support/pump_app.dart';

CameraBrandProfile brand(String name, {bool verified = false, String? id}) {
  return CameraBrandProfile(
    id: id ?? name.toLowerCase(),
    displayName: name,
    defaultPorts: const <int>[554],
    mainPathTemplates: const <String>['/'],
    subPathTemplates: const <String>[],
    mjpegTemplates: const <String>[],
    snapshotTemplates: const <String>[],
    verified: verified,
  );
}

ConnectionTestLabels labels() {
  return ConnectionTestLabels(
    run: 'Test connection',
    runAgain: 'Test again',
    running: 'Testing',
    passed: 'Connected',
    failed: "Can't connect",
    stage: (TestStage s) => 'stage-${s.name}',
    stageStatus: (StageStatus s) => 'status-${s.name}',
    elapsed: (int ms) => '$ms ms',
    troubleshoot: 'Open troubleshooter',
  );
}

void main() {
  group('DiscoveryResultRow', () {
    testWidgets('shows name, address and source and reports taps', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: DiscoveryResultRow(
            title: 'Porch camera',
            address: '192.168.1.20:554',
            sourceLabel: 'ONVIF',
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Porch camera'), findsOneWidget);
      expect(find.text('192.168.1.20:554'), findsOneWidget);
      expect(find.text('ONVIF'), findsOneWidget);
      await tester.tap(find.text('Porch camera'));
      expect(taps, 1);
    });

    testWidgets('survives large text', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: DiscoveryResultRow(
            title: 'A camera with a rather long model name',
            subtitle: 'Some model',
            address: '192.168.100.200:8554',
            sourceLabel: 'Network scan',
            onTap: () {},
          ),
        ),
        textScale: 3,
        size: const Size(400, 6000),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CameraListRow', () {
    CameraListRow row({VoidCallback? onTap, VoidCallback? onLong, VoidCallback? onDelete}) {
      return CameraListRow(
        dismissKey: const ValueKey<String>('a'),
        name: 'Garden',
        address: '10.0.0.7:554',
        protocolLabel: 'RTSP',
        status: StreamStatus.live,
        statusLabel: 'Live',
        onTap: onTap,
        onLongPress: onLong,
        onDelete: onDelete,
        deleteLabel: onDelete == null ? null : 'Delete',
      );
    }

    testWidgets('shows name, address, protocol and status', (WidgetTester tester) async {
      await pumpApp(tester, SizedBox(width: 400, child: row(onTap: () {})));
      for (final String text in <String>['Garden', '10.0.0.7:554', 'RTSP', 'Live']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.getSize(find.byType(CameraListRow)).height, greaterThanOrEqualTo(AppSizes.rowMinHeight));
    });

    testWidgets('tap and long-press are reported', (WidgetTester tester) async {
      int taps = 0;
      int longs = 0;
      await pumpApp(tester, SizedBox(width: 400, child: row(onTap: () => taps++, onLong: () => longs++)));
      await tester.tap(find.text('Garden'));
      await tester.longPress(find.text('Garden'));
      expect(taps, 1);
      expect(longs, 1);
    });

    testWidgets('swiping toward the end asks to delete and keeps the row until the list changes', (WidgetTester tester) async {
      int deletes = 0;
      await pumpApp(tester, SizedBox(width: 400, child: row(onTap: () {}, onDelete: () => deletes++)));
      await tester.drag(find.text('Garden'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(deletes, 1);
      expect(find.text('Garden'), findsOneWidget);
    });

    testWidgets('in right-to-left the delete swipe goes the other way', (WidgetTester tester) async {
      int deletes = 0;
      await pumpApp(
        tester,
        SizedBox(width: 400, child: row(onTap: () {}, onDelete: () => deletes++)),
        direction: TextDirection.rtl,
      );
      await tester.drag(find.text('Garden'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(deletes, 0);
      await tester.drag(find.text('Garden'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(deletes, 1);
    });

    testWidgets('a row with no status shows none', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          child: CameraListRow(
            dismissKey: ValueKey<String>('b'),
            name: 'Door',
            address: 'door.example.org:80',
            protocolLabel: 'MJPEG',
          ),
        ),
      );
      expect(find.text('Live'), findsNothing);
    });
  });

  group('BrandPicker', () {
    final List<CameraBrandProfile> brands = <CameraBrandProfile>[
      brand('Reolink', verified: true),
      brand('Axis'),
      brand('Hikvision', verified: true),
      brand('Amcrest'),
      brand('3xLogic'),
    ];

    Future<CameraBrandProfile?> pumpPicker(WidgetTester tester, {String? selected}) async {
      CameraBrandProfile? picked;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: BrandPicker(
            brands: brands,
            selectedId: selected,
            searchLabel: 'Search brands',
            noResultsTitle: 'No brand found',
            verifiedLabel: 'Verified',
            onSelected: (CameraBrandProfile b) => picked = b,
          ),
        ),
      );
      return picked;
    }

    test('groups by first letter, sorted, with other characters last', () {
      final List<MapEntry<String, List<CameraBrandProfile>>> groups = BrandPicker.group(brands, '');
      expect(groups.map((MapEntry<String, List<CameraBrandProfile>> e) => e.key), <String>['A', 'H', 'R', '#']);
      expect(groups.first.value.map((CameraBrandProfile b) => b.displayName), <String>['Amcrest', 'Axis']);
    });

    test('search is case-insensitive and matches inside names', () {
      final List<MapEntry<String, List<CameraBrandProfile>>> groups = BrandPicker.group(brands, 'VIS');
      expect(groups.single.value.single.displayName, 'Hikvision');
      expect(BrandPicker.group(brands, 'zzz'), isEmpty);
    });

    test('letters', () {
      expect(BrandPicker.letterFor('reolink'), 'R');
      expect(BrandPicker.letterFor('3xLogic'), '#');
      expect(BrandPicker.letterFor(''), '#');
    });

    testWidgets('shows letter headers and brands, and selecting reports the brand', (WidgetTester tester) async {
      CameraBrandProfile? picked;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: BrandPicker(
            brands: brands,
            searchLabel: 'Search brands',
            noResultsTitle: 'No brand found',
            verifiedLabel: 'Verified',
            onSelected: (CameraBrandProfile b) => picked = b,
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Axis'), findsOneWidget);
      expect(find.text('Verified'), findsNWidgets(2));
      await tester.tap(find.text('Axis'));
      expect(picked?.id, 'axis');
    });

    testWidgets('typing filters the list and shows an empty state when nothing matches', (WidgetTester tester) async {
      await pumpPicker(tester);
      await tester.enterText(find.byType(EditableText), 'rei');
      await tester.pump();
      expect(find.text('Axis'), findsNothing);
      expect(find.text('Reolink'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();
      expect(find.text('No brand found'), findsOneWidget);
    });

    testWidgets('the search field scrolls away with the content', (WidgetTester tester) async {
      final List<CameraBrandProfile> many = <CameraBrandProfile>[
        for (int i = 0; i < 60; i++) brand('Brand ${String.fromCharCode(65 + i % 26)}$i', id: 'b$i'),
      ];
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: BrandPicker(
            brands: many,
            searchLabel: 'Search brands',
            noResultsTitle: 'None',
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.byType(AppTextField), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pump();
      expect(find.byType(AppTextField), findsNothing);
    });

    testWidgets('the chosen brand is marked selected', (WidgetTester tester) async {
      await pumpPicker(tester, selected: 'axis');
      expect(find.text('Axis'), findsOneWidget);
    });
  });

  group('ConnectionTestPanel', () {
    const ConnectionTestResult passed = ConnectionTestResult(stages: <StageResult>[
      StageResult(stage: TestStage.dns, status: StageStatus.passed, elapsedMillis: 12),
      StageResult(stage: TestStage.tcp, status: StageStatus.passed, elapsedMillis: 30),
    ]);
    const ConnectionTestResult failed = ConnectionTestResult(
      stages: <StageResult>[
        StageResult(stage: TestStage.dns, status: StageStatus.passed, elapsedMillis: 12),
        StageResult(stage: TestStage.tcp, status: StageStatus.failed),
        StageResult(stage: TestStage.auth, status: StageStatus.skipped),
      ],
      error: AppError(ErrorClass.networkUnreachable),
    );

    testWidgets('before a run it offers the primary action and nothing else', (WidgetTester tester) async {
      int runs = 0;
      await pumpApp(tester, SizedBox(width: 400, child: ConnectionTestPanel(labels: labels(), onRun: () => runs++)));
      expect(find.text('stage-dns'), findsNothing);
      await tester.tap(find.text('Test connection'));
      expect(runs, 1);
    });

    testWidgets('a pass shows every stage, its time and a success message', (WidgetTester tester) async {
      await pumpApp(tester, SizedBox(width: 400, child: ConnectionTestPanel(labels: labels(), onRun: () {}, result: passed)));
      expect(find.text('stage-dns'), findsOneWidget);
      expect(find.text('12 ms'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Test again'), findsOneWidget);
      expect(find.text('Open troubleshooter'), findsNothing);
    });

    testWidgets('a failure shows the diagnosis, suggestions and the troubleshooter pill', (WidgetTester tester) async {
      int troubleshoot = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: ConnectionTestPanel(
            labels: labels(),
            onRun: () {},
            result: failed,
            diagnosis: 'The camera did not answer.',
            suggestions: const <String>['Check the Wi-Fi', 'Check the address'],
            onTroubleshoot: () => troubleshoot++,
          ),
        ),
        size: const Size(400, 1400),
      );
      expect(find.text("Can't connect"), findsOneWidget);
      expect(find.text('The camera did not answer.'), findsOneWidget);
      expect(find.text('Check the Wi-Fi'), findsOneWidget);
      expect(find.text('status-failed'), findsOneWidget);
      await tester.tap(find.text('Open troubleshooter'));
      expect(troubleshoot, 1);
    });

    testWidgets('while running the button is busy and cannot be pressed twice', (WidgetTester tester) async {
      int runs = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: ConnectionTestPanel(
            labels: labels(),
            onRun: () => runs++,
            isRunning: true,
            result: const ConnectionTestResult(stages: <StageResult>[
              StageResult(stage: TestStage.dns, status: StageStatus.running),
            ]),
          ),
        ),
      );
      await tester.tap(find.text('Testing'));
      expect(runs, 0);
      expect(find.text('Connected'), findsNothing);
      expect(find.text("Can't connect"), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('each stage is announced as name and status', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, SizedBox(width: 400, child: ConnectionTestPanel(labels: labels(), onRun: () {}, result: failed)));
      expect(find.bySemanticsLabel('stage-tcp, status-failed'), findsOneWidget);
      handle.dispose();
    });
  });

  group('BannerAdSlot', () {
    testWidgets('is absent until there is an ad, then shows it with a hairline and gaps', (WidgetTester tester) async {
      final ValueNotifier<AdSlotState> state = ValueNotifier<AdSlotState>(AdSlotState.collapsed);
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: BannerAdSlot(state: state, viewBuilder: (Object view) => const SizedBox(key: Key('ad'))),
        ),
      );
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 0);

      state.value = AdSlotState(height: 60, view: Object());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ad')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('ad'))).height, 60);
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 60 + 16);

      state.value = AdSlotState.collapsed;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 0);
      expect(find.byKey(const Key('ad')), findsNothing);
    });

    testWidgets('never taller than 100', (WidgetTester tester) async {
      final ValueNotifier<AdSlotState> state = ValueNotifier<AdSlotState>(AdSlotState(height: 250, view: Object()));
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: BannerAdSlot(state: state, viewBuilder: (Object view) => const SizedBox(key: Key('ad'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('ad'))).height, AppSizes.bannerMaxHeight);
    });
  });

  group('ProBadge', () {
    testWidgets('shows its label and is announced by it', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const ProBadge(label: 'PRO'));
      expect(find.text('PRO'), findsOneWidget);
      expect(find.bySemanticsLabel('PRO'), findsOneWidget);
      handle.dispose();
    });
  });

  group('PermissionRationaleView', () {
    testWidgets('explains, lists reasons and offers both actions', (WidgetTester tester) async {
      int primary = 0;
      int secondary = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: PermissionRationaleView(
            title: 'Find cameras on your network',
            message: 'Roehens needs local network access.',
            reasons: const <String>['Find cameras', 'Show their video'],
            primaryLabel: 'Continue',
            onPrimary: () => primary++,
            secondaryLabel: 'Not now',
            onSecondary: () => secondary++,
          ),
        ),
      );
      expect(find.text('Find cameras'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.tap(find.text('Not now'));
      expect((primary, secondary), (1, 1));
    });

    testWidgets('works without a second action and survives large text', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          height: 800,
          child: PermissionRationaleView(
            title: 'Local network access is off',
            message: 'Turn it on in Settings so Roehens can find cameras.',
            primaryLabel: 'Open Settings',
            onPrimary: () {},
          ),
        ),
        textScale: 3,
      );
      expect(find.text('Not now'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('OnboardingPage', () {
    testWidgets('shows the header only when given, then title, message and points', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          height: 800,
          child: OnboardingPage(
            header: Text('Roehens'),
            icon: AppIconName.cameraDome,
            title: 'Every camera, one screen',
            message: 'Watch all your cameras together.',
            points: <String>['RTSP and MJPEG', 'No account needed'],
          ),
        ),
      );
      expect(find.text('Roehens'), findsOneWidget);
      expect(find.text('Every camera, one screen'), findsOneWidget);
      expect(find.text('No account needed'), findsOneWidget);
    });

    testWidgets('a later page has no header', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          height: 800,
          child: OnboardingPage(icon: AppIconName.wifi, title: 'Same Wi-Fi', message: 'Stay on your home network.'),
        ),
      );
      expect(find.text('Roehens'), findsNothing);
    });

    testWidgets('scrolls instead of overflowing at the largest text size', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 360,
          height: 640,
          child: OnboardingPage(
            icon: AppIconName.wifi,
            title: 'Works while the app is open',
            message: 'Roehens shows cameras while it is open on screen.',
            points: <String>['Point one is long enough to wrap', 'Point two is also long enough to wrap'],
          ),
        ),
        textScale: 3,
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PersistenceWarningBanner', () {
    testWidgets('appears with the problem and goes when it is fixed', (WidgetTester tester) async {
      final ValueNotifier<PersistenceIssue> issue = ValueNotifier<PersistenceIssue>(PersistenceIssue.none);
      int actions = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: PersistenceWarningBanner(
            issue: issue,
            degradedMessage: 'Cameras may not be saved.',
            updateMessage: 'Update the app.',
            actionLabel: 'Export',
            onAction: () => actions++,
          ),
        ),
      );
      expect(tester.getSize(find.byType(PersistenceWarningBanner)).height, 0);

      issue.value = PersistenceIssue.degraded;
      await tester.pumpAndSettle();
      expect(find.text('Cameras may not be saved.'), findsOneWidget);
      await tester.tap(find.text('Export'));
      expect(actions, 1);

      issue.value = PersistenceIssue.updateRequired;
      await tester.pumpAndSettle();
      expect(find.text('Update the app.'), findsOneWidget);
      expect(find.text('Export'), findsNothing);

      issue.value = PersistenceIssue.none;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PersistenceWarningBanner)).height, 0);
    });
  });

  group('ErrorBoundaryView', () {
    testWidgets('shows the app until a fatal error, then the fallback, then the app again', (WidgetTester tester) async {
      final ValueNotifier<AppError?> fatal = ValueNotifier<AppError?>(null);
      AppError? reported;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: ErrorBoundaryView(
            fatal: fatal,
            title: 'Something went wrong',
            message: 'Roehens hit a problem.',
            retryLabel: 'Try again',
            reportLabel: 'Report',
            onReport: (AppError e) => reported = e,
            onRetry: () => fatal.value = null,
            child: const Text('App'),
          ),
        ),
      );
      expect(find.text('App'), findsOneWidget);

      fatal.value = const AppError(ErrorClass.fatal, detail: 'boom');
      await tester.pump();
      expect(find.text('App'), findsNothing);
      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Report'));
      expect(reported?.detail, 'boom');

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('without a report handler there is no Report button', (WidgetTester tester) async {
      final ValueNotifier<AppError?> fatal =
          ValueNotifier<AppError?>(const AppError(ErrorClass.fatal));
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: ErrorBoundaryView(
            fatal: fatal,
            title: 'Something went wrong',
            message: 'x',
            retryLabel: 'Try again',
            reportLabel: 'Report',
            onRetry: () {},
            child: const Text('App'),
          ),
        ),
      );
      expect(find.text('Report'), findsNothing);
    });
  });
}
