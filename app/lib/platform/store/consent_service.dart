import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';

/// The one place the consent SDK (Google's User Messaging Platform) is touched.
abstract interface class ConsentBackend {
  /// Updates the consent information and shows the form where one is required.
  /// Returns the resulting status; throws when the update fails.
  Future<ConsentStatus> updateAndShowFormIfRequired();

  Future<bool> canRequestAds();

  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

class GoogleConsentBackend implements ConsentBackend {
  @override
  Future<ConsentStatus> updateAndShowFormIfRequired() async {
    final Completer<void> updated = Completer<void>();
    ads.ConsentInformation.instance.requestConsentInfoUpdate(
      ads.ConsentRequestParameters(),
      () {
        if (!updated.isCompleted) {
          updated.complete();
        }
      },
      (ads.FormError error) {
        if (!updated.isCompleted) {
          updated.completeError(StateError(error.message));
        }
      },
    );
    await updated.future;

    final Completer<void> dismissed = Completer<void>();
    await ads.ConsentForm.loadAndShowConsentFormIfRequired((ads.FormError? error) {
      if (!dismissed.isCompleted) {
        dismissed.complete();
      }
    });
    await dismissed.future.timeout(const Duration(minutes: 10), onTimeout: () {});

    switch (await ads.ConsentInformation.instance.getConsentStatus()) {
      case ads.ConsentStatus.notRequired:
        return ConsentStatus.notRequired;
      case ads.ConsentStatus.obtained:
        return ConsentStatus.obtained;
      case ads.ConsentStatus.required:
        return ConsentStatus.required;
      case ads.ConsentStatus.unknown:
        return ConsentStatus.unknown;
    }
  }

  @override
  Future<bool> canRequestAds() => ads.ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async {
    final ads.PrivacyOptionsRequirementStatus status =
        await ads.ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == ads.PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptions() async {
    final Completer<void> dismissed = Completer<void>();
    await ads.ConsentForm.showPrivacyOptionsForm((ads.FormError? error) {
      if (!dismissed.isCompleted) {
        dismissed.complete();
      }
    });
    await dismissed.future.timeout(const Duration(minutes: 10), onTimeout: () {});
  }
}

/// Consent before ads (specification D6). Ads stay off until [canRequestAds];
/// a failed update leaves the status unknown and never throws.
class ConsentService implements ConsentContract {
  ConsentService({ConsentBackend? backend, this.logger})
      : _backend = backend ?? GoogleConsentBackend();

  final LoggerContract? logger;
  final ConsentBackend _backend;

  ConsentStatus _status = ConsentStatus.unknown;
  bool _canRequest = false;

  @override
  ConsentStatus get status => _status;

  @override
  bool get canRequestAds => _canRequest;

  @override
  Future<ConsentStatus> gatherConsent() async {
    try {
      _status = await _backend.updateAndShowFormIfRequired();
    } catch (error) {
      logger?.warning('consent', 'consent update failed', error: error);
      _status = ConsentStatus.unknown;
    }
    try {
      // Consent given in an earlier session may still allow ads after a failure.
      _canRequest = await _backend.canRequestAds();
    } catch (error) {
      logger?.warning('consent', 'could not read consent state', error: error);
      _canRequest = false;
    }
    return _status;
  }

  @override
  Future<bool> get privacyOptionsRequired async {
    try {
      return await _backend.privacyOptionsRequired();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await _backend.showPrivacyOptions();
      _canRequest = await _backend.canRequestAds();
    } catch (error) {
      logger?.warning('consent', 'privacy options failed', error: error);
    }
  }
}
