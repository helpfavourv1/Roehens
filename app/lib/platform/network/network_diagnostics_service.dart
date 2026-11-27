import 'dart:async';
import 'dart:io';

import 'package:roehens/core/contracts/network_diagnostics_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/diagnostics_report.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/public_ip_lookup.dart';

/// The network checks of the Diagnostics screen. Each answers one question
/// with a technical value to show and, on failure, a classified error.
class NetworkDiagnosticsService implements NetworkDiagnosticsContract {
  NetworkDiagnosticsService({
    required this._lan,
    required this._probes,
    required this._tester,
    required this._lookup,
    Future<List<InternetAddress>> Function(String host)? resolver,
    this.resolveTimeout = const Duration(seconds: 5),
  }) : _resolver = resolver ?? InternetAddress.lookup;

  final LanInfo _lan;
  final ConnectivityProbes _probes;
  final ConnectionTester _tester;
  final PublicIpLookup _lookup;
  final Future<List<InternetAddress>> Function(String host) _resolver;
  final Duration resolveTimeout;

  @override
  Future<CheckOutcome> localNetwork() async {
    final LanSnapshot? snapshot = await _lan.read();
    if (snapshot == null) {
      return const CheckOutcome(
        check: DiagnosticCheck.localNetwork,
        status: CheckStatus.failed,
        error: AppError(ErrorClass.networkUnreachable),
      );
    }
    final String gateway = snapshot.gateway == null
        ? '-'
        : '${snapshot.gateway}${snapshot.gatewayIsGuess ? ' (?)' : ''}';
    return CheckOutcome(
      check: DiagnosticCheck.localNetwork,
      status: CheckStatus.passed,
      detail: '${snapshot.address}\n$gateway',
    );
  }

  @override
  Future<CheckOutcome> lanReachability(
    Camera camera,
    CameraCredentials credentials,
  ) async {
    final ConnectionTestResult result = await _tester.run(camera, credentials);
    return CheckOutcome(
      check: DiagnosticCheck.lanReachability,
      status: result.passed ? CheckStatus.passed : CheckStatus.failed,
      error: result.error,
    );
  }

  @override
  Future<CheckOutcome> hostResolution(String host) async {
    try {
      final List<InternetAddress> found = await _resolver(
        host,
      ).timeout(resolveTimeout);
      if (found.isEmpty) {
        return const CheckOutcome(
          check: DiagnosticCheck.hostResolution,
          status: CheckStatus.failed,
          error: AppError(ErrorClass.networkUnreachable),
        );
      }
      return CheckOutcome(
        check: DiagnosticCheck.hostResolution,
        status: CheckStatus.passed,
        detail: found.map((InternetAddress a) => a.address).join('\n'),
      );
    } on TimeoutException {
      return _resolutionFailed();
    } on SocketException {
      return _resolutionFailed();
    }
  }

  CheckOutcome _resolutionFailed() {
    return const CheckOutcome(
      check: DiagnosticCheck.hostResolution,
      status: CheckStatus.failed,
      error: AppError(ErrorClass.networkUnreachable),
    );
  }

  @override
  Future<CheckOutcome> hostPort(String host, int port) async {
    final Stopwatch clock = Stopwatch()..start();
    final Result<void> result = await _probes.tcpConnect(host, port);
    final AppError? error = result.errorOrNull;
    if (error != null) {
      return CheckOutcome(
        check: DiagnosticCheck.hostPort,
        status: CheckStatus.failed,
        error: error,
      );
    }
    return CheckOutcome(
      check: DiagnosticCheck.hostPort,
      status: CheckStatus.passed,
      detail: '${clock.elapsedMilliseconds} ms',
    );
  }

  @override
  Future<CheckOutcome> publicAddress() async {
    final Result<String> result = await _lookup.fetch();
    final String? address = result.valueOrNull;
    if (address == null) {
      return CheckOutcome(
        check: DiagnosticCheck.publicAddress,
        status: CheckStatus.failed,
        error: result.errorOrNull,
      );
    }
    return CheckOutcome(
      check: DiagnosticCheck.publicAddress,
      status: CheckStatus.passed,
      detail: address,
    );
  }
}
