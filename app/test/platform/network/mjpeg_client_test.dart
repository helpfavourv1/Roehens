import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/platform/network/mjpeg_client.dart';

import '../../support/mjpeg_fixtures.dart';

typedef Handler = FutureOr<void> Function(HttpRequest request);

Future<Uri> serve(Handler handler) async {
  final HttpServer server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((HttpRequest request) async {
    try {
      await handler(request);
    } catch (_) {
      // The client may disconnect mid-write; that is part of some tests.
    }
  });
  return Uri.parse('http://127.0.0.1:${server.port}/video.mjpg');
}

Future<void> streamFrames(HttpRequest request, List<Uint8List> frames) async {
  final HttpResponse response = request.response;
  response.bufferOutput = false;
  response.headers.set(
    HttpHeaders.contentTypeHeader,
    'multipart/x-mixed-replace; boundary=frame',
  );
  for (final Uint8List frame in frames) {
    response.add(multipartPart(frame));
    await response.flush();
  }
  await response.close();
}

Future<(List<Uint8List>, Object?)> collect(Stream<Uint8List> stream) async {
  final List<Uint8List> frames = <Uint8List>[];
  Object? error;
  try {
    await for (final Uint8List frame in stream) {
      frames.add(frame);
    }
  } catch (e) {
    error = e;
  }
  return (frames, error);
}

void main() {
  final List<Uint8List> frames = <Uint8List>[
    for (int i = 0; i < 4; i++) fakeJpeg(i, size: 500 + i * 100),
  ];

  test('streams every frame in order and ends when the server closes', () async {
    final Uri uri = await serve((HttpRequest r) => streamFrames(r, frames));
    final (List<Uint8List> got, Object? error) =
        await collect(MjpegClient().frames(uri));
    expect(error, isNull);
    expect(got.length, frames.length);
    for (int i = 0; i < frames.length; i++) {
      expect(got[i], frames[i]);
    }
  });

  test('answers a Basic authentication challenge', () async {
    final String expected =
        'Basic ${base64.encode(utf8.encode('admin:pw12345'))}';
    final Uri uri = await serve((HttpRequest r) async {
      if (r.headers.value(HttpHeaders.authorizationHeader) != expected) {
        r.response.statusCode = HttpStatus.unauthorized;
        r.response.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          'Basic realm="cam"',
        );
        await r.response.close();
        return;
      }
      await streamFrames(r, frames);
    });

    final (List<Uint8List> got, Object? error) = await collect(
      MjpegClient().frames(
        uri,
        credentials: const CameraCredentials(
          username: 'admin',
          password: 'pw12345',
        ),
      ),
    );
    expect(error, isNull);
    expect(got.length, frames.length);
  });

  test('wrong or missing credentials are reported as an authentication failure', () async {
    final Uri uri = await serve((HttpRequest r) async {
      r.response.statusCode = HttpStatus.unauthorized;
      r.response.headers.set(
        HttpHeaders.wwwAuthenticateHeader,
        'Basic realm="cam"',
      );
      await r.response.close();
    });

    final (List<Uint8List> got, Object? error) =
        await collect(MjpegClient().frames(uri));
    expect(got, isEmpty);
    expect(error, isA<AppError>());
    expect((error! as AppError).errorClass, ErrorClass.authFailed);
  });

  test('wrong credentials fail fast instead of retrying until a timeout', () async {
    final Uri uri = await serve((HttpRequest r) async {
      r.response.statusCode = HttpStatus.unauthorized;
      r.response.headers.set(
        HttpHeaders.wwwAuthenticateHeader,
        'Basic realm="cam"',
      );
      await r.response.close();
    });
    final Stopwatch clock = Stopwatch()..start();
    final (List<Uint8List> got, Object? error) = await collect(
      MjpegClient(connectTimeout: const Duration(seconds: 8)).frames(
        uri,
        credentials: const CameraCredentials(username: 'admin', password: 'wrong'),
      ),
    );
    expect(got, isEmpty);
    expect((error! as AppError).errorClass, ErrorClass.authFailed);
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('HTTP statuses map to the documented error classes', () async {
    for (final (int status, ErrorClass expected) in <(int, ErrorClass)>[
      (HttpStatus.notFound, ErrorClass.pathNotFound),
      (HttpStatus.serviceUnavailable, ErrorClass.networkUnreachable),
    ]) {
      final Uri uri = await serve((HttpRequest r) async {
        r.response.statusCode = status;
        await r.response.close();
      });
      final (List<Uint8List> got, Object? error) =
          await collect(MjpegClient().frames(uri));
      expect(got, isEmpty);
      expect((error! as AppError).errorClass, expected, reason: '$status');
    }
  });

  test('a stalled stream is reported as dropped after the idle timeout', () async {
    final Uri uri = await serve((HttpRequest r) async {
      final HttpResponse response = r.response;
      response.bufferOutput = false;
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/x-mixed-replace; boundary=frame',
      );
      response.add(multipartPart(frames[0]));
      await response.flush();
      await Future<void>.delayed(const Duration(seconds: 5));
    });

    final (List<Uint8List> got, Object? error) = await collect(
      MjpegClient(idleTimeout: const Duration(milliseconds: 300)).frames(uri),
    );
    expect(got.length, 1);
    expect((error! as AppError).errorClass, ErrorClass.networkUnreachable);
  });

  test('an unreachable host is a network error', () async {
    final HttpServer closed =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final int port = closed.port;
    await closed.close(force: true);
    final (List<Uint8List> got, Object? error) = await collect(
      MjpegClient(connectTimeout: const Duration(seconds: 2)).frames(
        Uri.parse('http://127.0.0.1:$port/video.mjpg'),
      ),
    );
    expect(got, isEmpty);
    expect((error! as AppError).errorClass, ErrorClass.networkUnreachable);
  });

  test('cancelling the subscription closes the HTTP client', () async {
    final Uri uri = await serve((HttpRequest r) async {
      final HttpResponse response = r.response;
      response.bufferOutput = false;
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/x-mixed-replace; boundary=frame',
      );
      for (int i = 0; i < 250; i++) {
        response.add(multipartPart(frames[i % frames.length]));
        await response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await response.close();
    });

    late HttpClient created;
    final MjpegClient client =
        MjpegClient(clientFactory: () => created = HttpClient());
    final Completer<void> first = Completer<void>();
    final StreamSubscription<Uint8List> subscription =
        client.frames(uri).listen((Uint8List frame) {
      if (!first.isCompleted) {
        first.complete();
      }
    });
    await first.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('no frame arrived'),
    );
    await subscription.cancel();

    // A closed HttpClient refuses new requests.
    expect(() => created.getUrl(uri), throwsStateError);
  });

  group('single images', () {
    test('a snapshot address returns one JPEG', () async {
      final Uint8List image = fakeJpeg(9);
      final Uri uri = await serve((HttpRequest r) async {
        r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
        r.response.add(image);
        await r.response.close();
      });
      expect(await MjpegClient().fetchSnapshot(uri), image);
    });

    test('a snapshot that is not a complete JPEG is unsupported media', () async {
      final Uri uri = await serve((HttpRequest r) async {
        r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
        r.response.add(utf8.encode('<html>error</html>'));
        await r.response.close();
      });
      try {
        await MjpegClient().fetchSnapshot(uri);
        fail('expected an AppError');
      } on AppError catch (error) {
        expect(error.errorClass, ErrorClass.unsupportedMedia);
      }
    });

    test('a stream address that serves one image yields one frame', () async {
      final Uint8List image = fakeJpeg(3);
      final Uri uri = await serve((HttpRequest r) async {
        r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
        r.response.add(image);
        await r.response.close();
      });
      final (List<Uint8List> got, Object? error) =
          await collect(MjpegClient().frames(uri));
      expect(error, isNull);
      expect(got, <Uint8List>[image]);
    });
  });
}
