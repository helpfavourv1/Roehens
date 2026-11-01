import 'dart:async';
import 'dart:convert';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// The person's settings, loaded once and saved after every change. A failed
/// save keeps the new value in memory.
class SettingsProvider extends SafeValueNotifier<AppSettings> {
  SettingsProvider({required this._store, required this._logger})
      : super(const AppSettings());

  static const String _tag = 'settings';

  final KeyValueStore _store;
  final LoggerContract _logger;
  Future<void> _saving = Future<void>.value();

  /// Reads the saved settings. A missing or unreadable file means defaults.
  Future<void> load() async {
    final String? raw = (await _store.getString(StorageKeys.settings)).valueOrNull;
    if (raw == null) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        setIfAlive(normalize(AppSettings.fromJson(decoded)));
      }
    } on Object catch (error) {
      _logger.warning(_tag, 'saved settings unreadable, using defaults', error: error);
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(AppSettings Function(AppSettings current) change) {
    setIfAlive(normalize(change(value)));
    final AppSettings snapshot = value;
    _saving = _saving.then((_) => _write(snapshot));
    return _saving;
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    return update((AppSettings s) => s.copyWith(themeMode: mode));
  }

  /// Null follows the system language.
  Future<void> setLocaleCode(String? code) {
    return update((AppSettings s) => s.copyWith(localeCode: code));
  }

  Future<void> setDefaultTransport(StreamTransport transport) {
    return update((AppSettings s) => s.copyWith(defaultTransport: transport));
  }

  Future<void> setKeepAwake({required bool enabled}) {
    return update((AppSettings s) => s.copyWith(keepAwake: enabled));
  }

  Future<void> setHaptics({required bool enabled}) {
    return update((AppSettings s) => s.copyWith(hapticsEnabled: enabled));
  }

  Future<void> setAutoCycle({required bool enabled, int? seconds}) {
    return update(
      (AppSettings s) =>
          s.copyWith(autoCycleEnabled: enabled, autoCycleSeconds: seconds),
    );
  }

  /// Keeps stored values inside what the app supports.
  static AppSettings normalize(AppSettings settings) {
    if (Limits.autoCycleSeconds.contains(settings.autoCycleSeconds)) {
      return settings;
    }
    return settings.copyWith(autoCycleSeconds: Limits.defaultAutoCycleSeconds);
  }

  /// Removes the saved settings and returns to defaults.
  Future<void> reset() async {
    await _saving;
    setIfAlive(const AppSettings());
    await _store.remove(StorageKeys.settings);
  }

  Future<void> _write(AppSettings settings) async {
    final Result<void> result = await _store.setString(
      StorageKeys.settings,
      jsonEncode(settings.toJson()),
    );
    if (result.isErr) {
      _logger.warning(_tag, 'settings not saved, kept in memory');
    }
  }
}
