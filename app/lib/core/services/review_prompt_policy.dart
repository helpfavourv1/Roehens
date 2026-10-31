import 'dart:convert';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';

/// What the app remembers to decide when to ask for a rating.
class RatingState {
  const RatingState({
    this.firstLaunchAt,
    this.viewingSessions = 0,
    this.promptCount = 0,
    this.lastPromptAt,
    this.lastErrorAt,
  });

  factory RatingState.fromJson(Map<String, Object?> json) {
    DateTime? read(String key) {
      final int? millis = json[key] as int?;
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    return RatingState(
      firstLaunchAt: read('firstLaunchAtMillis'),
      viewingSessions: json['viewingSessions'] as int? ?? 0,
      promptCount: json['promptCount'] as int? ?? 0,
      lastPromptAt: read('lastPromptAtMillis'),
      lastErrorAt: read('lastErrorAtMillis'),
    );
  }

  final DateTime? firstLaunchAt;

  /// Sessions in which a camera played without trouble.
  final int viewingSessions;
  final int promptCount;
  final DateTime? lastPromptAt;
  final DateTime? lastErrorAt;

  RatingState copyWith({
    DateTime? firstLaunchAt,
    int? viewingSessions,
    int? promptCount,
    DateTime? lastPromptAt,
    DateTime? lastErrorAt,
  }) {
    return RatingState(
      firstLaunchAt: firstLaunchAt ?? this.firstLaunchAt,
      viewingSessions: viewingSessions ?? this.viewingSessions,
      promptCount: promptCount ?? this.promptCount,
      lastPromptAt: lastPromptAt ?? this.lastPromptAt,
      lastErrorAt: lastErrorAt ?? this.lastErrorAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'firstLaunchAtMillis': firstLaunchAt?.millisecondsSinceEpoch,
      'viewingSessions': viewingSessions,
      'promptCount': promptCount,
      'lastPromptAtMillis': lastPromptAt?.millisecondsSinceEpoch,
      'lastErrorAtMillis': lastErrorAt?.millisecondsSinceEpoch,
    };
  }
}

/// Decides when the store rating prompt may appear. Frequency-capped, and
/// never after an error. The store still decides whether it shows.
class ReviewPromptPolicy {
  ReviewPromptPolicy({
    required KeyValueStore store,
    required ClockContract clock,
  })  : _store = store,
        _clock = clock;

  final KeyValueStore _store;
  final ClockContract _clock;
  RatingState? _state;
  bool _errorThisSession = false;

  /// The pure rule, separated so it can be tested without storage.
  static bool isDue(
    RatingState state,
    DateTime now, {
    required bool errorThisSession,
  }) {
    if (errorThisSession) {
      return false;
    }
    final DateTime? firstLaunch = state.firstLaunchAt;
    if (firstLaunch == null ||
        now.difference(firstLaunch).inDays < Limits.ratingMinDaysSinceFirstLaunch) {
      return false;
    }
    if (state.viewingSessions < Limits.ratingMinViewingSessions) {
      return false;
    }
    if (state.promptCount >= Limits.ratingMaxPrompts) {
      return false;
    }
    final DateTime? lastPrompt = state.lastPromptAt;
    if (lastPrompt != null &&
        now.difference(lastPrompt).inDays < Limits.ratingMinDaysBetweenPrompts) {
      return false;
    }
    final DateTime? lastError = state.lastErrorAt;
    if (lastError != null &&
        now.difference(lastError) < Limits.ratingQuietAfterError) {
      return false;
    }
    return true;
  }

  /// Call once per app start.
  Future<void> recordLaunch() async {
    final RatingState state = await _load();
    if (state.firstLaunchAt == null) {
      await _save(state.copyWith(firstLaunchAt: _clock.now().toUtc()));
    }
    _errorThisSession = false;
  }

  /// Call when a camera has played for a meaningful time without an error.
  /// Counts at most once per app start.
  Future<void> recordViewingSession() async {
    if (_countedThisSession) {
      return;
    }
    _countedThisSession = true;
    final RatingState state = await _load();
    await _save(state.copyWith(viewingSessions: state.viewingSessions + 1));
  }

  bool _countedThisSession = false;

  /// Call on any error the person saw.
  Future<void> recordError() async {
    _errorThisSession = true;
    final RatingState state = await _load();
    await _save(state.copyWith(lastErrorAt: _clock.now().toUtc()));
  }

  Future<bool> shouldPrompt() async {
    final RatingState state = await _load();
    return isDue(state, _clock.now().toUtc(), errorThisSession: _errorThisSession);
  }

  /// Call when the prompt was requested.
  Future<void> markPrompted() async {
    final RatingState state = await _load();
    await _save(
      state.copyWith(
        promptCount: state.promptCount + 1,
        lastPromptAt: _clock.now().toUtc(),
      ),
    );
  }

  Future<RatingState> _load() async {
    final RatingState? cached = _state;
    if (cached != null) {
      return cached;
    }
    final String? raw = (await _store.getString(StorageKeys.ratingState)).valueOrNull;
    RatingState loaded = const RatingState();
    if (raw != null) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          loaded = RatingState.fromJson(decoded);
        }
      } on FormatException {
        loaded = const RatingState();
      } on TypeError {
        loaded = const RatingState();
      }
    }
    _state = loaded;
    return loaded;
  }

  Future<void> _save(RatingState state) async {
    _state = state;
    await _store.setString(StorageKeys.ratingState, jsonEncode(state.toJson()));
  }
}
