/// Keys for key-value storage and the secure vault. Changing a key orphans the
/// stored value, so keys are append-only.
class StorageKeys {
  StorageKeys._();

  // Key-value store (shared preferences).
  static const String settings = 'settings';
  static const String onboarding = 'onboarding';
  static const String activeLayoutId = 'active_layout_id';
  static const String flagsCache = 'flags_cache';
  static const String flagsFetchedAtMillis = 'flags_fetched_at_millis';
  static const String entitlement = 'entitlement';
  static const String ratingState = 'rating_state';

  // Secure vault. The camera id is appended: `camera_credentials_<id>`.
  static const String vaultCredentialsPrefix = 'camera_credentials_';

  static String vaultKeyForCamera(String cameraId) {
    return '$vaultCredentialsPrefix$cameraId';
  }
}
