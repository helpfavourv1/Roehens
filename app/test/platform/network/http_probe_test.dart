import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/platform/network/http_probe.dart';

import '../../support/local_http.dart';

void main() {
  test('reads status, content type and server without the body', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.headers.set(HttpHeaders.serverHeader, 'TestCam/1.0');
      r.response.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/x-mixed-replace; boundary=frame',
      );
      r.response.add(<int>[1, 2, 3]);
      await r.response.flush();
      // Never close: an MJPEG stream does not end.
      await Future<void>.delayed(const Duration(seconds: 10));
    });
    final Stopwatch clock = Stopwatch()..start();
    final HttpProbeResult result = (await HttpProbe().get(uri)).valueOrNull!;
    expect(clock.elapsedMilliseconds, lessThan(3000));
    expect(result.ok, isTrue);
    expect(result.isMultipartStream, isTrue);
    expect(result.isImage, isFalse);
    expect(result.server, 'TestCam/1.0');
  });

  test('an image address is recognized', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
      await r.response.close();
    });
    final HttpProbeResult result = (await HttpProbe().get(uri)).valueOrNull!;
    expect(result.isImage, isTrue);
    expect(result.isMultipartStream, isFalse);
  });

  test('a missing page is reported as a status, not an error', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.statusCode = HttpStatus.notFound;
      await r.response.close();
    });
    final HttpProbeResult result = (await HttpProbe().get(uri)).valueOrNull!;
    expect(result.statusCode, 404);
    expect(result.ok, isFalse);
  });

  test('a Basic challenge is answered with the credentials', () async {
    const String expected = 'Basic YWRtaW46cHcxMjM0NQ==';
    final Uri uri = await serveLocal((HttpRequest r) async {
      if (r.headers.value(HttpHeaders.authorizationHeader) != expected) {
        r.response.statusCode = HttpStatus.unauthorized;
        r.response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Basic realm="cam"');
      }
      await r.response.close();
    });
    final HttpProbeResult accepted = (await HttpProbe().get(
      uri,
      credentials: const CameraCredentials(username: 'admin', password: 'pw12345'),
    ))
        .valueOrNull!;
    expect(accepted.ok, isTrue);

    final HttpProbeResult rejected = (await HttpProbe().get(uri)).valueOrNull!;
    expect(rejected.statusCode, 401);
  });

  test('wrong credentials give a 401 quickly', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.statusCode = HttpStatus.unauthorized;
      r.response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Basic realm="cam"');
      await r.response.close();
    });
    final Stopwatch clock = Stopwatch()..start();
    final HttpProbeResult result = (await HttpProbe().get(
      uri,
      credentials: const CameraCredentials(username: 'admin', password: 'wrong'),
    ))
        .valueOrNull!;
    expect(result.statusCode, 401);
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('an unreachable host is a network error', () async {
    final HttpServer closed =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final int port = closed.port;
    await closed.close(force: true);
    final Result<HttpProbeResult> result = await HttpProbe(
      timeout: const Duration(seconds: 2),
    ).get(Uri.parse('http://127.0.0.1:$port/'));
    final AppError error = result.errorOrNull!;
    expect(error.errorClass, ErrorClass.networkUnreachable);
  });
}
