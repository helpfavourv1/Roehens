import 'package:roehens/core/errors/app_error.dart';

/// The network checks of the Diagnostics screen, each run on its own button.
enum DiagnosticCheck {
  localNetwork,
  lanReachability,
  hostResolution,
  hostPort,
  publicAddress,
}

enum CheckStatus { idle, running, passed, failed }

/// The result of one check. [detail] is a technical value to show in the Mono
/// face (an address, a list of addresses, a time); [error] explains a failure.
class CheckOutcome {
  const CheckOutcome({
    required this.check,
    this.status = CheckStatus.idle,
    this.detail,
    this.error,
  });

  final DiagnosticCheck check;
  final CheckStatus status;
  final String? detail;
  final AppError? error;

  CheckOutcome running() => CheckOutcome(check: check, status: CheckStatus.running);
}

/// All checks so far, by check.
class DiagnosticsReport {
  const DiagnosticsReport([this.outcomes = const <DiagnosticCheck, CheckOutcome>{}]);

  final Map<DiagnosticCheck, CheckOutcome> outcomes;

  CheckOutcome of(DiagnosticCheck check) {
    return outcomes[check] ?? CheckOutcome(check: check);
  }

  DiagnosticsReport withOutcome(CheckOutcome outcome) {
    return DiagnosticsReport(<DiagnosticCheck, CheckOutcome>{
      ...outcomes,
      outcome.check: outcome,
    });
  }
}
