import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/platform/store/store_config.dart';

import '../support/async_helpers.dart';
import '../support/fakes.dart';
import '../support/provider_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeKeyValueStore store;
  late FakeStorage storage;
  late FakeVault vault;
  late FakePurchase purchase;
  late FakeAd ad;
  late AppProviders app;

  Future<void> boot({
    Map<String, Camera> saved = const <String, Camera>{},
  }) async {
    store = FakeKeyValueStore();
    storage = FakeStorage()..cameras.addAll(saved);
    vault = FakeVault();
    purchase = FakePurchase();
    ad = FakeAd();
    app = await AppProviders.create(
      config: StoreConfig.googlePlay,
      overrides: AppOverrides(
        keyValueStore: store,
        storage: storage,
        vault: vault,
        purchase: purchase,
        ad: ad,
        consent: FakeConsent(),
        permission: FakePermission(PermissionStatus.notRequired),
        discovery: FakeDiscovery(),
        clock: FakeClock(),
      ),
    );
  }

  tearDown(() => app.dispose());

  test(
    'builds every provider and loads local data before the first frame',
    () async {
      await boot(
        saved: <String, Camera>{'a': testCamera(id: 'a', name: 'Porch')},
      );

      expect(app.cameras.value.isLoaded, isTrue);
      expect(app.cameras.value.cameras.single.name, 'Porch');
      expect(app.onboarding.isLoaded, isTrue);
      expect(app.onboarding.needsOnboarding, isTrue);
      expect(app.profiles.brands, isNotEmpty);
      expect(app.persistence.hasIssue, isFalse);
    },
  );

  test('the layout follows the cameras that exist', () async {
    await boot(
      saved: <String, Camera>{
        'a': testCamera(id: 'a'),
        'b': testCamera(id: 'b', sortIndex: 1),
      },
    );
    await waitUntil(() => app.layout.value.cameraIds.length == 2);

    await app.cameras.add(testCamera(name: 'New'), CameraCredentials.none);
    await waitUntil(() => app.layout.value.cameraIds.length == 3);

    final String removed = app.cameras.value.cameras.first.id;
    await app.cameras.delete(removed);
    await waitUntil(() => app.layout.value.cameraIds.length == 2);
    expect(app.layout.value.cameraIds, isNot(contains(removed)));
  });

  test('auto-cycle follows the settings and the layout interval', () async {
    await boot();
    app.autoCycle.setViewing(viewing: true);
    expect(app.autoCycle.isRunning, isFalse);

    await app.settings.setAutoCycle(enabled: true, seconds: 30);
    expect(app.autoCycle.isRunning, isTrue);

    await app.settings.setAutoCycle(enabled: false);
    expect(app.autoCycle.isRunning, isFalse);
  });

  test('the app going to the background stops auto-cycle', () async {
    await boot();
    await app.settings.setAutoCycle(enabled: true, seconds: 10);
    app.autoCycle.setViewing(viewing: true);
    expect(app.autoCycle.isRunning, isTrue);

    app.onPause();
    expect(app.autoCycle.isRunning, isFalse);
    await app.onResume();
    expect(app.autoCycle.isRunning, isTrue);
  });

  test('haptics follow the setting at once', () async {
    await boot();
    await app.settings.setHaptics(enabled: false);
    expect(app.settings.value.hapticsEnabled, isFalse);
    // Nothing is sent while off; the call completes without error.
    await app.haptics.light();
  });

  test('a deleted camera can be undone', () async {
    await boot(saved: <String, Camera>{'a': testCamera(id: 'a')});
    final DeletedCamera deleted = (await app.cameras.delete('a')).valueOrNull!;
    app.undo.offer(deleted);
    expect(app.cameras.value.isEmpty, isTrue);

    await app.undo.undo();
    expect(app.cameras.value.cameras, hasLength(1));
  });

  test('the cached ad-free unlock is read at start', () async {
    await boot();
    purchase.current = const Entitlement(
      tier: EntitlementTier.adFree,
      source: EntitlementSource.purchase,
    );
    await app.subscription.init();
    expect(app.subscription.isAdFree, isTrue);
  });

  test(
    'delete all local data empties cameras, credentials and settings',
    () async {
      await boot(saved: <String, Camera>{'a': testCamera(id: 'a')});
      await vault.writeCredentials(
        'a',
        const CameraCredentials(username: 'u', password: 'p'),
      );
      await app.settings.setThemeMode(AppThemeMode.light);
      await app.onboarding.complete();

      await app.deleteAllLocalData();

      expect(app.cameras.value.isEmpty, isTrue);
      expect(vault.entries, isEmpty);
      expect(app.settings.value, const AppSettings());
      expect(app.onboarding.needsOnboarding, isTrue);
    },
  );

  test('a degraded store shows the warning', () async {
    await boot();
    storage.degraded.value = true;
    expect(app.persistence.hasIssue, isTrue);
  });

  test('disposing twice is safe', () async {
    await boot();
    await app.dispose();
    await app.dispose();
  });
}
