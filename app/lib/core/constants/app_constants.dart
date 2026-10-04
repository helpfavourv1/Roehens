/// Identity and format constants that never change at runtime.
class AppConstants {
  AppConstants._();

  static const String appName = 'Roehens';
  static const String applicationId = 'com.zdmgold.roehens';
  static const String supportEmail = 'stmakarios@gmail.com';

  /// Non-consumable ad-free purchase (specification A1, Part B).
  static const String adFreeProductId = 'com.zdmgold.roehens.adfree';

  /// Onboarding is shown again when its completed version is below this.
  static const int onboardingVersion = 1;

  /// Schema version written into settings and export files.
  static const int settingsSchemaVersion = 1;

  /// Camera export file format.
  static const String exportFormatId = 'roehens-camera-list';
  static const int exportSchemaVersion = 1;
  static const String exportFileExtension = 'json';
}
