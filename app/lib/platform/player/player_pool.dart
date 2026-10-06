import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/reconnect_policy.dart';

/// Creates the right kind of session for a protocol.
typedef SessionFactory = PlayerSessionContract Function(StreamProtocol protocol);

/// One session under the pool's care. Its [state] is what the tile shows: the
/// raw session state plus the reconnect behavior the pool adds.
class PooledSession {
  PooledSession._({
    required this.key,
    required this.source,
    required this.session,
    required this._policy,
    required this._clock,
    required this._mapper,
    this._logger,
  });

  final String key;
  final PlayerSource source;
  final PlayerSessionContract session;
  final ReconnectPolicy _policy;
  final ClockContract _clock;
  final ErrorMapper _mapper;
  final LoggerContract? _logger;

  final ValueNotifier<PlayerState> state =
      ValueNotifier<PlayerState>(const PlayerIdle());

  Timer? _retryTimer;
  DateTime? _playingSince;
  bool _disposed = false;

  ValueListenable<VideoSize?> get videoSize => session.videoSize;

  /// The opaque handle the video view needs.
  Object? get viewHandle => session.viewHandle;

  Future<void> _start() async {
    session.state.addListener(_onSessionState);
    await _open();
  }

  Future<void> _open() async {
    if (_disposed) {
      return;
    }
    try {
      await session.open(source);
    } catch (error) {
      _logger?.warning('pool', 'session $key failed to open', error: error);
      _handleError(_mapper.fromException(error));
    }
  }

  void _onSessionState() {
    if (_disposed) {
      return;
    }
    final PlayerState next = session.state.value;
    switch (next) {
      case PlayerPlaying():
        _playingSince ??= _clock.now();
        _retryTimer?.cancel();
        state.value = next;
      case PlayerConnecting() || PlayerBuffering():
        // While reconnecting the tile keeps saying so until playback resumes.
        if (state.value is! PlayerReconnecting) {
          state.value = next;
        }
      case PlayerError():
        _handleError(next.error);
      case PlayerReconnecting() || PlayerIdle() || PlayerStopped():
        state.value = next;
    }
  }

  void _handleError(AppError error) {
    final DateTime? since = _playingSince;
    _playingSince = null;
    if (since != null) {
      _policy.onHealthyPlayback(_clock.now().difference(since));
    }
    if (!error.autoRetry) {
      state.value = PlayerError(error);
      return;
    }
    final Duration? delay = _policy.nextDelay();
    if (delay == null) {
      state.value = PlayerError(error);
      return;
    }
    state.value = PlayerReconnecting(attempt: _policy.attempts);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(_open()));
  }

  /// Manual retry: forgives earlier failures and connects again now.
  Future<void> retry() async {
    if (_disposed) {
      return;
    }
    _policy.reset();
    _retryTimer?.cancel();
    _playingSince = null;
    state.value = const PlayerConnecting();
    await _open();
  }

  Future<void> _dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _retryTimer?.cancel();
    session.state.removeListener(_onSessionState);
    try {
      await session.dispose();
    } catch (error) {
      _logger?.warning('pool', 'session $key failed to dispose', error: error);
    }
    state.dispose();
  }
}

/// Owns every playback session (specification D3). A session exists only while
/// the screen wants it; disposal is deterministic.
class PlayerPool {
  PlayerPool({
    required this.sessionFactory,
    ReconnectPolicy Function()? policyFactory,
    this.startStagger = Limits.resumeStagger,
    this.clock = const SystemClock(),
    this.logger,
    this.mapper = const ErrorMapper(),
  }) : _policyFactory = policyFactory ?? ReconnectPolicy.new;

  final SessionFactory sessionFactory;
  final Duration startStagger;
  final ClockContract clock;
  final LoggerContract? logger;
  final ErrorMapper mapper;
  final ReconnectPolicy Function() _policyFactory;

  final Map<String, PooledSession> _sessions = <String, PooledSession>{};
  Map<String, PlayerSource> _desired = <String, PlayerSource>{};
  bool _paused = false;

  Iterable<String> get keys => _sessions.keys;

  PooledSession? sessionFor(String key) => _sessions[key];

  /// Brings the pool to exactly [desired]: sessions that are no longer wanted
  /// (or whose source changed) are disposed, new ones are started one
  /// [startStagger] apart so decoders do not all spin up at once.
  Future<void> reconcile(Map<String, PlayerSource> desired) async {
    _desired = Map<String, PlayerSource>.of(desired);
    if (_paused) {
      return;
    }
    await _apply();
  }

  Future<void> _apply() async {
    final Map<String, PlayerSource> target = _desired;
    for (final String key in _sessions.keys.toList()) {
      final PlayerSource? wanted = target[key];
      if (wanted == null || wanted != _sessions[key]!.source) {
        await _remove(key);
      }
    }
    bool first = true;
    for (final MapEntry<String, PlayerSource> entry in target.entries) {
      if (_sessions.containsKey(entry.key)) {
        continue;
      }
      if (!first && startStagger > Duration.zero) {
        await Future<void>.delayed(startStagger);
      }
      first = false;
      if (_paused || !identical(target, _desired)) {
        return;
      }
      await _add(entry.key, entry.value);
    }
  }

  Future<void> _add(String key, PlayerSource source) async {
    if (_sessions.containsKey(key)) {
      return;
    }
    final PooledSession pooled;
    try {
      pooled = PooledSession._(
        key: key,
        source: source,
        session: sessionFactory(source.protocol),
        policy: _policyFactory(),
        clock: clock,
        mapper: mapper,
        logger: logger,
      );
    } catch (error) {
      logger?.error('pool', 'cannot create a session for $key', error: error);
      return;
    }
    _sessions[key] = pooled;
    await pooled._start();
  }

  Future<void> _remove(String key) async {
    final PooledSession? pooled = _sessions.remove(key);
    await pooled?._dispose();
  }

  /// Manual retry for one tile.
  Future<void> retry(String key) async {
    await _sessions[key]?.retry();
  }

  /// Stops wanting [key] and disposes its session.
  Future<void> release(String key) async {
    _desired = Map<String, PlayerSource>.of(_desired)..remove(key);
    await _remove(key);
  }

  /// App moved to the background: dispose everything except [keep] (the one
  /// session an Android picture-in-picture window may still need). The desired
  /// set is remembered for [resume].
  Future<void> pause({Set<String> keep = const <String>{}}) async {
    _paused = true;
    for (final String key in _sessions.keys.toList()) {
      if (!keep.contains(key)) {
        await _remove(key);
      }
    }
  }

  /// App is back: recreate the remembered sessions, staggered.
  Future<void> resume() async {
    _paused = false;
    await _apply();
  }

  Future<void> disposeAll() async {
    _desired = <String, PlayerSource>{};
    for (final String key in _sessions.keys.toList()) {
      await _remove(key);
    }
  }
}
