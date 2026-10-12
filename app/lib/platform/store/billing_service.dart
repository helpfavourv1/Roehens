import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/platform/store/store_config.dart';

enum PurchaseEventKind { purchased, restored, pending, canceled, failed }

/// A change in a purchase, in the app's own terms.
class PurchaseEvent {
  const PurchaseEvent({
    required this.productId,
    required this.kind,
    this.message,
  });

  final String productId;
  final PurchaseEventKind kind;
  final String? message;
}

/// A product as the store describes it.
class BillingProduct {
  const BillingProduct({
    required this.id,
    required this.title,
    required this.priceLabel,
  });

  final String id;
  final String title;
  final String priceLabel;
}

/// The one place the billing plugin is touched.
abstract interface class BillingBackend {
  Future<bool> isAvailable();

  /// Null when the store does not know the product.
  Future<BillingProduct?> loadProduct(String productId);

  /// Starts the purchase flow; false when it could not be started.
  Future<bool> buy(String productId);

  Future<void> restore();

  Stream<PurchaseEvent> get events;
}

class StoreBillingBackend implements BillingBackend {
  StoreBillingBackend({iap.InAppPurchase? store})
      : _store = store ?? iap.InAppPurchase.instance;

  final iap.InAppPurchase _store;
  final Map<String, iap.ProductDetails> _products = <String, iap.ProductDetails>{};

  @override
  late final Stream<PurchaseEvent> events = _store.purchaseStream.asyncExpand(
    (List<iap.PurchaseDetails> updates) async* {
      for (final iap.PurchaseDetails details in updates) {
        yield PurchaseEvent(
          productId: details.productID,
          kind: _kind(details.status),
          message: details.error?.message,
        );
        if (details.pendingCompletePurchase) {
          await _store.completePurchase(details);
        }
      }
    },
  );

  static PurchaseEventKind _kind(iap.PurchaseStatus status) {
    switch (status) {
      case iap.PurchaseStatus.pending:
        return PurchaseEventKind.pending;
      case iap.PurchaseStatus.purchased:
        return PurchaseEventKind.purchased;
      case iap.PurchaseStatus.restored:
        return PurchaseEventKind.restored;
      case iap.PurchaseStatus.canceled:
        return PurchaseEventKind.canceled;
      case iap.PurchaseStatus.error:
        return PurchaseEventKind.failed;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _store.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BillingProduct?> loadProduct(String productId) async {
    final iap.ProductDetailsResponse response =
        await _store.queryProductDetails(<String>{productId});
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    for (final iap.ProductDetails product in response.productDetails) {
      if (product.id == productId) {
        _products[productId] = product;
        return BillingProduct(
          id: product.id,
          title: product.title,
          priceLabel: product.price,
        );
      }
    }
    return null;
  }

  @override
  Future<bool> buy(String productId) async {
    final iap.ProductDetails? product = _products[productId];
    if (product == null) {
      return false;
    }
    return _store.buyNonConsumable(
      purchaseParam: iap.PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restore() => _store.restorePurchases();
}

/// The one-time ad-free purchase (specification D6). A purchase or restore of
/// the ad-free product becomes an [Entitlement] on [entitlementChanges]; a
/// cancelled purchase is silent; a failed one is reported on [failures].
class BillingService implements PurchaseContract {
  BillingService({
    required this.config,
    BillingBackend? backend,
    this.clock = const SystemClock(),
    this.restoreWait = const Duration(seconds: 3),
    this.logger,
  }) : _backend = backend ?? StoreBillingBackend() {
    if (config.iapSupported) {
      _subscription = _backend.events.listen(_onEvent);
    }
  }

  final StoreConfig config;
  final ClockContract clock;

  /// How long [currentEntitlement] waits for the store to report a restore.
  final Duration restoreWait;
  final LoggerContract? logger;
  final BillingBackend _backend;

  final StreamController<Entitlement> _entitlements =
      StreamController<Entitlement>.broadcast();
  final StreamController<AppError> _failures = StreamController<AppError>.broadcast();
  StreamSubscription<PurchaseEvent>? _subscription;
  Entitlement _current = const Entitlement.free();

  @override
  bool get isSupported => config.iapSupported;

  @override
  Stream<Entitlement> get entitlementChanges => _entitlements.stream;

  @override
  Stream<AppError> get failures => _failures.stream;

  void _onEvent(PurchaseEvent event) {
    if (event.productId != config.adFreeProductId) {
      return;
    }
    switch (event.kind) {
      case PurchaseEventKind.purchased:
      case PurchaseEventKind.restored:
        _current = Entitlement(
          tier: EntitlementTier.adFree,
          source: event.kind == PurchaseEventKind.purchased
              ? EntitlementSource.purchase
              : EntitlementSource.restore,
          verifiedAt: clock.now().toUtc(),
        );
        _entitlements.add(_current);
      case PurchaseEventKind.failed:
        _failures.add(AppError(ErrorClass.purchaseFailed, detail: event.message));
      case PurchaseEventKind.pending || PurchaseEventKind.canceled:
        break;
    }
  }

  static const AppError _unavailable = AppError(
    ErrorClass.purchaseFailed,
    detail: 'the store is not available',
  );

  @override
  Future<Result<Entitlement>> currentEntitlement() async {
    if (!isSupported) {
      return const Ok<Entitlement>(Entitlement.free());
    }
    if (_current.isAdFree) {
      return Ok<Entitlement>(_current);
    }
    try {
      if (!await _backend.isAvailable()) {
        return const Err<Entitlement>(_unavailable);
      }
      final Completer<void> found = Completer<void>();
      final StreamSubscription<Entitlement> wait = _entitlements.stream.listen((_) {
        if (!found.isCompleted) {
          found.complete();
        }
      });
      await _backend.restore();
      await found.future.timeout(restoreWait, onTimeout: () {});
      await wait.cancel();
      return Ok<Entitlement>(_current);
    } catch (error) {
      logger?.warning('billing', 'could not read the entitlement', error: error);
      return const Err<Entitlement>(_unavailable);
    }
  }

  @override
  Future<Result<ProductInfo?>> loadProduct() async {
    if (!isSupported) {
      return const Ok<ProductInfo?>(null);
    }
    try {
      if (!await _backend.isAvailable()) {
        return const Err<ProductInfo?>(_unavailable);
      }
      final BillingProduct? product = await _backend.loadProduct(config.adFreeProductId);
      if (product == null) {
        return const Ok<ProductInfo?>(null);
      }
      return Ok<ProductInfo?>(
        ProductInfo(id: product.id, title: product.title, priceLabel: product.priceLabel),
      );
    } catch (error) {
      logger?.warning('billing', 'could not load the product', error: error);
      return const Err<ProductInfo?>(_unavailable);
    }
  }

  @override
  Future<Result<void>> buy() async {
    if (!isSupported) {
      return const Err<void>(_unavailable);
    }
    try {
      if (!await _backend.isAvailable()) {
        return const Err<void>(_unavailable);
      }
      final bool started = await _backend.buy(config.adFreeProductId);
      return started
          ? const Ok<void>(null)
          : const Err<void>(
              AppError(ErrorClass.purchaseFailed, detail: 'the purchase could not start'),
            );
    } catch (error) {
      logger?.warning('billing', 'could not start the purchase', error: error);
      return const Err<void>(_unavailable);
    }
  }

  @override
  Future<Result<void>> restore() async {
    if (!isSupported) {
      return const Err<void>(_unavailable);
    }
    try {
      if (!await _backend.isAvailable()) {
        return const Err<void>(_unavailable);
      }
      await _backend.restore();
      return const Ok<void>(null);
    } catch (error) {
      logger?.warning('billing', 'restore failed', error: error);
      return const Err<void>(_unavailable);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _entitlements.close();
    await _failures.close();
  }
}
