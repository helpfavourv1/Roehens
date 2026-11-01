import 'package:flutter/foundation.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// What is wrong with local storage, if anything.
enum PersistenceIssue {
  none,

  /// A store could not be opened. Data is kept in memory for this session and
  /// the app shows a persistent warning banner (D2).
  degraded,

  /// The database was written by a newer version of the app. The app refuses
  /// to open it and shows the "update the app" screen.
  updateRequired,
}

/// Feeds the persistent warning banner. Combines the "degraded" signals of the
/// storage services.
class PersistenceHealthProvider extends SafeValueNotifier<PersistenceIssue> {
  PersistenceHealthProvider({required List<ValueListenable<bool>> sources})
      : _sources = List<ValueListenable<bool>>.unmodifiable(sources),
        super(PersistenceIssue.none) {
    for (final ValueListenable<bool> source in _sources) {
      source.addListener(_evaluate);
    }
    _evaluate();
  }

  final List<ValueListenable<bool>> _sources;
  bool _updateRequired = false;

  bool get hasIssue => value != PersistenceIssue.none;

  /// A newer database was found. Takes priority over a plain warning.
  void markUpdateRequired() {
    _updateRequired = true;
    _evaluate();
  }

  void _evaluate() {
    if (_updateRequired) {
      setIfAlive(PersistenceIssue.updateRequired);
    } else if (_sources.any((ValueListenable<bool> s) => s.value)) {
      setIfAlive(PersistenceIssue.degraded);
    } else {
      setIfAlive(PersistenceIssue.none);
    }
  }

  @override
  void dispose() {
    for (final ValueListenable<bool> source in _sources) {
      source.removeListener(_evaluate);
    }
    super.dispose();
  }
}
