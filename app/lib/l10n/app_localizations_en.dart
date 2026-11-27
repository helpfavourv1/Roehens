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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupViewing => 'Viewing';

  @override
  String get settingsGroupCameras => 'Cameras';

  @override
  String get settingsGroupApp => 'Roehens';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsAutoCycle => 'Auto-cycle';

  @override
  String get settingsAutoCycleInterval => 'Auto-cycle interval';

  @override
  String get settingsTransport => 'RTSP transport';

  @override
  String get settingsKeepAwake => 'Keep the screen on while viewing';

  @override
  String get settingsHaptics => 'Vibration feedback';

  @override
  String get settingsOverlayLabels => 'Show camera names on tiles';

  @override
  String get settingsGridSubstream => 'Use the lighter stream in the grid';

  @override
  String get settingsGridSubstreamHelp =>
      'The grid plays each camera\'s substream and fullscreen plays the main stream.';

  @override
  String get settingsImportExport => 'Import and export';

  @override
  String get settingsUpgrade => 'Remove ads';

  @override
  String get settingsUpgradeOwned => 'Ads are removed. Thank you.';

  @override
  String get settingsRestore => 'Restore purchase';

  @override
  String get settingsRestoreDone => 'Purchase checked.';

  @override
  String get settingsRate => 'Rate Roehens';

  @override
  String get settingsFeedback => 'Send feedback';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDeleteAll => 'Delete all local data';

  @override
  String get settingsDeleteAllHelp =>
      'Removes cameras, saved passwords, settings and the log from this phone.';

  @override
  String get settingsDeleteConfirmTitle => 'Delete everything on this phone?';

  @override
  String get settingsDeleteConfirmBody =>
      'All cameras, saved passwords and settings will be removed. This cannot be undone.';

  @override
  String get settingsDeleteConfirm => 'Delete everything';

  @override
  String get settingsDeleteCancel => 'Cancel';

  @override
  String get settingsDeleted => 'Everything was deleted.';

  @override
  String get settingsHelp => 'Help';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceHelp =>
      'Dark makes video stand out. System follows your phone.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSearch => 'Search languages';

  @override
  String get languageNoMatch => 'No language matches';

  @override
  String get upgradeTitle => 'Remove ads';

  @override
  String get upgradeHeadline => 'One purchase, no more ads';

  @override
  String get upgradeBody =>
      'Roehens shows one small banner on the Live screen. Buy once to remove it for good on this store account.';

  @override
  String get upgradeBenefitBanner => 'No banner on the Live screen';

  @override
  String get upgradeBenefitOnce => 'Paid once, not a subscription';

  @override
  String get upgradeBenefitSame => 'Every feature stays free';

  @override
  String upgradeBuy(String price) {
    return 'Remove ads for $price';
  }

  @override
  String get upgradePriceUnavailable => 'The price is not available right now.';

  @override
  String get upgradeOwned =>
      'Ads are removed. Thank you for supporting Roehens.';

  @override
  String get upgradeRestore => 'Restore purchase';

  @override
  String get upgradeUnavailable =>
      'Purchases are not available on this device.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingTagline =>
      'Every camera on your network, one calm screen.';

  @override
  String get onboardingOneTitle => 'All your cameras in one place';

  @override
  String get onboardingOneBody =>
      'Watch IP cameras and recorders side by side, take snapshots, and steer cameras that can pan and tilt.';

  @override
  String get onboardingOnePointOne => 'RTSP and MJPEG, including H.265';

  @override
  String get onboardingOnePointTwo => 'Finds cameras on your Wi-Fi';

  @override
  String get onboardingTwoTitle => 'Made for your home network';

  @override
  String get onboardingTwoBody =>
      'Roehens talks straight to your cameras. There is no account and no cloud, and your passwords stay on this phone.';

  @override
  String get onboardingTwoPointOne => 'Works while Roehens is open on screen';

  @override
  String get onboardingTwoPointTwo =>
      'Away from home, use your own VPN or port forward';

  @override
  String get onboardingThreeTitle => 'Ready when you are';

  @override
  String get onboardingThreeBody =>
      'Add a camera by hand, or let Roehens look for cameras on this network.';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get rationaleTitle => 'Find cameras on your network';

  @override
  String get rationaleBody =>
      'To find your cameras and play their video, Roehens needs to talk to devices on your home Wi-Fi.';

  @override
  String get rationaleReasonOne => 'Looks for cameras on this network';

  @override
  String get rationaleReasonTwo => 'Streams video from them to this phone';

  @override
  String get rationaleReasonThree => 'Nothing leaves your network';

  @override
  String get rationaleContinue => 'Continue';

  @override
  String get rationaleNotNow => 'Not now';

  @override
  String get rationaleDeniedTitle => 'Local network access is off';

  @override
  String get rationaleDeniedBody =>
      'Turn it on in Settings so Roehens can find and play your cameras.';

  @override
  String get rationaleOpenSettings => 'Open Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutWhileOpen =>
      'Roehens works while it is open on screen. It does not watch your cameras or send alerts when it is closed.';

  @override
  String get aboutNoMail => 'No mail app could be opened.';

  @override
  String get feedbackSubject => 'Roehens feedback';

  @override
  String get feedbackAttachTitle => 'Attach diagnostics?';

  @override
  String get feedbackAttachBody =>
      'Diagnostics list app and phone versions, settings, the kinds of cameras you have (never their addresses or passwords) and recent log lines. You see them in the mail before you send it.';

  @override
  String get feedbackAttach => 'Attach diagnostics';

  @override
  String get feedbackWithout => 'Send without';

  @override
  String get licensesTitle => 'Open-source licenses';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenses',
      one: '1 license',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty => 'No license information is available.';

  @override
  String get fatalTitle => 'Something went wrong';

  @override
  String get fatalBody =>
      'Roehens hit a problem it could not recover from. Your cameras and settings are safe.';

  @override
  String get fatalRetry => 'Try again';

  @override
  String get fatalReport => 'Report this';

  @override
  String get fatalReportSubject => 'Roehens problem report';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpHubSameWifiTitle => 'Same Wi-Fi';

  @override
  String get helpHubSameWifiBody => 'Set up a camera on your home network.';

  @override
  String get helpHubAwayTitle => 'Away from home';

  @override
  String get helpHubAwayBody =>
      'Reach your cameras from anywhere, step by step.';

  @override
  String get helpHubTroubleTitle => 'Troubleshoot';

  @override
  String get helpHubTroubleBody =>
      'Answer a few questions to find the problem.';

  @override
  String get helpHubDiagnosticsTitle => 'Diagnostics';

  @override
  String get helpHubDiagnosticsBody => 'Check this phone, a name or a port.';

  @override
  String get helpArticlesSameWifi => 'Same Wi-Fi';

  @override
  String get helpArticlesAway => 'Away from home';

  @override
  String get helpDisabled => 'Some help is switched off for now.';

  @override
  String get helpUnavailable => 'Help couldn\'t be loaded.';

  @override
  String get helpCopy => 'Copy';

  @override
  String get helpCopied => 'Copied';

  @override
  String helpStepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get helpTargetAddCamera => 'Add a camera';

  @override
  String get helpTargetFindCameras => 'Find cameras';

  @override
  String get helpTargetDiagnostics => 'Open Diagnostics';

  @override
  String get helpTargetTroubleshooter => 'Open the troubleshooter';

  @override
  String get helpTargetPhoneSettings => 'Open phone Settings';

  @override
  String helpTargetArticle(String title) {
    return 'Read: $title';
  }

  @override
  String get wizardTitle => 'Away from home';

  @override
  String get wizardChoosePath => 'Choose a way to reach your cameras';

  @override
  String get wizardCameraSection => 'Camera to test';

  @override
  String get wizardAddress => 'Address to test';

  @override
  String get wizardPort => 'Port to test';

  @override
  String get wizardTestStep => 'Test this step';

  @override
  String get wizardTesting => 'Testing…';

  @override
  String get wizardTestPassed => 'It works.';

  @override
  String get wizardTestFailed => 'Not working yet.';

  @override
  String get wizardNoCameras => 'Add a camera first so Help can test it.';

  @override
  String get wizardNext => 'Next step';

  @override
  String get wizardPrevious => 'Previous step';

  @override
  String wizardStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get wizardOtherPath => 'Choose another way';

  @override
  String get troubleTitle => 'Troubleshoot';

  @override
  String get troubleBack => 'Back';

  @override
  String get troubleRestart => 'Start again';

  @override
  String get troubleWhatToTry => 'What to try';

  @override
  String get troubleReadMore => 'Read more';

  @override
  String get diagTitle => 'Diagnostics';

  @override
  String get diagIntro => 'Each check runs only when you press its button.';

  @override
  String get diagRun => 'Run';

  @override
  String get diagRunAgain => 'Run again';

  @override
  String get diagRunning => 'Running…';

  @override
  String get diagPassed => 'Passed';

  @override
  String get diagFailed => 'Failed';

  @override
  String get diagLocalTitle => 'This phone on the network';

  @override
  String get diagLocalHelp =>
      'Shows the address of this phone and of your router.';

  @override
  String get diagLocalAddress => 'Phone address';

  @override
  String get diagLocalGateway => 'Router address';

  @override
  String get diagLanTitle => 'Camera on this network';

  @override
  String get diagLanHelp =>
      'Tests a saved camera the way the camera form does.';

  @override
  String get diagLanNoCameras => 'Add a camera to use this check.';

  @override
  String get diagHostTitle => 'Name lookup';

  @override
  String get diagHostHelp => 'Checks that a host name resolves to an address.';

  @override
  String get diagHostField => 'Host name or address';

  @override
  String get diagHostPortTitle => 'Host and port';

  @override
  String get diagHostPortHelp =>
      'Checks that a host and port accept a connection. Run it on mobile data to test the way in from outside.';

  @override
  String get diagPortField => 'Port';

  @override
  String get diagPublicTitle => 'Public address';

  @override
  String get diagPublicHelp =>
      'Asks one public service which address the internet sees for this connection. Only that address is used; no camera or personal data is sent.';

  @override
  String get diagPublicCompare =>
      'Compare it with the internet address on your router\'s status page. If they differ, you are behind CGNAT.';

  @override
  String get diagKindPublic => 'This is a public address.';

  @override
  String get diagKindPrivate =>
      'This is a private address, not reachable from outside.';

  @override
  String get diagKindShared =>
      'This address is shared by your provider (CGNAT). Port forwarding cannot work.';

  @override
  String get diagKindOther => 'This address is not usable from outside.';

  @override
  String get diagTime => 'Time';

  @override
  String get diagResolved => 'Resolves to';

  @override
  String get diagHostRequired => 'Enter a host name or address.';
}
