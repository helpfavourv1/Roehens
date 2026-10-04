import 'package:flutter/foundation.dart';

/// The adaptive banner on the Live screen. Everything that can go wrong
/// (initialization, loading, no fill) leaves [bannerHeight] at zero and never
/// throws, so the slot collapses and the app carries on.
abstract interface class AdContract {
  /// Starts the ads SDK. Called only after consent is resolved.
  Future<void> initialize();

  /// Reserved height of the loaded banner in logical pixels; zero when there is
  /// nothing to show. Capped at the slot maximum by the implementation.
  ValueListenable<double> get bannerHeight;

  /// Requests a banner for the given available width.
  Future<void> loadBanner({required int widthDp});

  /// The platform view for the banner, or null. Opaque to everything except
  /// the banner slot widget, which checks that it is a widget before use.
  Object? get bannerView;

  /// Releases the banner.
  void disposeBanner();
}
