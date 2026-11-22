import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/platform/store/store_config.dart';

import 'fake_player.dart';
import 'fakes.dart';
import 'live_fakes.dart';
import 'provider_fakes.dart';

/// The real composition root with every phone-facing piece replaced by a
/// fake, so a screen test drives the real providers.
class ScreenHarness {
  ScreenHarness._(this.app, this.sessions, this.ptz, this.storage);

  final AppProviders app;

  /// Every player session the pool created, in creation order.
  final List<FakePlayerSession> sessions;
  final FakePtz ptz;
  final FakeStorage storage;

  static Future<ScreenHarness> boot(
    WidgetTester tester, {
    List<Camera> cameras = const <Camera>[],
    bool ptzSupported = true,
  }) async {
    final List<FakePlayerSession> sessions = <FakePlayerSession>[];
    final FakePtz ptz = FakePtz(supported: ptzSupported);
    final FakeStorage storage = FakeStorage();
    for (final Camera c in cameras) {
      storage.cameras[c.id] = c;
    }
    final AppProviders? app = await tester.runAsync(
      () => AppProviders.create(
        config: StoreConfig.googlePlay,
        overrides: AppOverrides(
          keyValueStore: FakeKeyValueStore(),
          storage: storage,
          vault: FakeVault(),
          purchase: FakePurchase(),
          ad: FakeAd(),
          consent: FakeConsent(),
          permission: FakePermission(PermissionStatus.notRequired),
          discovery: FakeDiscovery(),
          clock: FakeClock(),
          videoBuilder: fakeVideoView,
          sessionFactory: (_) {
            final FakePlayerSession s = FakePlayerSession();
            sessions.add(s);
            return s;
          },
          ptz: ptz,
          posterFetcher: (_, _, _) async => null,
        ),
      ),
    );
    addTearDown(() async {
      await tester.runAsync(app!.dispose);
    });
    return ScreenHarness._(app!, sessions, ptz, storage);
  }
}

/// Lets timers, animations and the pool's staggered starts run.
Future<void> settle(WidgetTester tester, {int milliseconds = 1200}) async {
  for (int i = 0; i < milliseconds ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
