import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/platform/store/store_config.dart';

void main() {
  test('the ad units are Google sample units until real ones exist', () {
    // Google's published sample publisher; these always serve test ads.
    const String samplePublisher = 'ca-app-pub-3940256099942544/';
    expect(StoreConfig.googlePlay.bannerUnitId, '${samplePublisher}6300978111');
    expect(StoreConfig.appStore.bannerUnitId, '${samplePublisher}2934735716');
    expect(StoreConfig.googlePlay.usesTestAds, isTrue);
    expect(StoreConfig.appStore.usesTestAds, isTrue);
  });

  test('both stores sell the same ad-free product', () {
    expect(StoreConfig.googlePlay.adFreeProductId, AppConstants.adFreeProductId);
    expect(StoreConfig.appStore.adFreeProductId, 'com.zdmgold.roehens.adfree');
    expect(StoreConfig.googlePlay.iapSupported, isTrue);
    expect(StoreConfig.appStore.iapSupported, isTrue);
  });

  test('the stores are told apart and the App Store ID is not invented', () {
    expect(StoreConfig.googlePlay.storeName, StoreName.googlePlay);
    expect(StoreConfig.appStore.storeName, StoreName.appStore);
    expect(StoreConfig.googlePlay.appStoreId, isNull);
    expect(StoreConfig.appStore.appStoreId, isNull);
  });

  test('the current configuration follows the platform', () {
    // Tests run on a desktop host, which is treated like Android.
    expect(StoreConfig.current().storeName, StoreName.googlePlay);
  });
}
