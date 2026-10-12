import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart' as att;
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';

/// The one place the tracking-transparency plugin is touched.
abstract interface class AttBackend {
  Future<TrackingStatus> status();

  Future<TrackingStatus> request();
}

class AppTrackingBackend implements AttBackend {
  static TrackingStatus _map(att.TrackingStatus status) {
    switch (status) {
      case att.TrackingStatus.notDetermined:
        return TrackingStatus.notDetermined;
      case att.TrackingStatus.restricted:
        return TrackingStatus.restricted;
      case att.TrackingStatus.denied:
        return TrackingStatus.denied;
      case att.TrackingStatus.authorized:
        return TrackingStatus.authorized;
      case att.TrackingStatus.notSupported:
        return TrackingStatus.notApplicable;
    }
  }

  @override
  Future<TrackingStatus> status() async {
    return _map(await att.AppTrackingTransparency.trackingAuthorizationStatus);
  }

  @override
  Future<TrackingStatus> request() async {
    return _map(await att.AppTrackingTransparency.requestTrackingAuthorization());
  }
}

/// iOS App Tracking Transparency. On Android it reports "not applicable". The
/// system prompt is only shown while the status is "not determined".
class AttService implements TrackingAuthorizationContract {
  AttService({AttBackend? backend, bool? isIos, this.logger})
      : _backend = backend ?? AppTrackingBackend(),
        _isIos = isIos ?? Platform.isIOS;

  final LoggerContract? logger;
  final AttBackend _backend;
  final bool _isIos;

  @override
  Future<TrackingStatus> currentStatus() async {
    if (!_isIos) {
      return TrackingStatus.notApplicable;
    }
    try {
      return await _backend.status();
    } catch (error) {
      logger?.warning('att', 'could not read tracking status', error: error);
      return TrackingStatus.notDetermined;
    }
  }

  @override
  Future<TrackingStatus> requestAuthorization() async {
    if (!_isIos) {
      return TrackingStatus.notApplicable;
    }
    final TrackingStatus current = await currentStatus();
    if (current != TrackingStatus.notDetermined) {
      return current;
    }
    try {
      return await _backend.request();
    } catch (error) {
      logger?.warning('att', 'tracking request failed', error: error);
      return TrackingStatus.notDetermined;
    }
  }
}
