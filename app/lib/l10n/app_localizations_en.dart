// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Roehens';

  @override
  String get tabLive => 'Live';

  @override
  String get tabCameras => 'Cameras';

  @override
  String get tabSettings => 'Settings';

  @override
  String get actionAddCamera => 'Add camera';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionBack => 'Back';

  @override
  String get liveEmptyTitle => 'No cameras yet';

  @override
  String get liveEmptyBody =>
      'Add a camera to see it here. Roehens can find cameras on your network, or you can enter one yourself.';

  @override
  String get liveFindCameras => 'Find cameras on my network';

  @override
  String get liveLayoutButton => 'Layout';

  @override
  String get liveAutoCycleStart => 'Start auto-cycle';

  @override
  String get liveAutoCycleStop => 'Stop auto-cycle';

  @override
  String livePageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get livePagePrevious => 'Previous page';

  @override
  String get livePageNext => 'Next page';

  @override
  String get statusLive => 'Live';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get statusError => 'Error';

  @override
  String get statusOffline => 'Offline';

  @override
  String ageSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds ago',
      one: '1 second ago',
    );
    return '$_temp0';
  }

  @override
  String ageMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String ageHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String ageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get errorNetworkUnreachable => 'Can\'t reach the camera';

  @override
  String get errorAuthFailed => 'Check the username or password';

  @override
  String get errorPathNotFound => 'The stream path was not found';

  @override
  String get errorUnsupportedMedia =>
      'This camera\'s video format isn\'t supported';

  @override
  String get errorLocalNetworkDenied => 'Local network access is turned off';

  @override
  String get errorStreamDropped => 'The stream dropped';

  @override
  String get errorResourcePressure => 'Too many streams for this phone';

  @override
  String get errorStorageFailure => 'Saved data couldn\'t be read or written';

  @override
  String get errorFlagDisabled => 'This feature is switched off for now';

  @override
  String get errorPurchaseFailed => 'The purchase didn\'t go through';

  @override
  String get errorInvalidFile => 'That file isn\'t a Roehens camera list';

  @override
  String get errorTransferFailed => 'The file couldn\'t be shared or opened';

  @override
  String get errorFatal => 'Something went wrong';

  @override
  String get protocolRtsp => 'RTSP';

  @override
  String get protocolMjpeg => 'MJPEG';

  @override
  String get protocolSnapshot => 'HTTP snapshot';

  @override
  String get fullscreenMute => 'Mute';

  @override
  String get fullscreenUnmute => 'Unmute';

  @override
  String get fullscreenSnapshot => 'Take snapshot';

  @override
  String get fullscreenSnapshotFailed => 'Couldn\'t capture a picture';

  @override
  String get fullscreenPtz => 'Pan and tilt';

  @override
  String get fullscreenQualityHigh => 'Switch to high quality';

  @override
  String get fullscreenQualityLow => 'Switch to low quality';

  @override
  String get fullscreenPip => 'Picture in picture';

  @override
  String get fullscreenZoomReset => 'Reset zoom';

  @override
  String fullscreenZoomLevel(String level) {
    return 'Zoom $level×';
  }

  @override
  String get fullscreenPreviousCamera => 'Previous camera';

  @override
  String get fullscreenNextCamera => 'Next camera';

  @override
  String get ptzPad => 'Pan and tilt pad';

  @override
  String get ptzHome => 'Home position';

  @override
  String get ptzZoomIn => 'Zoom in';

  @override
  String get ptzZoomOut => 'Zoom out';

  @override
  String get ptzNeedsOnvif =>
      'Turn on ONVIF for this camera to use pan and tilt.';

  @override
  String get ptzNotSupported =>
      'This camera doesn\'t report pan and tilt control.';

  @override
  String get camerasTitle => 'Cameras';

  @override
  String get camerasSearchHint => 'Search cameras';

  @override
  String get camerasEmptyTitle => 'No cameras yet';

  @override
  String get camerasEmptyBody =>
      'Add your first camera. Roehens keeps its password in the secure storage of this phone.';

  @override
  String get camerasNoResultsTitle => 'No matching cameras';

  @override
  String get camerasNoResultsBody => 'Try a different name or address.';

  @override
  String cameraDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get cameraDeleteSwipe => 'Delete';

  @override
  String get layoutTitle => 'Layout';

  @override
  String layoutPerPage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cameras per page',
      one: '1 camera per page',
    );
    return '$_temp0';
  }

  @override
  String layoutSizeLabel(int count) {
    return '$count';
  }

  @override
  String get layoutOrderSection => 'Order';

  @override
  String layoutMoveUp(String name) {
    return 'Move $name up';
  }

  @override
  String layoutMoveDown(String name) {
    return 'Move $name down';
  }

  @override
  String get layoutAutoCycleSection => 'Auto-cycle';

  @override
  String get layoutAutoCycleDefault => 'Use default';

  @override
  String layoutAutoCycleSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get layoutAutoCycleHelp =>
      'Moves to the next page after this time. Touching the screen pauses it.';

  @override
  String get persistenceDegraded =>
      'Your saved data can\'t be kept right now. Export your cameras to keep a copy.';

  @override
  String get persistenceUpdate => 'Update Roehens to open your saved data.';

  @override
  String get persistenceExport => 'Export cameras';
}
