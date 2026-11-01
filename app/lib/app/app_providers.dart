import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:roehens/core/contracts/ad_contract.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/contracts/secure_vault_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/core/providers/auto_cycle_provider.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/core/providers/discovery_provider.dart';
import 'package:roehens/core/providers/flags_provider.dart';
import 'package:roehens/core/providers/layout_provider.dart';
import 'package:roehens/core/providers/locale_provider.dart';
import 'package:roehens/core/providers/onboarding_provider.dart';
import 'package:roehens/core/providers/persistence_health_provider.dart';
import 'package:roehens/core/providers/settings_provider.dart';
import 'package:roehens/core/providers/subscription_provider.dart';
import 'package:roehens/core/providers/theme_provider.dart';
import 'package:roehens/core/providers/undo_provider.dart';
import 'package:roehens/core/services/camera_export_service.dart';
import 'package:roehens/core/services/camera_import_service.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/core/services/diagnostics_service.dart';
import 'package:roehens/core/services/flag_service.dart';
import 'package:roehens/core/services/grid_planner.dart';
import 'package:roehens/core/services/profile_catalog.dart';
import 'package:roehens/core/services/review_prompt_policy.dart';
import 'package:roehens/platform/files/file_picker_service.dart';
import 'package:roehens/platform/files/file_transfer_service.dart';
import 'package:roehens/platform/files/share_service.dart';
import 'package:roehens/platform/network/discovery_service.dart';
import 'package:roehens/platform/network/flags_http_fetcher.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/local_network_permission_service.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';
import 'package:roehens/platform/network/network_probes.dart';
import 'package:roehens/platform/network/onvif_client.dart';
import 'package:roehens/platform/network/ptz_service.dart';
import 'package:roehens/platform/network/subnet_scanner.dart';
import 'package:roehens/platform/network/ws_discovery_socket.dart';
import 'package:roehens/platform/player/frame_capture_service.dart';
import 'package:roehens/platform/player/media_player_service.dart';
import 'package:roehens/platform/player/player_pool.dart';
import 'package:roehens/platform/storage/database_service.dart';
import 'package:roehens/platform/storage/key_value_store.dart';
import 'package:roehens/platform/storage/secure_vault_service.dart';
import 'package:roehens/platform/store/admob_service.dart';
import 'package:roehens/platform/store/att_service.dart';
import 'package:roehens/platform/store/billing_service.dart';
import 'package:roehens/platform/store/consent_service.dart';
import 'package:roehens/platform/store/review_service.dart';
import 'package:roehens/platform/store/store_config.dart';
import 'package:roehens/platform/system/haptics_service.dart';
import 'package:roehens/platform/system/logger_service.dart';
import 'package:roehens/platform/system/orientation_service.dart';
import 'package:roehens/platform/system/pip_service.dart';
import 'package:roehens/platform/system/screen_wake_service.dart';

/// Replacements for the pieces that talk to the phone, used by tests. A null
/// field means the real service.
class AppOverrides {
  const AppOverrides({
    this.keyValueStore,
    this.storage,
    this.vault,
    this.purchase,
    this.ad,
    this.consent,
    this.permission,
    this.discovery,
    this.clock,
  });

  final KeyValueStore? keyValueStore;
  final StorageContract? storage;
  final SecureVaultContract? vault;
  final PurchaseContract? purchase;
  final AdContract? ad;
  final ConsentContract? consent;
  final PermissionContract? permission;
  final DiscoveryContract? discovery;
  final ClockContract? clock;
}

/// The composition root: every real service is built here with plain
/// constructors and handed to the providers. Screens and widgets receive this
/// object and never import `platform/`.
class AppProviders {
  AppProviders._({
    required this.logger,
    required this.clock,
    required this.storeConfig,
    required this.repository,
    required this.settings,
    required this.theme,
    required this.locale,
    required this.onboarding,
    required this.cameras,
    required this.layout,
    required this.flagService,
    required this.flags,
    required this.subscription,
    required this.adState,
    required this.undo,
    required this.persistence,
    required this.discovery,
    required this.autoCycle,
    required this.consent,
    required this.tracking,
    required this.exporter,
    required this.importer,
    required this.fileTransfer,
    required this.reviewPolicy,
    required this.review,
    required this.haptics,
    required this.wake,
    required this.orientation,
    required this.pip,
    required this.ptz,
    required this.permission,
    required this.lan,
    required this.connectionTester,
    required this.profiles,
    required this.diagnostics,
    required this.playerPool,
    required this.frameCapture,
    required this.gridPlanner,
    required this.iosDiscoveryMode,
    required this._ownedResources,
  });

  final LoggerContract logger;
  final ClockContract clock;
  final StoreConfig storeConfig;
  final CameraRepository repository;

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final OnboardingProvider onboarding;
  final CamerasProvider cameras;
  final LayoutProvider layout;
  final FlagService flagService;
  final FlagsProvider flags;
  final SubscriptionProvider subscription;
  final AdStateProvider adState;
  final UndoProvider undo;
  final PersistenceHealthProvider persistence;
  final DiscoveryProvider discovery;
  final AutoCycleProvider autoCycle;

  final ConsentContract consent;
  final TrackingAuthorizationContract tracking;
  final CameraExportService exporter;
  final CameraImportService importer;
  final FileTransferService fileTransfer;
  final ReviewPromptPolicy reviewPolicy;
  final ReviewService review;
  final HapticsService haptics;
  final ScreenWakeService wake;
  final OrientationService orientation;
  final PipService pip;
  final PtzService ptz;
  final PermissionContract permission;
  final LanInfo lan;
  final ConnectionTester connectionTester;
  final ProfileCatalog profiles;
  final DiagnosticsService diagnostics;
  final PlayerPool playerPool;
  final FrameCaptureService frameCapture;
  final GridPlanner gridPlanner;

  /// `subnet_sweep_only` or `ws_discovery` (D4), for diagnostics.
  final String iosDiscoveryMode;
  final List<Future<void> Function()> _ownedResources;
  final List<VoidCallback> _unlisten = <VoidCallback>[];
  bool _disposed = false;

  /// Builds everything and loads what the first frame needs from local storage
  /// (settings, onboarding, cameras, layout). Network work (the store, the
  /// flags file) starts in the background so launch stays fast.
  static Future<AppProviders> create({
    StoreConfig? config,
    Uri? flagsUrl,
    String? appVersion,
    AppOverrides overrides = const AppOverrides(),
  }) async {
    final LoggerContract logger = LoggerService();
    final ClockContract clock = overrides.clock ?? const SystemClock();
    final StoreConfig storeConfig = config ?? StoreConfig.current();
    final List<Future<void> Function()> owned = <Future<void> Function()>[];

    final KeyValueStore keyValue =
        overrides.keyValueStore ?? SharedPrefsKeyValueStore(logger: logger);

    StorageContract storage;
    bool downgradeRefused = false;
    if (overrides.storage != null) {
      storage = overrides.storage!;
    } else {
      final DatabaseService database = DatabaseService(logger: logger);
      await database.open();
      downgradeRefused = database.outcome == StorageOpenOutcome.downgradeRefused;
      owned.add(() async => database.dispose());
      storage = database;
    }
    final SecureVaultContract vault =
        overrides.vault ?? SecureVaultService(logger: logger);
    final CameraRepository repository = CameraRepository(
      storage: storage,
      vault: vault,
      clock: clock,
    );

    final SettingsProvider settings =
        SettingsProvider(store: keyValue, logger: logger);
    final OnboardingProvider onboarding = OnboardingProvider(store: keyValue);
    final CamerasProvider cameras = CamerasProvider(repository: repository);
    final LayoutProvider layout =
        LayoutProvider(storage: storage, store: keyValue, logger: logger);
    await Future.wait(<Future<void>>[
      settings.load(),
      onboarding.load(),
      cameras.load(),
      layout.load(),
    ]);

    final FlagService flagService = FlagService(
      store: keyValue,
      fetcher: fetchFlagsText,
      clock: clock,
      logger: logger,
      url: flagsUrl,
    );
    final FlagsProvider flags = FlagsProvider(flags: flagService);

    final PurchaseContract purchase = overrides.purchase ??
        BillingService(config: storeConfig, clock: clock, logger: logger);
    if (overrides.purchase == null) {
      owned.add(() => (purchase as BillingService).dispose());
    }
    final SubscriptionProvider subscription = SubscriptionProvider(
      purchase: purchase,
      store: keyValue,
      clock: clock,
      logger: logger,
    );

    final ConsentContract consent =
        overrides.consent ?? ConsentService(logger: logger);
    final AdContract ad =
        overrides.ad ?? AdMobService(config: storeConfig, logger: logger);
    final AdStateProvider adState = AdStateProvider(
      ad: ad,
      consent: consent,
      subscription: subscription,
      flags: flags,
      logger: logger,
    );

    final MulticastLockChannel channel = MulticastLockChannel();
    final LanInfo lan = LanInfo(channel: channel);
    final PermissionContract permission = overrides.permission ??
        LocalNetworkPermissionService(lan: lan, channel: channel);
    const String iosMode = String.fromEnvironment(
      'IOS_DISCOVERY_MODE',
      defaultValue: 'subnet_sweep_only',
    );
    final DiscoveryContract discoveryContract = overrides.discovery ??
        DiscoveryService(
          lan: lan,
          scanner: SubnetScanner(),
          socket: WsDiscoverySocket(),
          channel: channel,
          wsDiscoveryEnabled: !Platform.isIOS || iosMode == 'ws_discovery',
          logger: logger,
        );
    final DiscoveryProvider discovery = DiscoveryProvider(
      discovery: discoveryContract,
      flags: flags,
      logger: logger,
      permission: permission,
    );

    final PipService pip = PipService(logger: logger);
    owned.add(() async => pip.dispose());

    final MediaPlayerService mediaPlayer = MediaPlayerService(logger: logger);
    final PlayerPool pool = PlayerPool(
      sessionFactory: mediaPlayer.sessionFor,
      logger: logger,
    );
    owned.add(pool.disposeAll);

    final ProfileCatalog profiles = ProfileCatalog.parse(
      await rootBundle.loadString('assets/profiles/camera_profiles.json'),
    );

    final PersistenceHealthProvider persistence = PersistenceHealthProvider(
      sources: <ValueListenable<bool>>[
        storage.isDegraded,
        if (keyValue is SharedPrefsKeyValueStore) keyValue.isDegraded,
      ],
    );
    if (downgradeRefused) {
      persistence.markUpdateRequired();
    }

    final AppProviders app = AppProviders._(
      logger: logger,
      clock: clock,
      storeConfig: storeConfig,
      repository: repository,
      settings: settings,
      theme: ThemeProvider(settings: settings),
      locale: LocaleProvider(settings: settings),
      onboarding: onboarding,
      cameras: cameras,
      layout: layout,
      flagService: flagService,
      flags: flags,
      subscription: subscription,
      adState: adState,
      undo: UndoProvider(restore: cameras.restore),
      persistence: persistence,
      discovery: discovery,
      autoCycle: AutoCycleProvider(),
      consent: consent,
      tracking: AttService(logger: logger),
      exporter: CameraExportService(clock: clock, appVersion: appVersion),
      importer: CameraImportService(repository: repository),
      fileTransfer: FileTransferService(
        share: ShareService(logger: logger),
        picker: FilePickerService(logger: logger),
      ),
      reviewPolicy: ReviewPromptPolicy(store: keyValue, clock: clock),
      review: ReviewService(config: storeConfig, logger: logger),
      haptics: HapticsService(isEnabled: () => settings.value.hapticsEnabled),
      wake: ScreenWakeService(logger: logger),
      orientation: OrientationService(logger: logger),
      pip: pip,
      ptz: PtzService(client: OnvifClient()),
      permission: permission,
      lan: lan,
      connectionTester: ConnectionTester(probes: NetworkProbes()),
      profiles: profiles,
      diagnostics: const DiagnosticsService(),
      playerPool: pool,
      frameCapture: FrameCaptureService(pool: pool, clock: clock),
      gridPlanner: const GridPlanner(),
      iosDiscoveryMode: iosMode,
      ownedResources: owned,
    );
    app._wire();
    await app._startBackgroundWork();
    return app;
  }

  /// Connections between providers that no single provider owns.
  void _wire() {
    void syncLayout() {
      final CamerasState state = cameras.value;
      if (!state.isLoaded || state.error != null) {
        return;
      }
      unawaited(layout.syncCameras(state.cameras));
      layout.clampPage(state.cameras.length);
    }

    void syncAutoCycle() {
      autoCycle.configure(
        enabled: settings.value.autoCycleEnabled,
        seconds: AutoCycleProvider.effectiveSeconds(settings.value, layout.value),
      );
    }

    cameras.addListener(syncLayout);
    settings.addListener(syncAutoCycle);
    layout.addListener(syncAutoCycle);
    _unlisten
      ..add(() => cameras.removeListener(syncLayout))
      ..add(() => settings.removeListener(syncAutoCycle))
      ..add(() => layout.removeListener(syncAutoCycle));
    syncLayout();
    syncAutoCycle();
  }

  Future<void> _startBackgroundWork() async {
    await reviewPolicy.recordLaunch();
    await pip.initialize();
    unawaited(subscription.init());
    unawaited(flagService.refresh());
    flagService.start();
  }

  /// Call when the app returns to the foreground.
  Future<void> onResume() async {
    autoCycle.setForeground(foreground: true);
    await flagService.onResume();
  }

  /// Call when the app leaves the screen.
  void onPause() {
    autoCycle.setForeground(foreground: false);
  }

  /// "Delete all local data" (A3): cameras, credentials, layouts, settings,
  /// onboarding and the cached unlock. Logs are cleared too.
  Future<void> deleteAllLocalData() async {
    await cameras.deleteAll();
    await settings.reset();
    await onboarding.reset();
    await subscription.reset();
    logger.clear();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final VoidCallback remove in _unlisten) {
      remove();
    }
    for (final ChangeNotifier notifier in <ChangeNotifier>[
      adState,
      autoCycle,
      discovery,
      undo,
      persistence,
      subscription,
      flags,
      layout,
      cameras,
      locale,
      theme,
      onboarding,
      settings,
    ]) {
      notifier.dispose();
    }
    flagService.dispose();
    for (final Future<void> Function() release in _ownedResources) {
      await release();
    }
  }
}
