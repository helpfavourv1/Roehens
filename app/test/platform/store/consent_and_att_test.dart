import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/platform/store/att_service.dart';
import 'package:roehens/platform/store/consent_service.dart';

class FakeConsentBackend implements ConsentBackend {
  ConsentStatus result = ConsentStatus.obtained;
  Object? updateError;
  bool canRequest = true;
  Object? canRequestError;
  bool optionsRequired = false;
  Object? optionsError;
  int optionsShown = 0;

  @override
  Future<ConsentStatus> updateAndShowFormIfRequired() async {
    final Object? error = updateError;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<bool> canRequestAds() async {
    final Object? error = canRequestError;
    if (error != null) {
      throw error;
    }
    return canRequest;
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    final Object? error = optionsError;
    if (error != null) {
      throw error;
    }
    return optionsRequired;
  }

  @override
  Future<void> showPrivacyOptions() async {
    optionsShown++;
  }
}

class FakeAttBackend implements AttBackend {
  TrackingStatus current = TrackingStatus.notDetermined;
  TrackingStatus afterRequest = TrackingStatus.authorized;
  Object? statusError;
  Object? requestError;
  int requests = 0;

  @override
  Future<TrackingStatus> status() async {
    final Object? error = statusError;
    if (error != null) {
      throw error;
    }
    return current;
  }

  @override
  Future<TrackingStatus> request() async {
    requests++;
    final Object? error = requestError;
    if (error != null) {
      throw error;
    }
    current = afterRequest;
    return afterRequest;
  }
}

void main() {
  group('ConsentService', () {
    late FakeConsentBackend backend;
    late ConsentService service;

    setUp(() {
      backend = FakeConsentBackend();
      service = ConsentService(backend: backend);
    });

    test('ads are not allowed before consent was gathered', () {
      expect(service.status, ConsentStatus.unknown);
      expect(service.canRequestAds, isFalse);
    });

    test('a resolved consent allows ads', () async {
      expect(await service.gatherConsent(), ConsentStatus.obtained);
      expect(service.status, ConsentStatus.obtained);
      expect(service.canRequestAds, isTrue);
    });

    test('a region that needs no consent also allows ads', () async {
      backend.result = ConsentStatus.notRequired;
      await service.gatherConsent();
      expect(service.status, ConsentStatus.notRequired);
      expect(service.canRequestAds, isTrue);
    });

    test('a refused consent keeps ads off when the SDK says so', () async {
      backend.result = ConsentStatus.required;
      backend.canRequest = false;
      await service.gatherConsent();
      expect(service.status, ConsentStatus.required);
      expect(service.canRequestAds, isFalse);
    });

    test('a failed update leaves the status unknown but never throws', () async {
      backend.updateError = StateError('offline');
      backend.canRequest = false;
      expect(await service.gatherConsent(), ConsentStatus.unknown);
      expect(service.canRequestAds, isFalse);
    });

    test('earlier consent still allows ads after a failed update', () async {
      backend.updateError = StateError('offline');
      backend.canRequest = true;
      await service.gatherConsent();
      expect(service.status, ConsentStatus.unknown);
      expect(service.canRequestAds, isTrue);
    });

    test('an unreadable consent state keeps ads off', () async {
      backend.canRequestError = StateError('broken');
      await service.gatherConsent();
      expect(service.canRequestAds, isFalse);
    });

    test('the privacy options entry follows the SDK and survives errors', () async {
      backend.optionsRequired = true;
      expect(await service.privacyOptionsRequired, isTrue);
      backend.optionsError = StateError('x');
      expect(await service.privacyOptionsRequired, isFalse);
    });

    test('showing the privacy options refreshes whether ads are allowed', () async {
      backend.canRequest = false;
      await service.gatherConsent();
      expect(service.canRequestAds, isFalse);
      backend.canRequest = true;
      await service.showPrivacyOptions();
      expect(backend.optionsShown, 1);
      expect(service.canRequestAds, isTrue);
    });
  });

  group('AttService', () {
    late FakeAttBackend backend;

    setUp(() => backend = FakeAttBackend());

    test('Android has nothing to ask', () async {
      final AttService service = AttService(backend: backend, isIos: false);
      expect(await service.currentStatus(), TrackingStatus.notApplicable);
      expect(await service.requestAuthorization(), TrackingStatus.notApplicable);
      expect(backend.requests, 0);
    });

    test('iOS asks once while the choice is open', () async {
      final AttService service = AttService(backend: backend, isIos: true);
      expect(await service.requestAuthorization(), TrackingStatus.authorized);
      expect(backend.requests, 1);
      expect(await service.requestAuthorization(), TrackingStatus.authorized);
      expect(backend.requests, 1);
    });

    test('a choice already made is returned without asking again', () async {
      backend.current = TrackingStatus.denied;
      final AttService service = AttService(backend: backend, isIos: true);
      expect(await service.requestAuthorization(), TrackingStatus.denied);
      expect(backend.requests, 0);
    });

    test('a restricted device is never prompted', () async {
      backend.current = TrackingStatus.restricted;
      final AttService service = AttService(backend: backend, isIos: true);
      expect(await service.requestAuthorization(), TrackingStatus.restricted);
      expect(backend.requests, 0);
    });

    test('failures never throw', () async {
      backend.statusError = StateError('x');
      final AttService service = AttService(backend: backend, isIos: true);
      expect(await service.currentStatus(), TrackingStatus.notDetermined);

      backend.statusError = null;
      backend.requestError = StateError('y');
      expect(await service.requestAuthorization(), TrackingStatus.notDetermined);
    });
  });
}
