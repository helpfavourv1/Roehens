import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// What the person owns: the free app with ads, or the ad-free unlock. The ad
/// slot reads this. The cached answer is used at once and replaced when the
/// store answers; if the store cannot be reached the cache stays.
class SubscriptionProvider extends SafeValueNotifier<Entitlement> {
  SubscriptionProvider({
    required this._purchase,
    required this._store,
    required this._clock,
    required this._logger,
  }) : super(const Entitlement.free());

  static const String _tag = 'subscription';

  final PurchaseContract _purchase;
  final KeyValueStore _store;
  final ClockContract _clock;
  final LoggerContract _logger;

  /// The product and its store price, once loaded.
  final ValueNotifier<ProductInfo?> product = ValueNotifier<ProductInfo?>(null);

  /// The last purchase failure, for an inline message on the upgrade screen.
  final ValueNotifier<AppError?> failure = ValueNotifier<AppError?>(null);

  /// True while a purchase or restore is in progress.
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  StreamSubscription<Entitlement>? _changes;
  StreamSubscription<AppError>? _failures;

  bool get isAdFree => value.isAdFree;

  Future<void> init() async {
    if (!_purchase.isSupported) {
      // No billing in this build: the app stays free for good.
      await _store.remove(StorageKeys.entitlement);
      return;
    }
    await _loadCache();
    _changes = _purchase.entitlementChanges.listen(_apply);
    _failures = _purchase.failures.listen((AppError error) {
      failure.value = error;
      busy.value = false;
    });
    final Result<Entitlement> current = await _purchase.currentEntitlement();
    final Entitlement? entitlement = current.valueOrNull;
    if (entitlement != null) {
      await _apply(entitlement);
    } else {
      _logger.warning(_tag, 'store did not answer, keeping the cached entitlement');
    }
  }

  Future<void> loadProduct() async {
    final Result<ProductInfo?> result = await _purchase.loadProduct();
    product.value = result.valueOrNull;
  }

  Future<void> buy() => _run(_purchase.buy);

  Future<void> restore() => _run(_purchase.restore);

  /// "Delete all local data": back to free until the store says otherwise.
  Future<void> reset() async {
    setIfAlive(const Entitlement.free());
    await _store.remove(StorageKeys.entitlement);
  }

  Future<void> _run(Future<Result<void>> Function() action) async {
    failure.value = null;
    busy.value = true;
    final Result<void> result = await action();
    final AppError? error = result.errorOrNull;
    if (error != null) {
      failure.value = error;
    }
    busy.value = false;
  }

  Future<void> _loadCache() async {
    final String? raw =
        (await _store.getString(StorageKeys.entitlement)).valueOrNull;
    if (raw == null) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        final Entitlement cached = Entitlement.fromJson(decoded);
        if (cached.isAdFree) {
          setIfAlive(
            Entitlement(
              tier: cached.tier,
              source: EntitlementSource.cache,
              verifiedAt: cached.verifiedAt,
            ),
          );
        }
      }
    } on Object {
      // A damaged cache is the same as none.
    }
  }

  Future<void> _apply(Entitlement entitlement) async {
    final Entitlement stamped = entitlement.verifiedAt == null
        ? Entitlement(
            tier: entitlement.tier,
            source: entitlement.source,
            verifiedAt: _clock.now().toUtc(),
          )
        : entitlement;
    setIfAlive(stamped);
    await _store.setString(StorageKeys.entitlement, jsonEncode(stamped.toJson()));
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    unawaited(_failures?.cancel());
    product.dispose();
    failure.dispose();
    busy.dispose();
    super.dispose();
  }
}
