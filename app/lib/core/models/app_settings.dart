import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/stream_protocol.dart';

const Object _unset = Object();

/// Appearance setting. [system] follows the device.
enum AppThemeMode { system, light, dark }

/// Person-adjustable settings, stored as JSON in key-value storage.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localeCode,
    this.defaultTransport = StreamTransport.auto,
    this.gridSubstreamDefault = true,
    this.keepAwake = true,
    this.showOverlayLabels = true,
    this.hapticsEnabled = true,
    this.autoCycleEnabled = false,
    this.autoCycleSeconds = Limits.defaultAutoCycleSeconds,
    this.schemaVersion = AppConstants.settingsSchemaVersion,
  });

  /// Tolerant of missing keys (older files) and unknown keys (newer files).
  factory AppSettings.fromJson(Map<String, Object?> json) {
    const AppSettings defaults = AppSettings();
    final String? theme = json['themeMode'] as String?;
    final String? transport = json['defaultTransport'] as String?;
    return AppSettings(
      themeMode: theme == null
          ? defaults.themeMode
          : AppThemeMode.values.byName(theme),
      localeCode: json['localeCode'] as String?,
      defaultTransport: transport == null
          ? defaults.defaultTransport
          : StreamTransport.values.byName(transport),
      gridSubstreamDefault:
          json['gridSubstreamDefault'] as bool? ?? defaults.gridSubstreamDefault,
      keepAwake: json['keepAwake'] as bool? ?? defaults.keepAwake,
      showOverlayLabels:
          json['showOverlayLabels'] as bool? ?? defaults.showOverlayLabels,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      autoCycleEnabled:
          json['autoCycleEnabled'] as bool? ?? defaults.autoCycleEnabled,
      autoCycleSeconds:
          json['autoCycleSeconds'] as int? ?? defaults.autoCycleSeconds,
      schemaVersion: json['schemaVersion'] as int? ?? defaults.schemaVersion,
    );
  }

  final AppThemeMode themeMode;

  /// Language chosen in the app, or null to follow the system language.
  final String? localeCode;
  final StreamTransport defaultTransport;

  /// Use the substream in the grid when a camera has one.
  final bool gridSubstreamDefault;
  final bool keepAwake;
  final bool showOverlayLabels;
  final bool hapticsEnabled;
  final bool autoCycleEnabled;
  final int autoCycleSeconds;
  final int schemaVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'themeMode': themeMode.name,
      'localeCode': localeCode,
      'defaultTransport': defaultTransport.name,
      'gridSubstreamDefault': gridSubstreamDefault,
      'keepAwake': keepAwake,
      'showOverlayLabels': showOverlayLabels,
      'hapticsEnabled': hapticsEnabled,
      'autoCycleEnabled': autoCycleEnabled,
      'autoCycleSeconds': autoCycleSeconds,
      'schemaVersion': schemaVersion,
    };
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Object? localeCode = _unset,
    StreamTransport? defaultTransport,
    bool? gridSubstreamDefault,
    bool? keepAwake,
    bool? showOverlayLabels,
    bool? hapticsEnabled,
    bool? autoCycleEnabled,
    int? autoCycleSeconds,
    int? schemaVersion,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode:
          identical(localeCode, _unset) ? this.localeCode : localeCode as String?,
      defaultTransport: defaultTransport ?? this.defaultTransport,
      gridSubstreamDefault: gridSubstreamDefault ?? this.gridSubstreamDefault,
      keepAwake: keepAwake ?? this.keepAwake,
      showOverlayLabels: showOverlayLabels ?? this.showOverlayLabels,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoCycleEnabled: autoCycleEnabled ?? this.autoCycleEnabled,
      autoCycleSeconds: autoCycleSeconds ?? this.autoCycleSeconds,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.localeCode == localeCode &&
        other.defaultTransport == defaultTransport &&
        other.gridSubstreamDefault == gridSubstreamDefault &&
        other.keepAwake == keepAwake &&
        other.showOverlayLabels == showOverlayLabels &&
        other.hapticsEnabled == hapticsEnabled &&
        other.autoCycleEnabled == autoCycleEnabled &&
        other.autoCycleSeconds == autoCycleSeconds &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        localeCode,
        defaultTransport,
        gridSubstreamDefault,
        keepAwake,
        showOverlayLabels,
        hapticsEnabled,
        autoCycleEnabled,
        autoCycleSeconds,
        schemaVersion,
      );
}
