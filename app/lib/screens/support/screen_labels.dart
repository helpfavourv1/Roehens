import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/camera_form.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/utils/date_formatter.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// Turns models and error classes into the words a screen shows.
///
/// Kept in one place so every screen says the same thing the same way, and so
/// the 24 translations of each phrase are written once.

String streamStatusLabel(AppLocalizations l10n, StreamStatus status) {
  return switch (status) {
    StreamStatus.live => l10n.statusLive,
    StreamStatus.connecting => l10n.statusConnecting,
    StreamStatus.reconnecting => l10n.statusReconnecting,
    StreamStatus.error => l10n.statusError,
    StreamStatus.offline => l10n.statusOffline,
  };
}

String protocolLabel(AppLocalizations l10n, StreamProtocol protocol) {
  return switch (protocol) {
    StreamProtocol.rtsp => l10n.protocolRtsp,
    StreamProtocol.mjpeg => l10n.protocolMjpeg,
    StreamProtocol.httpSnapshot => l10n.protocolSnapshot,
  };
}

/// The person-facing sentence for [error], chosen by its message key.
String errorMessage(AppLocalizations l10n, AppError error) {
  return switch (error.messageKey) {
    'errorNetworkUnreachable' => l10n.errorNetworkUnreachable,
    'errorAuthFailed' => l10n.errorAuthFailed,
    'errorPathNotFound' => l10n.errorPathNotFound,
    'errorUnsupportedMedia' => l10n.errorUnsupportedMedia,
    'errorLocalNetworkDenied' => l10n.errorLocalNetworkDenied,
    'errorStreamDropped' => l10n.errorStreamDropped,
    'errorResourcePressure' => l10n.errorResourcePressure,
    'errorStorageFailure' => l10n.errorStorageFailure,
    'errorFlagDisabled' => l10n.errorFlagDisabled,
    'errorPurchaseFailed' => l10n.errorPurchaseFailed,
    'errorInvalidFile' => l10n.errorInvalidFile,
    'errorTransferFailed' => l10n.errorTransferFailed,
    _ => l10n.errorFatal,
  };
}

/// "5 seconds ago" and friends, for the age of a still picture.
String ageLabel(AppLocalizations l10n, AgeSpan span) {
  return switch (span.unit) {
    AgeUnit.seconds => l10n.ageSeconds(span.value),
    AgeUnit.minutes => l10n.ageMinutes(span.value),
    AgeUnit.hours => l10n.ageHours(span.value),
    AgeUnit.days => l10n.ageDays(span.value),
  };
}

/// `host:port`, the address as the person typed it (always left-to-right).
String cameraAddress(String host, int port) => '$host:$port';

String testStageLabel(AppLocalizations l10n, TestStage stage) {
  return switch (stage) {
    TestStage.dns => l10n.testStageDns,
    TestStage.tcp => l10n.testStageTcp,
    TestStage.auth => l10n.testStageAuth,
    TestStage.describe => l10n.testStageDescribe,
    TestStage.firstFrame => l10n.testStageFirstFrame,
  };
}

String testStatusLabel(AppLocalizations l10n, StageStatus status) {
  return switch (status) {
    StageStatus.pending => l10n.testStatusPending,
    StageStatus.running => l10n.testStatusRunning,
    StageStatus.passed => l10n.testStatusPassed,
    StageStatus.failed => l10n.testStatusFailed,
    StageStatus.skipped => l10n.testStatusSkipped,
  };
}

/// The sentence for a suggestion key the connection tester produced. Keys this
/// build does not know are left out (null), never shown raw.
String? testSuggestionLabel(AppLocalizations l10n, String key) {
  return switch (key) {
    TestSuggestion.checkHostName => l10n.testSuggestCheckHostName,
    TestSuggestion.checkWifi => l10n.testSuggestCheckWifi,
    TestSuggestion.checkPort => l10n.testSuggestCheckPort,
    TestSuggestion.enableRtsp => l10n.testSuggestEnableRtsp,
    TestSuggestion.checkCredentials => l10n.testSuggestCheckCredentials,
    TestSuggestion.tryBrandPaths => l10n.testSuggestTryBrandPaths,
    TestSuggestion.trySubstream => l10n.testSuggestTrySubstream,
    TestSuggestion.tryMjpeg => l10n.testSuggestTryMjpeg,
    TestSuggestion.openTroubleshooter => l10n.testSuggestOpenTroubleshooter,
    _ => null,
  };
}

String formIssueLabel(AppLocalizations l10n, CameraFormIssue issue) {
  return switch (issue) {
    CameraFormIssue.nameRequired => l10n.editNameRequired,
    CameraFormIssue.hostInvalid => l10n.editHostInvalid,
    CameraFormIssue.portInvalid => l10n.editPortInvalid,
  };
}
