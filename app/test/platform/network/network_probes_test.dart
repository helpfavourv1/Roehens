import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/platform/network/network_probes.dart';

import '../../support/local_http.dart';

void main() {
  final NetworkProbes probes = NetworkProbes(timeout: const Duration(seconds: 3));

  test('localhost resolves and a nonsense name does not', () async {
    expect(await probes.resolves('localhost'), isTrue);
    expect(await probes.resolves('no-such-host.invalid'), isFalse);
  });

  test('a listening port connects and a closed one is a network error', () async {
    final ServerSocket open = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(open.close);
    expect((await probes.tcpConnect('127.0.0.1', open.port)).isOk, isTrue);

    final ServerSocket gone = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final int port = gone.port;
    await gone.close();
    final Result<void> closed = await probes.tcpConnect('127.0.0.1', port);
    expect(closed.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
  });

  test('an RTSP answer is converted with its codecs', () async {
    const String sdp = 'm=video 0 RTP/AVP 96\r\na=rtpmap:96 H264/90000\r\n';
    final ServerSocket server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((Socket socket) {
      socket.listen((List<int> data) async {
        socket.write('RTSP/1.0 200 OK\r\nContent-Length: ${sdp.length}\r\n\r\n$sdp');
        await socket.flush();
        await socket.close();
      });
    });
    final RtspDescribeResult reply = (await probes.describeRtsp(
      Uri.parse('rtsp://127.0.0.1:${server.port}/s'),
      CameraCredentials.none,
    ))
        .valueOrNull!;
    expect(reply.statusCode, 200);
    expect(reply.authRequired, isFalse);
    expect(reply.videoCodecs, <String>['H264']);
  });

  test('an HTTP answer is converted with its content type', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
      r.response.add(utf8.encode('x'));
      await r.response.close();
    });
    final HttpHeadResult reply =
        (await probes.probeHttp(uri, CameraCredentials.none)).valueOrNull!;
    expect(reply.statusCode, 200);
    expect(reply.isStreamOrImage, isTrue);
  });

  test('probe failures come back as errors', () async {
    final HttpServer gone = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final int port = gone.port;
    await gone.close(force: true);
    expect(
      (await probes.probeHttp(Uri.parse('http://127.0.0.1:$port/'), CameraCredentials.none)).isErr,
      isTrue,
    );
    expect(
      (await probes.describeRtsp(Uri.parse('rtsp://127.0.0.1:$port/'), CameraCredentials.none)).isErr,
      isTrue,
    );
  });
}
