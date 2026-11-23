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
  String get fullscreenQualityHigh => 'Use high quality';

  @override
  String get fullscreenQualityLow => 'Use low quality';

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

  @override
  String get ptzSpeed => 'Speed';

  @override
  String get editAddTitle => 'Add camera';

  @override
  String get editEditTitle => 'Edit camera';

  @override
  String get editSectionCamera => 'Camera';

  @override
  String get editSectionSignIn => 'Sign-in';

  @override
  String get editSectionStreams => 'Streams';

  @override
  String get editSectionAdvanced => 'Advanced';

  @override
  String get editStreamAddress => 'Stream address';

  @override
  String get editStreamAddressHint => 'rtsp://192.168.1.10/stream0';

  @override
  String get editStreamAddressHelp =>
      'Paste a full address to fill in the fields below. A password in it is moved to secure storage.';

  @override
  String get editAddressNotUnderstood => 'That address couldn\'t be read.';

  @override
  String get editName => 'Name';

  @override
  String get editNameHint => 'Front door';

  @override
  String get editNameRequired => 'Give the camera a name.';

  @override
  String get editProtocol => 'Type';

  @override
  String get editHost => 'Address or host name';

  @override
  String get editHostHint => '192.168.1.10';

  @override
  String get editHostInvalid =>
      'Enter an IP address or host name, without spaces or slashes.';

  @override
  String get editPort => 'Port';

  @override
  String get editPortInvalid => 'Enter a port from 1 to 65535.';

  @override
  String get editUsername => 'Username';

  @override
  String get editPassword => 'Password';

  @override
  String get editShowPassword => 'Show password';

  @override
  String get editHidePassword => 'Hide password';

  @override
  String get editMainPath => 'Main stream path';

  @override
  String get editSubPath => 'Substream path (optional)';

  @override
  String get editTransport => 'Transport';

  @override
  String get transportAuto => 'Automatic';

  @override
  String get transportTcp => 'TCP';

  @override
  String get editOnvif => 'Use ONVIF';

  @override
  String get editOnvifHelp =>
      'Needed for pan and tilt. Most cameras answer on port 80 or 8000.';

  @override
  String get editOnvifPort => 'ONVIF port';

  @override
  String get editBrand => 'Brand';

  @override
  String get editBrandNone => 'Choose a brand';

  @override
  String get editModel => 'Model (optional)';

  @override
  String get editBrandPaths => 'Other paths this brand uses';

  @override
  String get editSave => 'Save';

  @override
  String get testRun => 'Test connection';

  @override
  String get testRunAgain => 'Test again';

  @override
  String get testRunning => 'Testing…';

  @override
  String get testPassed => 'The connection works.';

  @override
  String get testFailed => 'The connection didn\'t work.';

  @override
  String get testStageDns => 'Find the address';

  @override
  String get testStageTcp => 'Connect';

  @override
  String get testStageAuth => 'Sign in';

  @override
  String get testStageDescribe => 'Read the stream';

  @override
  String get testStageFirstFrame => 'First picture';

  @override
  String get testStatusPending => 'Waiting';

  @override
  String get testStatusRunning => 'Running';

  @override
  String get testStatusPassed => 'OK';

  @override
  String get testStatusFailed => 'Failed';

  @override
  String get testStatusSkipped => 'Skipped';

  @override
  String testElapsed(int millis) {
    return '$millis ms';
  }

  @override
  String get testOpenTroubleshooter => 'Open troubleshooter';

  @override
  String get testSuggestCheckHostName =>
      'Check the address for typing mistakes.';

  @override
  String get testSuggestCheckWifi =>
      'Make sure this phone and the camera are on the same Wi-Fi.';

  @override
  String get testSuggestCheckPort =>
      'Check the port. Many cameras use 554 for RTSP.';

  @override
  String get testSuggestEnableRtsp => 'Turn on RTSP in the camera settings.';

  @override
  String get testSuggestCheckCredentials => 'Check the username and password.';

  @override
  String get testSuggestTryBrandPaths => 'Try another path for this brand.';

  @override
  String get testSuggestTrySubstream => 'Try the substream, which is lighter.';

  @override
  String get testSuggestTryMjpeg =>
      'Try an MJPEG address if the camera offers one.';

  @override
  String get testSuggestOpenTroubleshooter =>
      'Open the troubleshooter for more help.';

  @override
  String get brandTitle => 'Brand';

  @override
  String get brandSearch => 'Search brands';

  @override
  String get brandNoResults => 'No brand matches';

  @override
  String get brandNoResultsHint =>
      'Choose Generic RTSP if your brand isn\'t listed.';

  @override
  String get brandVerified => 'Verified';

  @override
  String get discoveryTitle => 'Find cameras';

  @override
  String get discoveryScanning => 'Looking for cameras on your network…';

  @override
  String discoveryFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cameras found',
      one: '1 camera found',
    );
    return '$_temp0';
  }

  @override
  String get discoveryRescan => 'Scan again';

  @override
  String get discoveryNone => 'No cameras found';

  @override
  String get discoveryNoneBody =>
      'Check that this phone and the camera are on the same Wi-Fi, and that ONVIF is on in the camera.';

  @override
  String get discoveryManual => 'Add a camera by hand';

  @override
  String get discoverySourceOnvif => 'ONVIF';

  @override
  String get discoverySourceSweep => 'Network scan';

  @override
  String get discoveryDisabled => 'Camera search is switched off for now.';

  @override
  String get discoveryPermissionTitle => 'Local network access is off';

  @override
  String get discoveryPermissionBody =>
      'Roehens needs local network access to find cameras. Turn it on in Settings.';

  @override
  String get discoveryOpenSettings => 'Open Settings';

  @override
  String get ioTitle => 'Import and export';

  @override
  String get ioExportSection => 'Export';

  @override
  String get ioExportRow => 'Export camera list';

  @override
  String ioExportBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cameras, without passwords',
      one: '1 camera, without its password',
      zero: 'No cameras to export',
    );
    return '$_temp0';
  }

  @override
  String get ioImportSection => 'Import';

  @override
  String get ioImportRow => 'Import from a file';

  @override
  String get ioImportBody =>
      'Choose a camera list exported from Roehens. Passwords are not included; add them afterwards.';

  @override
  String ioPreviewSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cameras in the file',
      one: '1 camera in the file',
    );
    return '$_temp0';
  }

  @override
  String get ioItemNew => 'New';

  @override
  String get ioItemExists => 'Already saved';

  @override
  String get ioConflictSection => 'When a camera already exists';

  @override
  String get ioSkip => 'Skip';

  @override
  String get ioReplace => 'Replace';

  @override
  String get ioDuplicate => 'Keep both';

  @override
  String ioInvalidEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries could not be read and are left out',
      one: '1 entry could not be read and is left out',
    );
    return '$_temp0';
  }

  @override
  String get ioApply => 'Import';

  @override
  String ioDone(int added, int replaced, int skipped, int failed) {
    return 'Added $added, replaced $replaced, skipped $skipped, failed $failed.';
  }
}
