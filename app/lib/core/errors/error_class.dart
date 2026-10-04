/// Every failure the app can show, with its treatment (specification D5).
///
/// [messageKey] is the localization key of the plain-language message.
/// [retriable] says whether the person (or the app) can try again;
/// [autoRetry] says whether the app retries on its own with backoff.
enum ErrorClass {
  /// Host down, wrong Wi-Fi, timeout.
  networkUnreachable(
    messageKey: 'errorNetworkUnreachable',
    retriable: true,
    autoRetry: true,
  ),

  /// HTTP or RTSP 401 and 403.
  authFailed(messageKey: 'errorAuthFailed', retriable: false, autoRetry: false),

  /// RTSP 404 or a wrong path.
  pathNotFound(
    messageKey: 'errorPathNotFound',
    retriable: false,
    autoRetry: false,
  ),

  /// Codec or container the engine cannot play.
  unsupportedMedia(
    messageKey: 'errorUnsupportedMedia',
    retriable: false,
    autoRetry: false,
  ),

  /// iOS local network permission is off.
  localNetworkDenied(
    messageKey: 'errorLocalNetworkDenied',
    retriable: false,
    autoRetry: false,
  ),

  /// A Wi-Fi blip; the tile shows "Reconnecting" and no dialog.
  streamDropped(
    messageKey: 'errorStreamDropped',
    retriable: true,
    autoRetry: true,
  ),

  /// Too many streams for the device; tiles degrade to posters.
  resourcePressure(
    messageKey: 'errorResourcePressure',
    retriable: false,
    autoRetry: false,
  ),

  /// Database or vault failure.
  storageFailure(
    messageKey: 'errorStorageFailure',
    retriable: false,
    autoRetry: false,
  ),

  /// A remote kill switch is on.
  flagDisabled(
    messageKey: 'errorFlagDisabled',
    retriable: false,
    autoRetry: false,
  ),

  /// Store billing error; retry is manual and restore stays available.
  purchaseFailed(
    messageKey: 'errorPurchaseFailed',
    retriable: true,
    autoRetry: false,
  ),

  /// Anything unhandled.
  fatal(messageKey: 'errorFatal', retriable: false, autoRetry: false);

  const ErrorClass({
    required this.messageKey,
    required this.retriable,
    required this.autoRetry,
  });

  final String messageKey;
  final bool retriable;
  final bool autoRetry;
}
