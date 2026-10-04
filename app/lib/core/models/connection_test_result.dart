import 'package:flutter/foundation.dart';
import 'package:roehens/core/errors/app_error.dart';

/// Steps of the connection test, in order.
enum TestStage { dns, tcp, auth, describe, firstFrame }

enum StageStatus { pending, running, passed, failed, skipped }

/// Outcome of one stage.
class StageResult {
  const StageResult({
    required this.stage,
    required this.status,
    this.detail,
    this.elapsedMillis,
  });

  final TestStage stage;
  final StageStatus status;

  /// Diagnostic text; never shown by default and never contains credentials.
  final String? detail;
  final int? elapsedMillis;

  @override
  bool operator ==(Object other) {
    return other is StageResult &&
        other.stage == stage &&
        other.status == status &&
        other.detail == detail &&
        other.elapsedMillis == elapsedMillis;
  }

  @override
  int get hashCode => Object.hash(stage, status, detail, elapsedMillis);
}

/// Result of testing a camera: per-stage outcomes, one classified error when it
/// failed, and localization keys of suggestions to try next.
class ConnectionTestResult {
  const ConnectionTestResult({
    required this.stages,
    this.error,
    this.suggestionKeys = const <String>[],
  });

  final List<StageResult> stages;
  final AppError? error;
  final List<String> suggestionKeys;

  /// True when no stage failed and at least one stage passed.
  bool get passed {
    return error == null &&
        !stages.any((StageResult s) => s.status == StageStatus.failed) &&
        stages.any((StageResult s) => s.status == StageStatus.passed);
  }

  StageResult? get firstFailure {
    for (final StageResult stage in stages) {
      if (stage.status == StageStatus.failed) {
        return stage;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionTestResult &&
        listEquals(other.stages, stages) &&
        other.error == error &&
        listEquals(other.suggestionKeys, suggestionKeys);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(stages),
        error,
        Object.hashAll(suggestionKeys),
      );
}
