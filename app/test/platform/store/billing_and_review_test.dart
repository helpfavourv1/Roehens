import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/platform/store/billing_service.dart';
import 'package:roehens/platform/store/review_service.dart';
import 'package:roehens/platform/store/store_config.dart';

import '../../support/fakes.dart';

class FakeBillingBackend implements BillingBackend {
  bool available = true;
  BillingProduct? product = const BillingProduct(
    id: 'com.zdmgold.roehens.adfree',
    title: 'Roehens ad-free',
    priceLabel: r'$4.99',
  );
  Object? loadError;
  bool startsPurchase = true;
  int restores = 0;
  int buys = 0;
  PurchaseEvent? onRestore;
  final StreamController<PurchaseEvent> controller =
      StreamController<PurchaseEvent>.broadcast();

  @override
  Stream<PurchaseEvent> get events => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BillingProduct?> loadProduct(String productId) async {
    final Object? error = loadError;
    if (error != null) {
      throw error;
    }
    return product;
  }

  @override
  Future<bool> buy(String productId) async {
    buys++;
    return startsPurchase;
  }

  @override
  Future<void> restore() async {
    restores++;
    final PurchaseEvent? event = onRestore;
    if (event != null) {
      controller.add(event);
    }
  }
}

const String productId = 'com.zdmgold.roehens.adfree';

PurchaseEvent event(PurchaseEventKind kind, {String id = productId, String? message}) {
  return PurchaseEvent(productId: id, kind: kind, message: message);
}

class FakeReviewBackend implements ReviewBackend {
  bool available = true;
  Object? error;
  int requests = 0;
  final List<String?> opened = <String?>[];

  @override
  Future<bool> isAvailable() async {
    if (error != null) {
      throw error!;
    }
    return available;
  }

  @override
  Future<void> requestReview() async {
    requests++;
  }

  @override
  Future<void> openStoreListing({String? appStoreId}) async {
    if (error != null) {
      throw error!;
    }
    opened.add(appStoreId);
  }
}

void main() {
  group('BillingService', () {
    late FakeBillingBackend backend;
    late FakeClock clock;
    late BillingService service;

    setUp(() {
      backend = FakeBillingBackend();
      clock = FakeClock();
      service = BillingService(
        config: StoreConfig.googlePlay,
        backend: backend,
        clock: clock,
        restoreWait: const Duration(milliseconds: 60),
      );
    });

    tearDown(() => service.dispose());

    test('a store without billing offers nothing', () async {
      final BillingService none = BillingService(
        config: const StoreConfig(
          storeName: StoreName.amazon,
          iapSupported: false,
          bannerUnitId: 'x',
        ),
        backend: backend,
      );
      expect(none.isSupported, isFalse);
      expect((await none.currentEntitlement()).valueOrNull!.isAdFree, isFalse);
      expect((await none.loadProduct()).valueOrNull, isNull);
      expect((await none.buy()).errorOrNull!.errorClass, ErrorClass.purchaseFailed);
      expect((await none.restore()).isErr, isTrue);
      expect(backend.buys, 0);
      await none.dispose();
    });

    group('product and purchase', () {
      test('the product comes with its price', () async {
        final ProductInfo info = (await service.loadProduct()).valueOrNull!;
        expect(info.id, productId);
        expect(info.priceLabel, r'$4.99');
      });

      test('a product the store does not know is not an error', () async {
        backend.product = null;
        expect((await service.loadProduct()).valueOrNull, isNull);
        expect((await service.loadProduct()).isOk, isTrue);
      });

      test('an unavailable store is an error', () async {
        backend.available = false;
        expect((await service.loadProduct()).isErr, isTrue);
        expect((await service.buy()).isErr, isTrue);
        expect((await service.restore()).isErr, isTrue);
        expect((await service.currentEntitlement()).isErr, isTrue);
      });

      test('a store that throws is an error, not a crash', () async {
        backend.loadError = StateError('boom');
        expect((await service.loadProduct()).errorOrNull!.errorClass, ErrorClass.purchaseFailed);
      });

      test('buying starts the flow', () async {
        expect((await service.buy()).isOk, isTrue);
        expect(backend.buys, 1);
      });

      test('a flow that cannot start is an error', () async {
        backend.startsPurchase = false;
        expect((await service.buy()).errorOrNull!.errorClass, ErrorClass.purchaseFailed);
      });
    });

    group('events', () {
      test('a purchase becomes an ad-free entitlement', () async {
        final Future<Entitlement> next = service.entitlementChanges.first;
        backend.controller.add(event(PurchaseEventKind.purchased));
        final Entitlement entitlement = await next;
        expect(entitlement.isAdFree, isTrue);
        expect(entitlement.source, EntitlementSource.purchase);
        expect(entitlement.verifiedAt, clock.time);
      });

      test('a restore becomes an entitlement from a restore', () async {
        final Future<Entitlement> next = service.entitlementChanges.first;
        backend.controller.add(event(PurchaseEventKind.restored));
        expect((await next).source, EntitlementSource.restore);
      });

      test('other products are ignored', () async {
        final List<Entitlement> seen = <Entitlement>[];
        service.entitlementChanges.listen(seen.add);
        backend.controller.add(event(PurchaseEventKind.purchased, id: 'something.else'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(seen, isEmpty);
      });

      test('a cancelled or pending purchase is silent', () async {
        final List<Object> seen = <Object>[];
        service.entitlementChanges.listen(seen.add);
        service.failures.listen(seen.add);
        backend.controller.add(event(PurchaseEventKind.canceled));
        backend.controller.add(event(PurchaseEventKind.pending));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(seen, isEmpty);
      });

      test('a failed purchase is reported', () async {
        final Future<AppError> next = service.failures.first;
        backend.controller.add(event(PurchaseEventKind.failed, message: 'card declined'));
        final AppError error = await next;
        expect(error.errorClass, ErrorClass.purchaseFailed);
        expect(error.detail, 'card declined');
      });
    });

    group('current entitlement', () {
      test('is free when the store has nothing to restore', () async {
        final Entitlement entitlement = (await service.currentEntitlement()).valueOrNull!;
        expect(entitlement.isAdFree, isFalse);
        expect(backend.restores, 1);
      });

      test('picks up a purchase the store restores', () async {
        backend.onRestore = event(PurchaseEventKind.restored);
        final Entitlement entitlement = (await service.currentEntitlement()).valueOrNull!;
        expect(entitlement.isAdFree, isTrue);
        expect(entitlement.source, EntitlementSource.restore);
      });

      test('once ad-free it answers without asking the store again', () async {
        backend.controller.add(event(PurchaseEventKind.purchased));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect((await service.currentEntitlement()).valueOrNull!.isAdFree, isTrue);
        expect(backend.restores, 0);
      });
    });

    test('restore asks the store', () async {
      expect((await service.restore()).isOk, isTrue);
      expect(backend.restores, 1);
    });
  });

  group('ReviewService', () {
    late FakeReviewBackend backend;

    setUp(() => backend = FakeReviewBackend());

    test('the prompt is requested when available', () async {
      await ReviewService(config: StoreConfig.googlePlay, backend: backend).requestReview();
      expect(backend.requests, 1);
    });

    test('no prompt when the store says it is unavailable', () async {
      backend.available = false;
      await ReviewService(config: StoreConfig.googlePlay, backend: backend).requestReview();
      expect(backend.requests, 0);
    });

    test('a failing store never throws', () async {
      backend.error = StateError('boom');
      final ReviewService service =
          ReviewService(config: StoreConfig.googlePlay, backend: backend);
      expect(await service.isAvailable, isFalse);
      await service.requestReview();
      await service.openStoreListing();
    });

    test('Google Play opens the listing without an App Store ID', () async {
      await ReviewService(config: StoreConfig.googlePlay, backend: backend).openStoreListing();
      expect(backend.opened, <String?>[null]);
    });

    test('the App Store listing needs its ID and is skipped until it is known', () async {
      await ReviewService(config: StoreConfig.appStore, backend: backend).openStoreListing();
      expect(backend.opened, isEmpty);

      const StoreConfig known = StoreConfig(
        storeName: StoreName.appStore,
        iapSupported: true,
        bannerUnitId: 'x',
        appStoreId: '123456789',
      );
      await ReviewService(config: known, backend: backend).openStoreListing();
      expect(backend.opened, <String?>['123456789']);
    });
  });
}
