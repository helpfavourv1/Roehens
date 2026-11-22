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
