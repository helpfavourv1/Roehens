import 'dart:async';
import 'dart:io';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/platform/network/http_probe.dart';
import 'package:roehens/platform/network/rtsp_probe.dart';

/// The real network operations behind [ConnectionTester].
class NetworkProbes implements ConnectivityProbes {
  NetworkProbes({
    this.timeout = const Duration(seconds: 6),
    this._errorMapper = const ErrorMapper(),
  })  : _rtsp = RtspProbe(timeout: timeout),
        _http = HttpProbe(timeout: timeout);

  final Duration timeout;
  final ErrorMapper _errorMapper;
  final RtspProbe _rtsp;
  final HttpProbe _http;

  @override
  Future<bool> resolves(String host) async {
    try {
      final List<InternetAddress> found =
          await InternetAddress.lookup(host).timeout(timeout);
      return found.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Result<void>> tcpConnect(String host, int port) async {
    try {
      final Socket socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return const Ok<void>(null);
    } on AppError catch (error) {
      return Err<void>(error);
    } catch (error) {
      return Err<void>(_errorMapper.fromException(error));
    }
  }

  @override
  Future<Result<RtspDescribeResult>> describeRtsp(
    Uri uri,
    CameraCredentials credentials,
  ) async {
    final Result<RtspProbeResult> result =
        await _rtsp.describe(uri, credentials: credentials);
    final AppError? error = result.errorOrNull;
    if (error != null) {
      return Err<RtspDescribeResult>(error);
    }
    final RtspProbeResult reply = result.valueOrNull!;
    return Ok<RtspDescribeResult>(
      RtspDescribeResult(
        statusCode: reply.statusCode,
        statusText: reply.statusText,
        authRequired: reply.authRequired,
        videoCodecs: reply.videoCodecs,
        audioCodecs: reply.audioCodecs,
      ),
    );
  }

  @override
  Future<Result<HttpHeadResult>> probeHttp(
    Uri uri,
    CameraCredentials credentials,
  ) async {
    final Result<HttpProbeResult> result =
        await _http.get(uri, credentials: credentials);
    final AppError? error = result.errorOrNull;
    if (error != null) {
      return Err<HttpHeadResult>(error);
    }
    final HttpProbeResult reply = result.valueOrNull!;
    return Ok<HttpHeadResult>(
      HttpHeadResult(statusCode: reply.statusCode, contentType: reply.contentType),
    );
  }
}
