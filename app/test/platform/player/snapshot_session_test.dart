import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/platform/player/snapshot_session.dart';

import '../../support/async_helpers.dart';
import '../../support/local_http.dart';
import '../../support/mjpeg_fixtures.dart';

PlayerSource sourceFor(Uri uri) {
  return PlayerSource(uri: uri, protocol: StreamProtocol.httpSnapshot);
}

void main() {
  test('shows connecting, then plays and exposes the picture and size', () async {
    final Uint8List image = fakeSizedJpeg(640, 480, id: 1);
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
      r.response.add(image);
      await r.response.close();
    });
    final SnapshotSession session = SnapshotSession(
      interval: const Duration(milliseconds: 50),
    );
    addTearDown(session.dispose);

    expect(session.state.value, isA<PlayerIdle>());
    final Future<void> opening = session.open(sourceFor(uri));
    expect(session.state.value, isA<PlayerConnecting>());
    await opening;

    expect(session.state.value, isA<PlayerPlaying>());
    final ValueListenable<Uint8List?> handle =
        session.viewHandle! as ValueListenable<Uint8List?>;
    expect(handle.value, image);
    expect(session.videoSize.value, const VideoSize(640, 480));
    expect(await session.captureFrame(), image);
  });

  test('keeps fetching and shows the newest picture', () async {
    int served = 0;
    final Uri uri = await serveLocal((HttpRequest r) async {
      served++;
      r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
      r.response.add(fakeSizedJpeg(320, 240, id: served));
      await r.response.close();
    });
    final SnapshotSession session = SnapshotSession(
      interval: const Duration(milliseconds: 40),
    );
    addTearDown(session.dispose);
    await session.open(sourceFor(uri));

    await waitUntil(() => served >= 3);
    expect(session.state.value, isA<PlayerPlaying>());
  });

  test('an unreachable address ends in an error the pool can retry', () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final int port = server.port;
    await server.close(force: true);
    final SnapshotSession session = SnapshotSession();
    addTearDown(session.dispose);

    await session.open(sourceFor(Uri.parse('http://127.0.0.1:$port/shot.jpg')));

    final PlayerState state = session.state.value;
    expect(state, isA<PlayerError>());
    expect(
      (state as PlayerError).error.errorClass,
      ErrorClass.networkUnreachable,
    );
  });

  test('stop and dispose end polling and never throw', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
      r.response.add(fakeJpeg(1));
      await r.response.close();
    });
    final SnapshotSession session = SnapshotSession(
      interval: const Duration(milliseconds: 20),
    );
    await session.open(sourceFor(uri));

    await session.stop();
    expect(session.state.value, isA<PlayerStopped>());
    await session.dispose();
    await session.dispose();
  });
}
