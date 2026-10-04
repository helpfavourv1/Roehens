import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/entitlement.dart';

/// The ad-free product as the store describes it.
class ProductInfo {
  const ProductInfo({
    required this.id,
    required this.title,
    required this.priceLabel,
  });

  final String id;
  final String title;

  /// Price formatted by the store, in the person's currency.
  final String priceLabel;
}

/// One-time ad-free purchase. Restore is always available.
abstract interface class PurchaseContract {
  /// False where the store has no billing (for example the Amazon build).
  bool get isSupported;

  /// Entitlement changes: after a purchase, a restore, or a refund.
  Stream<Entitlement> get entitlementChanges;

  /// What the store reports for this account.
  Future<Result<Entitlement>> currentEntitlement();

  /// Null when the product is not available in the store.
  Future<Result<ProductInfo?>> loadProduct();

  Future<Result<void>> buy();

  Future<Result<void>> restore();
}
