import 'dart:ui';

import 'package:roehens/core/constants/languages.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/providers/settings_provider.dart';

/// The language chosen in the app. Null means "follow the system language".
class LocaleProvider extends SafeValueNotifier<Locale?> {
  LocaleProvider({required this._settings})
      : super(localeFromCode(_settings.value.localeCode)) {
    _settings.addListener(_sync);
  }

  final SettingsProvider _settings;

  /// The code of the chosen language, or null for the system language.
  String? get code => _settings.value.localeCode;

  /// An unsupported code is treated as the system language.
  Future<void> setLanguage(String? code) {
    return _settings.setLocaleCode(localeFromCode(code) == null ? null : code);
  }

  void _sync() => setIfAlive(localeFromCode(_settings.value.localeCode));

  @override
  void dispose() {
    _settings.removeListener(_sync);
    super.dispose();
  }
}
