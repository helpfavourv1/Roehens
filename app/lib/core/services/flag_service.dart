import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/flags_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/models/remote_flags.dart';

/// Downloads the flags file as text. Throws on any failure.
typedef FlagsFetcher = Future<String> Function(Uri url, Duration timeout);

/// Remote kill switches (D7): fetched on launch with a short timeout, cached,
/// stale-while-revalidate, re-checked every six hours and on resume. A failed
/// fetch keeps the cache, and no cache means everything on.
class FlagService implements FlagsContract {
  FlagService({
    required this._store,
    required this._fetcher,
    required this._clock,
    required this._logger,
    this.url,
  });

  static const String _tag = 'flags';

  /// Where the file lives. Null until the website is hosted; the service then
  /// serves the cache or the defaults and never touches the network.
  final Uri? url;

  final KeyValueStore _store;
  final FlagsFetcher _fetcher;
  final ClockContract _clock;
  final LoggerContract _logger;
  final ValueNotifier<RemoteFlags> _flags = ValueNotifier<RemoteFlags>(
    RemoteFlags.defaults,
  );

  Timer? _timer;
  bool _cacheLoaded = false;
  bool _refreshing = false;
  DateTime? _lastAttempt;

  @override
  ValueListenable<RemoteFlags> get flags => _flags;

  @override
  Future<void> refresh() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    try {
      await _loadCache();
      await _fetch();
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        'refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _refreshing = false;
    }
  }

  /// Starts the six-hour re-check while the app is open.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(Limits.flagsRecheck, (Timer _) {
      unawaited(refresh());
    });
  }

  /// Call when the app returns to the foreground. Skips the request when one
  /// was made a moment ago.
  Future<void> onResume() async {
    final DateTime? last = _lastAttempt;
    if (last != null &&
        _clock.now().difference(last) < Limits.flagsResumeMinInterval) {
      return;
    }
    await refresh();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _flags.dispose();
  }

  Future<void> _loadCache() async {
    if (_cacheLoaded) {
      return;
    }
    _cacheLoaded = true;
    final String? raw = (await _store.getString(StorageKeys.flagsCache))
        .valueOrNull;
    if (raw == null) {
      return;
    }
    final RemoteFlags? cached = _parse(raw);
    if (cached != null) {
      _flags.value = cached;
    }
  }

  Future<void> _fetch() async {
    final Uri? target = url;
    if (target == null || target.scheme != 'https') {
      return;
    }
    _lastAttempt = _clock.now();
    final String body;
    try {
      body = await _fetcher(target, Limits.flagsTimeout);
    } catch (error) {
      _logger.warning(_tag, 'fetch failed, keeping cache', error: error);
      return;
    }
    final RemoteFlags? fresh = _parse(body);
    if (fresh == null) {
      _logger.warning(_tag, 'flags file is not valid, keeping cache');
      return;
    }
    _flags.value = fresh;
    await _store.setString(StorageKeys.flagsCache, body);
    await _store.setString(
      StorageKeys.flagsFetchedAtMillis,
      _clock.now().millisecondsSinceEpoch.toString(),
    );
  }

  RemoteFlags? _parse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return RemoteFlags.fromJson(decoded);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
