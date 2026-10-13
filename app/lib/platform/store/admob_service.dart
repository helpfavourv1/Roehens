import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/ad_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/platform/store/store_config.dart';

/// A banner that finished loading.
class LoadedBanner {
  const LoadedBanner({
    required this.height,
    required this.view,
    required this.dispose,
  });

  final double height;
  final Object view;
  final void Function() dispose;
}

/// The one place the ads SDK is touched.
abstract interface class AdsBackend {
  Future<void> initialize();

  /// Loads an anchored adaptive banner for [widthDp]; null when it fails.
  Future<LoadedBanner?> loadBanner({required String unitId, required int widthDp});
}

class GoogleAdsBackend implements AdsBackend {
  @override
  Future<void> initialize() async {
    await ads.MobileAds.instance.initialize();
  }

  @override
  Future<LoadedBanner?> loadBanner({
    required String unitId,
    required int widthDp,
  }) async {
    // The replacement, getLargeAnchoredAdaptiveBannerAdSize, returns banners up
    // to 15% of the screen height, which can exceed the 100 dp slot and would
    // clip the ad. The older method stays until the slot design changes.
    // ignore: deprecated_member_use
    final ads.AnchoredAdaptiveBannerAdSize? size = await ads.AdSize
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthDp);
    if (size == null) {
      return null;
    }
    final Completer<LoadedBanner?> done = Completer<LoadedBanner?>();
    late final ads.BannerAd banner;
    banner = ads.BannerAd(
      size: size,
      adUnitId: unitId,
      request: const ads.AdRequest(),
      listener: ads.BannerAdListener(
        onAdLoaded: (ads.Ad ad) {
          if (!done.isCompleted) {
            done.complete(
              LoadedBanner(
                height: size.height.toDouble(),
                view: ads.AdWidget(ad: banner),
                dispose: banner.dispose,
              ),
            );
          }
        },
        onAdFailedToLoad: (ads.Ad ad, ads.LoadAdError error) {
          unawaited(ad.dispose());
          if (!done.isCompleted) {
            done.complete(null);
          }
        },
      ),
    );
    try {
      await banner.load();
    } catch (_) {
      banner.dispose();
      return null;
    }
    return done.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        banner.dispose();
        return null;
      },
    );
  }
}

/// The banner on the Live screen (specification D6 and C8.4). Anything that goes
/// wrong leaves [bannerHeight] at zero; nothing here throws.
class AdMobService implements AdContract {
  AdMobService({
    required this.config,
    AdsBackend? backend,
    this.maxHeight = Limits.bannerMaxHeight,
    this.logger,
  }) : _backend = backend ?? GoogleAdsBackend();

  final StoreConfig config;
  final double maxHeight;
  final LoggerContract? logger;
  final AdsBackend _backend;

  final ValueNotifier<double> _height = ValueNotifier<double>(0);
  LoadedBanner? _banner;
  bool _initialized = false;
  int _generation = 0;

  @override
  ValueListenable<double> get bannerHeight => _height;

  @override
  Object? get bannerView => _banner?.view;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await _backend.initialize();
      _initialized = true;
    } catch (error) {
      logger?.warning('ads', 'ads failed to start', error: error);
    }
  }

  @override
  Future<void> loadBanner({required int widthDp}) async {
    if (!_initialized || widthDp <= 0) {
      return;
    }
    final int generation = ++_generation;
    LoadedBanner? loaded;
    try {
      loaded = await _backend.loadBanner(
        unitId: config.bannerUnitId,
        widthDp: widthDp,
      );
    } catch (error) {
      logger?.warning('ads', 'banner failed to load', error: error);
    }
    if (generation != _generation) {
      // A newer request or a dispose won; this banner is stale.
      loaded?.dispose();
      return;
    }
    _replace(loaded);
  }

  void _replace(LoadedBanner? next) {
    final LoadedBanner? old = _banner;
    _banner = next;
    old?.dispose();
    final double height = next == null
        ? 0
        : (next.height > maxHeight ? maxHeight : next.height);
    _height.value = height < 0 ? 0 : height;
  }

  @override
  void disposeBanner() {
    _generation++;
    _replace(null);
  }
}
