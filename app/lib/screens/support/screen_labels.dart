import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/stream_protocol.dart';
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
