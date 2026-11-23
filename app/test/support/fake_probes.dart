import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/connection_tester.dart';

/// Answers the connection tester's network questions from memory.
class FakeProbes implements ConnectivityProbes {
  bool dnsOk = true;
  Result<void> tcp = const Ok<void>(null);
  Result<RtspDescribeResult> rtsp = const Ok<RtspDescribeResult>(
    RtspDescribeResult(
      statusCode: 200,
      authRequired: true,
      videoCodecs: <String>['H265'],
    ),
  );
  Result<HttpHeadResult> http = const Ok<HttpHeadResult>(
    HttpHeadResult(statusCode: 200, contentType: 'multipart/x-mixed-replace'),
  );
  final List<String> calls = <String>[];

  @override
  Future<bool> resolves(String host) async {
    calls.add('dns $host');
    return dnsOk;
  }

  @override
  Future<Result<void>> tcpConnect(String host, int port) async {
    calls.add('tcp $host:$port');
    return tcp;
  }

  @override
  Future<Result<RtspDescribeResult>> describeRtsp(
    Uri uri,
    CameraCredentials c,
  ) async {
    calls.add('rtsp $uri');
    return rtsp;
  }

  @override
  Future<Result<HttpHeadResult>> probeHttp(Uri uri, CameraCredentials c) async {
    calls.add('http $uri');
    return http;
  }
}
