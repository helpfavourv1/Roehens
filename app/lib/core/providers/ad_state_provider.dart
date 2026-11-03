import 'dart:async';

import 'package:roehens/core/contracts/ad_contract.dart';
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/providers/flags_provider.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/providers/subscription_provider.dart';

/// What the banner slot shows. A height of zero means the slot does not exist:
/// no gap, no border, nothing drawn (C8.4).
class AdSlotState {
  const AdSlotState({this.height = 0, this.view});

  static const AdSlotState collapsed = AdSlotState();

  final double height;

  /// The banner's platform view; only the slot widget looks inside it.
  final Object? view;

  bool get isVisible => height > 0 && view != null;

  @override
  bool operator ==(Object other) {
    return other is AdSlotState &&
        other.height == height &&
        identical(other.view, view);
  }

  @override
  int get hashCode => Object.hash(height, view);
}

/// Decides whether the banner exists. The slot is collapsed when consent is
/// unresolved, the ad SDK failed, the person owns the ad-free unlock, the `ads`
/// kill switch is on, the keyboard is up, or the screen is not Live. Ads are
/// never requested before consent resolves, and never for ad-free owners.
class AdStateProvider extends SafeValueNotifier<AdSlotState> {
  AdStateProvider({
    required this._ad,
    required this._consent,
    required this._subscription,
    required this._flags,
    required this._logger,
  }) : super(AdSlotState.collapsed) {
    _subscription.addListener(_evaluate);
    _flags.addListener(_evaluate);
    _ad.bannerHeight.addListener(_evaluate);
  }

  static const String _tag = 'ad_state';

  final AdContract _ad;
  final ConsentContract _consent;
  final SubscriptionProvider _subscription;
  final FlagsProvider _flags;
  final LoggerContract _logger;

  bool _consentResolved = false;
  bool _adsStarted = false;
  bool _starting = false;
  bool _live = false;
  bool _keyboardVisible = false;
  int _widthDp = 0;
  int _requestedWidthDp = 0;

  /// Call once the first-launch steps (onboarding, rationale, tracking prompt)
  /// are done. Gathers consent and, when allowed, starts the ads SDK.
  Future<void> start() async {
    try {
      await _consent.gatherConsent();
    } on Object catch (error) {
      _logger.warning(_tag, 'consent flow failed, ads stay off', error: error);
    }
    _consentResolved = _consent.canRequestAds;
    await _evaluateAsync();
  }

  void setLive({required bool live}) {
    _live = live;
    _evaluate();
  }

  void setKeyboardVisible({required bool visible}) {
    _keyboardVisible = visible;
    _evaluate();
  }

  /// The width the banner can use; a new width asks for a new banner.
  void setAvailableWidth(int widthDp) {
    _widthDp = widthDp;
    _evaluate();
  }

  bool get _suppressed =>
      _subscription.isAdFree || !_flags.isEnabled(RemoteFlagKeys.ads);

  void _evaluate() {
    unawaited(_evaluateAsync());
  }

  Future<void> _evaluateAsync() async {
    if (isDisposed) {
      return;
    }
    if (_suppressed) {
      if (_requestedWidthDp != 0) {
        _ad.disposeBanner();
        _requestedWidthDp = 0;
      }
      setIfAlive(AdSlotState.collapsed);
      return;
    }
    if (!_consentResolved) {
      setIfAlive(AdSlotState.collapsed);
      return;
    }
    if (!_adsStarted && !_starting) {
      _starting = true;
      await _ad.initialize();
      _adsStarted = true;
      _starting = false;
    }
    if (!_adsStarted) {
      return;
    }
    final bool wanted = _live && !_keyboardVisible && _widthDp > 0;
    if (wanted && _requestedWidthDp != _widthDp) {
      _requestedWidthDp = _widthDp;
      await _ad.loadBanner(widthDp: _widthDp);
    }
    if (isDisposed) {
      return;
    }
    final double height = _ad.bannerHeight.value;
    final Object? view = _ad.bannerView;
    setIfAlive(
      wanted && height > 0 && view != null
          ? AdSlotState(height: height, view: view)
          : AdSlotState.collapsed,
    );
  }

  @override
  void dispose() {
    _subscription.removeListener(_evaluate);
    _flags.removeListener(_evaluate);
    _ad.bannerHeight.removeListener(_evaluate);
    _ad.disposeBanner();
    super.dispose();
  }
}
