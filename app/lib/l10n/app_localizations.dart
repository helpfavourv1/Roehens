import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The product name, shown as the wordmark.
  ///
  /// In en, this message translates to:
  /// **'Roehens'**
  String get appName;

  /// Bottom bar label for the live camera grid.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// Bottom bar label for the camera list.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get tabCameras;

  /// Bottom bar label for settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Button that starts adding a camera.
  ///
  /// In en, this message translates to:
  /// **'Add camera'**
  String get actionAddCamera;

  /// Button that tries a failed connection again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Button that opens a camera for editing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Button that reverses a delete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// Spoken label of a close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Button that deletes a camera.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Spoken label of a back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Title shown on Live before any camera exists.
  ///
  /// In en, this message translates to:
  /// **'No cameras yet'**
  String get liveEmptyTitle;

  /// Body text on Live before any camera exists.
  ///
  /// In en, this message translates to:
  /// **'Add a camera to see it here. Roehens can find cameras on your network, or you can enter one yourself.'**
  String get liveEmptyBody;

  /// Button that opens network discovery.
  ///
  /// In en, this message translates to:
  /// **'Find cameras on my network'**
  String get liveFindCameras;

  /// Spoken label of the button that opens the layout sheet.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get liveLayoutButton;

  /// Spoken label of the button that starts cycling through cameras.
  ///
  /// In en, this message translates to:
  /// **'Start auto-cycle'**
  String get liveAutoCycleStart;

  /// Spoken label of the button that stops cycling.
  ///
  /// In en, this message translates to:
  /// **'Stop auto-cycle'**
  String get liveAutoCycleStop;

  /// Spoken position among pages of cameras.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String livePageOf(int current, int total);

  /// Stream status: playing.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get statusLive;

  /// Stream status: opening the connection.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// Stream status: lost and trying again.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnecting;

  /// Stream status: failed.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// Stream status: not playing.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// Age of a still picture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second ago} other{{count} seconds ago}}'**
  String ageSeconds(int count);

  /// Age of a still picture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String ageMinutes(int count);

  /// Age of a still picture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String ageHours(int count);

  /// Age of a still picture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String ageDays(int count);

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the camera'**
  String get errorNetworkUnreachable;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Check the username or password'**
  String get errorAuthFailed;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'The stream path was not found'**
  String get errorPathNotFound;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'This camera\'s video format isn\'t supported'**
  String get errorUnsupportedMedia;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Local network access is turned off'**
  String get errorLocalNetworkDenied;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'The stream dropped'**
  String get errorStreamDropped;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Too many streams for this phone'**
  String get errorResourcePressure;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Saved data couldn\'t be read or written'**
  String get errorStorageFailure;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'This feature is switched off for now'**
  String get errorFlagDisabled;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through'**
  String get errorPurchaseFailed;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Roehens camera list'**
  String get errorInvalidFile;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'The file couldn\'t be shared or opened'**
  String get errorTransferFailed;

  /// Error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorFatal;

  /// Protocol name; stays in Latin script.
  ///
  /// In en, this message translates to:
  /// **'RTSP'**
  String get protocolRtsp;

  /// Protocol name; stays in Latin script.
  ///
  /// In en, this message translates to:
  /// **'MJPEG'**
  String get protocolMjpeg;

  /// Protocol name for a camera that serves still pictures.
  ///
  /// In en, this message translates to:
  /// **'HTTP snapshot'**
  String get protocolSnapshot;

  /// Spoken label: turn camera sound off.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get fullscreenMute;

  /// Spoken label: turn camera sound on.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get fullscreenUnmute;

  /// Spoken label of the snapshot button.
  ///
  /// In en, this message translates to:
  /// **'Take snapshot'**
  String get fullscreenSnapshot;

  /// Message when a snapshot fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t capture a picture'**
  String get fullscreenSnapshotFailed;

  /// Spoken label of the button that shows the pan and tilt pad.
  ///
  /// In en, this message translates to:
  /// **'Pan and tilt'**
  String get fullscreenPtz;

  /// Spoken label: use the main stream.
  ///
  /// In en, this message translates to:
  /// **'Use high quality'**
  String get fullscreenQualityHigh;

  /// Spoken label: use the substream.
  ///
  /// In en, this message translates to:
  /// **'Use low quality'**
  String get fullscreenQualityLow;

  /// Spoken label of the picture-in-picture button.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture'**
  String get fullscreenPip;

  /// Spoken label of the button that resets zoom.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get fullscreenZoomReset;

  /// Zoom level shown while zoomed in.
  ///
  /// In en, this message translates to:
  /// **'Zoom {level}×'**
  String fullscreenZoomLevel(String level);

  /// Spoken label for the previous camera.
  ///
  /// In en, this message translates to:
  /// **'Previous camera'**
  String get fullscreenPreviousCamera;

  /// Spoken label for the next camera.
  ///
  /// In en, this message translates to:
  /// **'Next camera'**
  String get fullscreenNextCamera;

  /// Spoken label of the pan and tilt pad.
  ///
  /// In en, this message translates to:
  /// **'Pan and tilt pad'**
  String get ptzPad;

  /// Spoken label of the button that returns the camera to its home position.
  ///
  /// In en, this message translates to:
  /// **'Home position'**
  String get ptzHome;

  /// Spoken label of the camera zoom-in button.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get ptzZoomIn;

  /// Spoken label of the camera zoom-out button.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get ptzZoomOut;

  /// Hint shown when pan and tilt is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Turn on ONVIF for this camera to use pan and tilt.'**
  String get ptzNeedsOnvif;

  /// Message when the camera has no pan and tilt.
  ///
  /// In en, this message translates to:
  /// **'This camera doesn\'t report pan and tilt control.'**
  String get ptzNotSupported;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get camerasTitle;

  /// Hint of the camera search field.
  ///
  /// In en, this message translates to:
  /// **'Search cameras'**
  String get camerasSearchHint;

  /// Title of the empty camera list.
  ///
  /// In en, this message translates to:
  /// **'No cameras yet'**
  String get camerasEmptyTitle;

  /// Body of the empty camera list.
  ///
  /// In en, this message translates to:
  /// **'Add your first camera. Roehens keeps its password in the secure storage of this phone.'**
  String get camerasEmptyBody;

  /// Title when a search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching cameras'**
  String get camerasNoResultsTitle;

  /// Body when a search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or address.'**
  String get camerasNoResultsBody;

  /// Message after a camera is deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String cameraDeleted(String name);

  /// Spoken label of the swipe-to-delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cameraDeleteSwipe;

  /// Title of the layout sheet.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layoutTitle;

  /// Description of the selected grid size.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 camera per page} other{{count} cameras per page}}'**
  String layoutPerPage(int count);

  /// Label of one grid size choice.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String layoutSizeLabel(int count);

  /// Section header of the camera order list.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get layoutOrderSection;

  /// Spoken label of the move-up button.
  ///
  /// In en, this message translates to:
  /// **'Move {name} up'**
  String layoutMoveUp(String name);

  /// Spoken label of the move-down button.
  ///
  /// In en, this message translates to:
  /// **'Move {name} down'**
  String layoutMoveDown(String name);

  /// Section header of the auto-cycle interval.
  ///
  /// In en, this message translates to:
  /// **'Auto-cycle'**
  String get layoutAutoCycleSection;

  /// Choice that uses the global auto-cycle interval.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get layoutAutoCycleDefault;

  /// Auto-cycle interval choice, in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String layoutAutoCycleSeconds(int seconds);

  /// Help text under the auto-cycle choices.
  ///
  /// In en, this message translates to:
  /// **'Moves to the next page after this time. Touching the screen pauses it.'**
  String get layoutAutoCycleHelp;

  /// Banner when storage fails.
  ///
  /// In en, this message translates to:
  /// **'Your saved data can\'t be kept right now. Export your cameras to keep a copy.'**
  String get persistenceDegraded;

  /// Banner when the saved data is from a newer version.
  ///
  /// In en, this message translates to:
  /// **'Update Roehens to open your saved data.'**
  String get persistenceUpdate;

  /// Banner action.
  ///
  /// In en, this message translates to:
  /// **'Export cameras'**
  String get persistenceExport;

  /// Label of the pan and tilt speed slider.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get ptzSpeed;

  /// Title of the add-camera screen.
  ///
  /// In en, this message translates to:
  /// **'Add camera'**
  String get editAddTitle;

  /// Title of the edit-camera screen.
  ///
  /// In en, this message translates to:
  /// **'Edit camera'**
  String get editEditTitle;

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get editSectionCamera;

  /// Section header for username and password.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get editSectionSignIn;

  /// Section header for the stream paths.
  ///
  /// In en, this message translates to:
  /// **'Streams'**
  String get editSectionStreams;

  /// Section header for transport and ONVIF.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get editSectionAdvanced;

  /// Label of the field that takes a whole stream address.
  ///
  /// In en, this message translates to:
  /// **'Stream address'**
  String get editStreamAddress;

  /// Hint of the stream address field. An example address; keep it as is.
  ///
  /// In en, this message translates to:
  /// **'rtsp://192.168.1.10/stream0'**
  String get editStreamAddressHint;

  /// Help under the stream address field.
  ///
  /// In en, this message translates to:
  /// **'Paste a full address to fill in the fields below. A password in it is moved to secure storage.'**
  String get editStreamAddressHelp;

  /// Error under the stream address field.
  ///
  /// In en, this message translates to:
  /// **'That address couldn\'t be read.'**
  String get editAddressNotUnderstood;

  /// Label of the camera name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editName;

  /// Hint of the camera name field.
  ///
  /// In en, this message translates to:
  /// **'Front door'**
  String get editNameHint;

  /// Error when the name is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the camera a name.'**
  String get editNameRequired;

  /// Label of the stream type choice.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get editProtocol;

  /// Label of the host field.
  ///
  /// In en, this message translates to:
  /// **'Address or host name'**
  String get editHost;

  /// Hint of the host field. An example address; keep it as is.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.10'**
  String get editHostHint;

  /// Error when the host is not valid.
  ///
  /// In en, this message translates to:
  /// **'Enter an IP address or host name, without spaces or slashes.'**
  String get editHostInvalid;

  /// Label of the port field.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get editPort;

  /// Error when a port is not valid.
  ///
  /// In en, this message translates to:
  /// **'Enter a port from 1 to 65535.'**
  String get editPortInvalid;

  /// Label of the username field.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editUsername;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get editPassword;

  /// Spoken label of the show-password button.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get editShowPassword;

  /// Spoken label of the hide-password button.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get editHidePassword;

  /// Label of the main stream path field.
  ///
  /// In en, this message translates to:
  /// **'Main stream path'**
  String get editMainPath;

  /// Label of the substream path field.
  ///
  /// In en, this message translates to:
  /// **'Substream path (optional)'**
  String get editSubPath;

  /// Label of the RTSP transport choice.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get editTransport;

  /// RTSP transport: let the app choose.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get transportAuto;

  /// RTSP transport; stays in Latin script.
  ///
  /// In en, this message translates to:
  /// **'TCP'**
  String get transportTcp;

  /// Label of the ONVIF switch.
  ///
  /// In en, this message translates to:
  /// **'Use ONVIF'**
  String get editOnvif;

  /// Help under the ONVIF switch.
  ///
  /// In en, this message translates to:
  /// **'Needed for pan and tilt. Most cameras answer on port 80 or 8000.'**
  String get editOnvifHelp;

  /// Label of the ONVIF port field.
  ///
  /// In en, this message translates to:
  /// **'ONVIF port'**
  String get editOnvifPort;

  /// Label of the brand row.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get editBrand;

  /// Value of the brand row before a brand is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a brand'**
  String get editBrandNone;

  /// Label of the model field.
  ///
  /// In en, this message translates to:
  /// **'Model (optional)'**
  String get editModel;

  /// Header over the chips of alternative stream paths.
  ///
  /// In en, this message translates to:
  /// **'Other paths this brand uses'**
  String get editBrandPaths;

  /// Button that saves the camera.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSave;

  /// Button that tests the connection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testRun;

  /// Button that repeats the connection test.
  ///
  /// In en, this message translates to:
  /// **'Test again'**
  String get testRunAgain;

  /// Shown while the connection test runs.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get testRunning;

  /// Result when every step passed.
  ///
  /// In en, this message translates to:
  /// **'The connection works.'**
  String get testPassed;

  /// Result when a step failed.
  ///
  /// In en, this message translates to:
  /// **'The connection didn\'t work.'**
  String get testFailed;

  /// Test step: name lookup.
  ///
  /// In en, this message translates to:
  /// **'Find the address'**
  String get testStageDns;

  /// Test step: open the connection.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get testStageTcp;

  /// Test step: check the login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get testStageAuth;

  /// Test step: ask for the stream details.
  ///
  /// In en, this message translates to:
  /// **'Read the stream'**
  String get testStageDescribe;

  /// Test step: wait for a picture.
  ///
  /// In en, this message translates to:
  /// **'First picture'**
  String get testStageFirstFrame;

  /// Test step status.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get testStatusPending;

  /// Test step status.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get testStatusRunning;

  /// Test step status.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get testStatusPassed;

  /// Test step status.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get testStatusFailed;

  /// Test step status.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get testStatusSkipped;

  /// Time a test step took.
  ///
  /// In en, this message translates to:
  /// **'{millis} ms'**
  String testElapsed(int millis);

  /// Pill that opens the troubleshooter after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Open troubleshooter'**
  String get testOpenTroubleshooter;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Check the address for typing mistakes.'**
  String get testSuggestCheckHostName;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Make sure this phone and the camera are on the same Wi-Fi.'**
  String get testSuggestCheckWifi;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Check the port. Many cameras use 554 for RTSP.'**
  String get testSuggestCheckPort;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Turn on RTSP in the camera settings.'**
  String get testSuggestEnableRtsp;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Check the username and password.'**
  String get testSuggestCheckCredentials;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Try another path for this brand.'**
  String get testSuggestTryBrandPaths;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Try the substream, which is lighter.'**
  String get testSuggestTrySubstream;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Try an MJPEG address if the camera offers one.'**
  String get testSuggestTryMjpeg;

  /// Suggestion after a failed test.
  ///
  /// In en, this message translates to:
  /// **'Open the troubleshooter for more help.'**
  String get testSuggestOpenTroubleshooter;

  /// Title of the brand picker.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandTitle;

  /// Hint of the brand search field.
  ///
  /// In en, this message translates to:
  /// **'Search brands'**
  String get brandSearch;

  /// Title when a brand search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No brand matches'**
  String get brandNoResults;

  /// Help when a brand search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'Choose Generic RTSP if your brand isn\'t listed.'**
  String get brandNoResultsHint;

  /// Badge on a brand whose paths were confirmed on a real camera.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get brandVerified;

  /// Title of the discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Find cameras'**
  String get discoveryTitle;

  /// Shown while discovery runs.
  ///
  /// In en, this message translates to:
  /// **'Looking for cameras on your network…'**
  String get discoveryScanning;

  /// Number of cameras found.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 camera found} other{{count} cameras found}}'**
  String discoveryFound(int count);

  /// Button that repeats discovery.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get discoveryRescan;

  /// Title when discovery finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No cameras found'**
  String get discoveryNone;

  /// Help when discovery finds nothing.
  ///
  /// In en, this message translates to:
  /// **'Check that this phone and the camera are on the same Wi-Fi, and that ONVIF is on in the camera.'**
  String get discoveryNoneBody;

  /// Button that opens the add-camera form.
  ///
  /// In en, this message translates to:
  /// **'Add a camera by hand'**
  String get discoveryManual;

  /// Badge: found by ONVIF; stays in Latin script.
  ///
  /// In en, this message translates to:
  /// **'ONVIF'**
  String get discoverySourceOnvif;

  /// Badge: found by scanning addresses.
  ///
  /// In en, this message translates to:
  /// **'Network scan'**
  String get discoverySourceSweep;

  /// Shown when the discovery kill switch is on.
  ///
  /// In en, this message translates to:
  /// **'Camera search is switched off for now.'**
  String get discoveryDisabled;

  /// Title when local network access is refused.
  ///
  /// In en, this message translates to:
  /// **'Local network access is off'**
  String get discoveryPermissionTitle;

  /// Body when local network access is refused.
  ///
  /// In en, this message translates to:
  /// **'Roehens needs local network access to find cameras. Turn it on in Settings.'**
  String get discoveryPermissionBody;

  /// Button that opens the phone settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get discoveryOpenSettings;

  /// Title of the import and export screen.
  ///
  /// In en, this message translates to:
  /// **'Import and export'**
  String get ioTitle;

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get ioExportSection;

  /// Row that shares the camera list.
  ///
  /// In en, this message translates to:
  /// **'Export camera list'**
  String get ioExportRow;

  /// Summary under the export row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No cameras to export} =1{1 camera, without its password} other{{count} cameras, without passwords}}'**
  String ioExportBody(int count);

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get ioImportSection;

  /// Row that picks a camera list file.
  ///
  /// In en, this message translates to:
  /// **'Import from a file'**
  String get ioImportRow;

  /// Help under the import row.
  ///
  /// In en, this message translates to:
  /// **'Choose a camera list exported from Roehens. Passwords are not included; add them afterwards.'**
  String get ioImportBody;

  /// Section header over the import preview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 camera in the file} other{{count} cameras in the file}}'**
  String ioPreviewSection(int count);

  /// Badge: the camera is not saved yet.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ioItemNew;

  /// Badge: a camera with this address exists.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get ioItemExists;

  /// Section header of the conflict choice.
  ///
  /// In en, this message translates to:
  /// **'When a camera already exists'**
  String get ioConflictSection;

  /// Conflict choice: leave the saved camera.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ioSkip;

  /// Conflict choice: overwrite the saved camera.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get ioReplace;

  /// Conflict choice: add a second camera.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get ioDuplicate;

  /// Note about unreadable entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry could not be read and is left out} other{{count} entries could not be read and are left out}}'**
  String ioInvalidEntries(int count);

  /// Button that imports the previewed cameras.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get ioApply;

  /// Result of an import.
  ///
  /// In en, this message translates to:
  /// **'Added {added}, replaced {replaced}, skipped {skipped}, failed {failed}.'**
  String ioDone(int added, int replaced, int skipped, int failed);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
