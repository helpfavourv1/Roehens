/// Result of the consent flow.
enum ConsentStatus { unknown, required, notRequired, obtained }

/// iOS app tracking authorization.
enum TrackingStatus { notDetermined, restricted, denied, authorized, notApplicable }

/// User Messaging Platform consent. Ads never load before consent resolves.
abstract interface class ConsentContract {
  ConsentStatus get status;

  /// Whether ads may be requested now.
  bool get canRequestAds;

  /// Gathers consent where the person's region requires it. Never throws; on
  /// failure the status stays [ConsentStatus.unknown] and ads stay off.
  Future<ConsentStatus> gatherConsent();

  /// Whether a privacy-options entry must be offered in Settings.
  Future<bool> get privacyOptionsRequired;

  Future<void> showPrivacyOptions();
}

/// App Tracking Transparency. On Android this reports
/// [TrackingStatus.notApplicable].
abstract interface class TrackingAuthorizationContract {
  Future<TrackingStatus> currentStatus();

  /// Shows the system prompt once; returns the resulting status.
  Future<TrackingStatus> requestAuthorization();
}
