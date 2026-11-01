import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/providers/settings_provider.dart';

/// The appearance choice. It follows the settings, so there is one source of
/// truth.
class ThemeProvider extends SafeValueNotifier<AppThemeMode> {
  ThemeProvider({required this._settings}) : super(_settings.value.themeMode) {
    _settings.addListener(_sync);
  }

  final SettingsProvider _settings;

  Future<void> setMode(AppThemeMode mode) => _settings.setThemeMode(mode);

  void _sync() => setIfAlive(_settings.value.themeMode);

  @override
  void dispose() {
    _settings.removeListener(_sync);
    super.dispose();
  }
}
