import 'dart:io';

import 'package:roehens/core/constants/app_constants.dart';

/// Which store the build ships to.
enum StoreName { googlePlay, appStore, amazon }

/// Everything that differs between stores. This and the other files in
/// `lib/platform/store` are the only code the Amazon fork edits.
class StoreConfig {
  const StoreConfig({
    required this.storeName,
    required this.iapSupported,
    required this.bannerUnitId,
    this.adFreeProductId = AppConstants.adFreeProductId,
    this.appStoreId,
    this.usesTestAds = true,
  });

  /// Google's published sample ad unit IDs. They always serve test ads. They are
  /// replaced by the real IDs before the first store release.
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  static const StoreConfig googlePlay = StoreConfig(
    storeName: StoreName.googlePlay,
    iapSupported: true,
    bannerUnitId: testBannerAndroid,
  );

  static const StoreConfig appStore = StoreConfig(
    storeName: StoreName.appStore,
    iapSupported: true,
    bannerUnitId: testBannerIos,
  );

  /// The configuration for the platform the app is running on.
  factory StoreConfig.current() => Platform.isIOS ? appStore : googlePlay;

  final StoreName storeName;

  /// False where the store has no in-app billing.
  final bool iapSupported;

  final String bannerUnitId;
  final String adFreeProductId;

  /// The store's numeric app ID, needed to open the listing on iOS. Unknown until
  /// the app exists in App Store Connect.
  final String? appStoreId;

  /// True while [bannerUnitId] is one of Google's sample IDs.
  final bool usesTestAds;
}
