import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/core/providers/subscription_provider.dart';

import '../../support/async_helpers.dart';
import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';

void main() {
  late FakeKeyValueStore store;
  late FakeClock clock;
  late FakePurchase purchase;

  SubscriptionProvider build() {
    return SubscriptionProvider(
      purchase: purchase,
      store: store,
      clock: clock,
      logger: FakeLogger(),
    );
  }

  const Entitlement owned = Entitlement(
    tier: EntitlementTier.adFree,
    source: EntitlementSource.purchase,
  );

  setUp(() {
    store = FakeKeyValueStore();
    clock = FakeClock();
    purchase = FakePurchase();
  });

  test('a new install is free', () async {
    final SubscriptionProvider provider = build();
    await provider.init();
    expect(provider.isAdFree, isFalse);
    provider.dispose();
  });

  test(
    'the store answer unlocks ad-free and is cached with a timestamp',
    () async {
      purchase.current = owned;
      final SubscriptionProvider provider = build();
      await provider.init();

      expect(provider.isAdFree, isTrue);
      expect(provider.value.verifiedAt, clock.time);
      expect(store.values[StorageKeys.entitlement], isNotNull);
      provider.dispose();
    },
  );

  test('the cache applies when the store cannot be reached', () async {
    store.values[StorageKeys.entitlement] = jsonEncode(owned.toJson());
    purchase.failCurrent = true;
    final SubscriptionProvider provider = build();
    await provider.init();

    expect(provider.isAdFree, isTrue);
    expect(provider.value.source, EntitlementSource.cache);
    provider.dispose();
  });

  test('a refund reported by the store removes the unlock', () async {
    store.values[StorageKeys.entitlement] = jsonEncode(owned.toJson());
    purchase.current = const Entitlement.free();
    final SubscriptionProvider provider = build();
    await provider.init();

    expect(provider.isAdFree, isFalse);
    provider.dispose();
  });

  test('a purchase made later arrives through the stream', () async {
    final SubscriptionProvider provider = build();
    await provider.init();
    purchase.changes.add(owned);
    await waitUntil(() => provider.isAdFree);
    provider.dispose();
  });

  test('buying reports failures and clears them on the next try', () async {
    purchase.buyError = const AppError(ErrorClass.purchaseFailed);
    final SubscriptionProvider provider = build();
    await provider.init();

    await provider.buy();
    expect(provider.failure.value?.errorClass, ErrorClass.purchaseFailed);
    expect(provider.busy.value, isFalse);

    purchase.buyError = null;
    await provider.buy();
    expect(provider.failure.value, isNull);
    provider.dispose();
  });

  test('restore calls the store', () async {
    final SubscriptionProvider provider = build();
    await provider.init();
    await provider.restore();
    expect(purchase.restoreCalls, 1);
    provider.dispose();
  });

  test('the product and price load from the store', () async {
    final SubscriptionProvider provider = build();
    await provider.init();
    await provider.loadProduct();
    expect(provider.product.value?.priceLabel, r'$2.99');
    provider.dispose();
  });

  test('without billing the app stays free and the cache is cleared', () async {
    purchase = FakePurchase(supported: false);
    store.values[StorageKeys.entitlement] = jsonEncode(owned.toJson());
    final SubscriptionProvider provider = build();
    await provider.init();

    expect(provider.isAdFree, isFalse);
    expect(store.values.containsKey(StorageKeys.entitlement), isFalse);
    provider.dispose();
  });

  test('reset goes back to free', () async {
    purchase.current = owned;
    final SubscriptionProvider provider = build();
    await provider.init();
    await provider.reset();

    expect(provider.isAdFree, isFalse);
    expect(store.values.containsKey(StorageKeys.entitlement), isFalse);
    provider.dispose();
  });
}
