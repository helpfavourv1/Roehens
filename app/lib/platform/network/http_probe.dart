import 'dart:async';
import 'dart:io';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/platform/network/http_credentials.dart';

/// What an HTTP address answered, without reading the body.
class HttpProbeResult {
  const HttpProbeResult({
    required this.statusCode,
    required this.contentType,
    required this.server,
    required this.elapsed,
  });

  final int statusCode;
  final String? contentType;
  final String? server;
  final Duration elapsed;

  bool get ok => statusCode == HttpStatus.ok;

  /// `multipart/x-mixed-replace`: an MJPEG stream.
  bool get isMultipartStream => (contentType ?? '').startsWith('multipart/');

  bool get isImage => (contentType ?? '').startsWith('image/');
}

/// Checks an HTTP address for the connection tester: reachable, which status,
/// what kind of content. Reads the response headers and then closes, so it is
/// safe to point at an endless MJPEG stream.
class HttpProbe {
  HttpProbe({
    this.timeout = const Duration(seconds: 8),
    this.errorMapper = const ErrorMapper(),
  });

  final Duration timeout;
  final ErrorMapper errorMapper;

  Future<Result<HttpProbeResult>> get(
    Uri uri, {
    CameraCredentials credentials = CameraCredentials.none,
  }) async {
    final Stopwatch clock = Stopwatch()..start();
    final HttpClient client = HttpClient()..connectionTimeout = timeout;
    answerChallengeOnce(client, credentials);
    try {
      final HttpClientRequest request = await client.getUrl(uri).timeout(timeout);
      final HttpClientResponse response = await request.close().timeout(timeout);
      final HttpProbeResult result = HttpProbeResult(
        statusCode: response.statusCode,
        contentType: response.headers.contentType?.mimeType,
        server: response.headers.value(HttpHeaders.serverHeader),
        elapsed: clock.elapsed,
      );
      // Do not read the body: it may never end.
      return Ok<HttpProbeResult>(result);
    } on AppError catch (error) {
      return Err<HttpProbeResult>(error);
    } catch (error) {
      return Err<HttpProbeResult>(errorMapper.fromException(error));
    } finally {
      client.close(force: true);
    }
  }
}
