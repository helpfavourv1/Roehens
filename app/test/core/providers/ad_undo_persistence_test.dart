import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/core/providers/flags_provider.dart';
import 'package:roehens/core/providers/persistence_health_provider.dart';
import 'package:roehens/core/providers/subscription_provider.dart';
import 'package:roehens/core/providers/undo_provider.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/errors/result.dart';

import '../../support/async_helpers.dart';
import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';

void main() {
  group('AdStateProvider', () {
    late FakeAd ad;
    late FakeConsent consent;
    late FakePurchase purchase;
    late FakeFlags flagSource;
    late SubscriptionProvider subscription;
    late FlagsProvider flags;
    late AdStateProvider state;

    Future<void> build({bool consentOk = true}) async {
      ad = FakeAd();
      consent = FakeConsent(canRequest: consentOk);
      purchase = FakePurchase();
      flagSource = FakeFlags();
      flags = FlagsProvider(flags: flagSource);
      subscription = SubscriptionProvider(
        purchase: purchase,
        store: FakeKeyValueStore(),
        clock: FakeClock(),
        logger: FakeLogger(),
      );
      await subscription.init();
      state = AdStateProvider(
        ad: ad,
        consent: consent,
        subscription: subscription,
        flags: flags,
        logger: FakeLogger(),
      );
    }

    tearDown(() {
      state.dispose();
      subscription.dispose();
      flags.dispose();
    });

    test('shows the banner on Live once consent is resolved', () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);

      expect(state.value.height, 60);
      expect(ad.loadedWidths, <int>[360]);
      expect(ad.initializeCalls, 1);
    });

    test('nothing is requested before consent resolves', () async {
      await build(consentOk: false);
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(state.value.isVisible, isFalse);
      expect(ad.initializeCalls, 0);
      expect(ad.loadedWidths, isEmpty);
    });

    test('a crash in the consent form leaves ads off and the app running', () async {
      await build();
      consent.throwOnGather = true;
      consent.canRequest = false;
      await state.start();
      expect(state.value.isVisible, isFalse);
    });

    test('collapses off the Live screen and returns on it', () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);

      state.setLive(live: false);
      await waitUntil(() => !state.value.isVisible);
      state.setLive(live: true);
      await waitUntil(() => state.value.isVisible);
      expect(ad.loadedWidths, hasLength(1));
    });

    test('collapses while the keyboard is up', () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);

      state.setKeyboardVisible(visible: true);
      await waitUntil(() => !state.value.isVisible);
      state.setKeyboardVisible(visible: false);
      await waitUntil(() => state.value.isVisible);
    });

    test('a new width asks for a new banner', () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);
      state.setAvailableWidth(720);
      await waitUntil(() => ad.loadedWidths.length == 2);
      expect(ad.loadedWidths, <int>[360, 720]);
    });

    test('the ad-free unlock removes the banner and never starts the SDK', () async {
      await build();
      purchase.current = const Entitlement(
        tier: EntitlementTier.adFree,
        source: EntitlementSource.purchase,
      );
      await subscription.init();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(state.value.isVisible, isFalse);
      expect(ad.initializeCalls, 0);
    });

    test('buying the unlock while a banner shows removes it', () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);

      purchase.changes.add(
        const Entitlement(
          tier: EntitlementTier.adFree,
          source: EntitlementSource.purchase,
        ),
      );
      await waitUntil(() => !state.value.isVisible);
      expect(ad.disposeCalls, greaterThan(0));
    });

    test('the ads kill switch removes the banner, and lifting it brings it back',
        () async {
      await build();
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await waitUntil(() => state.value.isVisible);

      flagSource.notifier.value = const RemoteFlags(
        killSwitches: <String, bool>{'ads': true},
      );
      await waitUntil(() => !state.value.isVisible);

      flagSource.notifier.value = RemoteFlags.defaults;
      await waitUntil(() => state.value.isVisible);
    });

    test('no fill leaves the slot collapsed', () async {
      await build();
      ad.nextHeight = 0;
      await state.start();
      state
        ..setAvailableWidth(360)
        ..setLive(live: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(state.value.isVisible, isFalse);
    });
  });

  group('UndoProvider', () {
    late List<DeletedCamera> restored;
    late List<void Function()> timerCallbacks;
    late UndoProvider undo;

    DeletedCamera deleted(String id) {
      return DeletedCamera(
        camera: testCamera(id: id),
        credentials: CameraCredentials.none,
      );
    }

    setUp(() {
      restored = <DeletedCamera>[];
      timerCallbacks = <void Function()>[];
      undo = UndoProvider(
        restore: (DeletedCamera d) async {
          restored.add(d);
          return Ok<Camera>(d.camera);
        },
        timerFactory: (Duration delay, void Function() onFire) {
          expect(delay, Limits.undoWindow);
          timerCallbacks.add(onFire);
          return Timer(const Duration(days: 1), () {});
        },
      );
    });

    tearDown(() => undo.dispose());

    test('offers a delete and restores it on undo', () async {
      undo.offer(deleted('a'));
      expect(undo.value?.camera.id, 'a');

      final Result<Camera>? result = await undo.undo();
      expect(result?.isOk, isTrue);
      expect(restored.single.camera.id, 'a');
      expect(undo.value, isNull);
    });

    test('the window closing makes the delete final', () async {
      undo.offer(deleted('a'));
      timerCallbacks.single();
      expect(undo.value, isNull);
      expect(await undo.undo(), isNull);
      expect(restored, isEmpty);
    });

    test('a second delete replaces the first offer', () async {
      undo.offer(deleted('a'));
      undo.offer(deleted('b'));
      await undo.undo();
      expect(restored.single.camera.id, 'b');
    });

    test('dismiss clears the toast', () {
      undo.offer(deleted('a'));
      undo.dismiss();
      expect(undo.value, isNull);
    });

    test('undo with nothing pending does nothing', () async {
      expect(await undo.undo(), isNull);
    });
  });

  group('PersistenceHealthProvider', () {
    test('reports degraded storage and recovery', () {
      final ValueNotifier<bool> database = ValueNotifier<bool>(false);
      final ValueNotifier<bool> prefs = ValueNotifier<bool>(false);
      final PersistenceHealthProvider health = PersistenceHealthProvider(
        sources: <ValueListenable<bool>>[database, prefs],
      );
      expect(health.value, PersistenceIssue.none);
      expect(health.hasIssue, isFalse);

      prefs.value = true;
      expect(health.value, PersistenceIssue.degraded);
      expect(health.hasIssue, isTrue);

      prefs.value = false;
      expect(health.value, PersistenceIssue.none);
      health.dispose();
    });

    test('a newer database takes priority over a plain warning', () {
      final ValueNotifier<bool> database = ValueNotifier<bool>(true);
      final PersistenceHealthProvider health = PersistenceHealthProvider(
        sources: <ValueListenable<bool>>[database],
      );
      health.markUpdateRequired();
      expect(health.value, PersistenceIssue.updateRequired);

      database.value = false;
      expect(health.value, PersistenceIssue.updateRequired);
      health.dispose();
    });

    test('works with no sources', () {
      final PersistenceHealthProvider health =
          PersistenceHealthProvider(sources: const <ValueListenable<bool>>[]);
      expect(health.value, PersistenceIssue.none);
      health.dispose();
    });
  });
}
