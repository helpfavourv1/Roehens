import 'package:in_app_review/in_app_review.dart' as review;
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/review_contract.dart';
import 'package:roehens/platform/store/store_config.dart';

/// The one place the review plugin is touched.
abstract interface class ReviewBackend {
  Future<bool> isAvailable();

  Future<void> requestReview();

  Future<void> openStoreListing({String? appStoreId});
}

class InAppReviewBackend implements ReviewBackend {
  final review.InAppReview _review = review.InAppReview.instance;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing({String? appStoreId}) {
    return _review.openStoreListing(appStoreId: appStoreId);
  }
}

/// Asks the store for its rating prompt, or opens the listing. Nothing here
/// throws; the store decides whether the prompt actually shows.
class ReviewService implements ReviewContract {
  ReviewService({required this.config, ReviewBackend? backend, this.logger})
      : _backend = backend ?? InAppReviewBackend();

  final StoreConfig config;
  final LoggerContract? logger;
  final ReviewBackend _backend;

  @override
  Future<bool> get isAvailable async {
    try {
      return await _backend.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestReview() async {
    try {
      if (await isAvailable) {
        await _backend.requestReview();
      }
    } catch (error) {
      logger?.warning('review', 'review prompt failed', error: error);
    }
  }

  @override
  Future<void> openStoreListing() async {
    if (config.storeName == StoreName.appStore && config.appStoreId == null) {
      logger?.warning('review', 'the App Store ID is not known yet');
      return;
    }
    try {
      await _backend.openStoreListing(appStoreId: config.appStoreId);
    } catch (error) {
      logger?.warning('review', 'could not open the store listing', error: error);
    }
  }
}
