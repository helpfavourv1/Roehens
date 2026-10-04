/// State of a permission as the app sees it.
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notRequired,
  unknown,
}

/// The iOS local network permission. On Android it reports
/// [PermissionStatus.notRequired].
abstract interface class PermissionContract {
  Future<PermissionStatus> localNetworkStatus();

  /// Triggers the system prompt where there is one.
  Future<PermissionStatus> requestLocalNetwork();

  /// Opens the phone's own Settings page for this app.
  Future<bool> openAppSettings();
}
