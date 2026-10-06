import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/platform/player/mjpeg_session.dart';

import '../../support/async_helpers.dart';
import '../../support/local_http.dart';
import '../../support/mjpeg_fixtures.dart';

PlayerSource sourceFor(Uri uri) {
  return PlayerSource(uri: uri, protocol: StreamProtocol.mjpeg);
}

Future<void> sendFrames(
  HttpRequest request,
  List<Uint8List> frames, {
  Duration hold = Duration.zero,
}) async {
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
  await Future<void>.delayed(hold);
  await response.close();
}

void main() {
  final List<Uint8List> frames = <Uint8List>[
    for (int i = 0; i < 3; i++) fakeSizedJpeg(640, 480, id: i),
  ];

  test('goes from connecting to playing and exposes frame and size', () async {
    final Uri uri = await serveLocal(
      (HttpRequest r) => sendFrames(r, frames, hold: const Duration(seconds: 3)),
    );
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);

    expect(session.state.value, isA<PlayerIdle>());
    final Future<void> opening = session.open(sourceFor(uri));
    expect(session.state.value, isA<PlayerConnecting>());
    await opening;

    await waitUntil(() => session.state.value is PlayerPlaying);
    await waitUntil(() => session.latestFrame.value == frames.last);
    expect(session.videoSize.value, const VideoSize(640, 480));
    expect(await session.captureFrame(), frames.last);
  });

  test('there is no frame before the first one arrives', () async {
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);
    expect(session.latestFrame.value, isNull);
    expect(await session.captureFrame(), isNull);
  });

  test('a server that closes the stream is reported as dropped', () async {
    final Uri uri = await serveLocal((HttpRequest r) => sendFrames(r, frames));
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);
    await session.open(sourceFor(uri));

    await waitUntil(() => session.state.value is PlayerError);
    final PlayerError error = session.state.value as PlayerError;
    expect(error.error.errorClass, ErrorClass.streamDropped);
  });

  test('wrong credentials are an authentication failure', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.statusCode = HttpStatus.unauthorized;
      r.response.headers.set(
        HttpHeaders.wwwAuthenticateHeader,
        'Basic realm="cam"',
      );
      await r.response.close();
    });
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);
    await session.open(sourceFor(uri));

    await waitUntil(() => session.state.value is PlayerError);
    expect(
      (session.state.value as PlayerError).error.errorClass,
      ErrorClass.authFailed,
    );
  });

  test('stop ends the stream and later frames are ignored', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      final HttpResponse response = r.response;
      response.bufferOutput = false;
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/x-mixed-replace; boundary=frame',
      );
      for (int i = 0; i < 100; i++) {
        response.add(multipartPart(fakeSizedJpeg(640, 480, id: i)));
        await response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await response.close();
    });
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);
    await session.open(sourceFor(uri));
    await waitUntil(() => session.state.value is PlayerPlaying);

    await session.stop();
    expect(session.state.value, isA<PlayerStopped>());
    final Uint8List? frozen = session.latestFrame.value;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(session.latestFrame.value, frozen);
    expect(session.state.value, isA<PlayerStopped>());
  });

  test('the same session can be opened again after a failure', () async {
    final Uri bad = await serveLocal((HttpRequest r) async {
      r.response.statusCode = HttpStatus.serviceUnavailable;
      await r.response.close();
    });
    final Uri good = await serveLocal(
      (HttpRequest r) => sendFrames(r, frames, hold: const Duration(seconds: 3)),
    );
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);

    await session.open(sourceFor(bad));
    await waitUntil(() => session.state.value is PlayerError);

    await session.open(sourceFor(good));
    await waitUntil(() => session.state.value is PlayerPlaying);
    await waitUntil(() => session.latestFrame.value == frames.last);
  });

  test('the view handle is the frame notifier', () {
    final MjpegSession session = MjpegSession();
    addTearDown(session.dispose);
    expect(session.viewHandle, same(session.latestFrame));
  });
}
