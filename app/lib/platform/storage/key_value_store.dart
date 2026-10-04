import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value storage on shared preferences. If the platform store fails, values
/// are kept in memory for the session and [isDegraded] is set so the app shows
/// its persistence warning. No call throws.
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore({SharedPreferencesAsync? prefs, LoggerContract? logger})
      : _prefs = prefs ?? SharedPreferencesAsync(),
        _logger = logger;

  final SharedPreferencesAsync _prefs;
  final LoggerContract? _logger;
  final Map<String, String> _memory = <String, String>{};
  final ValueNotifier<bool> _degraded = ValueNotifier<bool>(false);

  ValueListenable<bool> get isDegraded => _degraded;

  @override
  Future<Result<String?>> getString(String key) async {
    try {
      final String? stored = await _prefs.getString(key);
      return Ok<String?>(stored ?? _memory[key]);
    } catch (error) {
      _fail('read', error);
      return Ok<String?>(_memory[key]);
    }
  }

  @override
  Future<Result<void>> setString(String key, String value) async {
    _memory[key] = value;
    try {
      await _prefs.setString(key, value);
      _memory.remove(key);
    } catch (error) {
      _fail('write', error);
    }
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> remove(String key) async {
    _memory.remove(key);
    try {
      await _prefs.remove(key);
    } catch (error) {
      _fail('remove', error);
    }
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> clear() async {
    _memory.clear();
    try {
      await _prefs.clear();
    } catch (error) {
      _fail('clear', error);
    }
    return const Ok<void>(null);
  }

  void _fail(String action, Object error) {
    _degraded.value = true;
    _logger?.warning('prefs', 'preferences $action failed', error: error);
  }

  void dispose() {
    _degraded.dispose();
  }
}
