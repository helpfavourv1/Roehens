import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/http_auth.dart';
import 'package:roehens/platform/network/rtsp_probe.dart';

const String sdp = 'v=0\r\n'
    'm=video 0 RTP/AVP 96\r\n'
    'a=rtpmap:96 H265/90000\r\n'
    'm=audio 0 RTP/AVP 0\r\n'
    'a=rtpmap:0 PCMU/8000\r\n';

String ok() => 'RTSP/1.0 200 OK\r\nCSeq: 1\r\nServer: FakeCam\r\n'
    'Content-Type: application/sdp\r\nContent-Length: ${sdp.length}\r\n\r\n$sdp';

String unauthorized(String challenge) =>
    'RTSP/1.0 401 Unauthorized\r\nCSeq: 1\r\nWWW-Authenticate: $challenge\r\n'
    'Content-Length: 0\r\n\r\n';

String plain(int code, String text) =>
    'RTSP/1.0 $code $text\r\nCSeq: 1\r\nContent-Length: 0\r\n\r\n';

/// A pretend camera. [respond] gets the request text and the request number.
Future<Uri> serveRtsp(String Function(String request, int index) respond) async {
  final ServerSocket server =
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close());
  int index = 0;
  server.listen((Socket socket) {
    final StringBuffer buffer = StringBuffer();
    socket.listen((List<int> data) async {
      buffer.write(latin1.decode(data));
      if (buffer.toString().contains('\r\n\r\n')) {
        final String request = buffer.toString();
        buffer.clear();
        socket.write(respond(request, index++));
        await socket.flush();
        await socket.close();
      }
    }, onError: (Object _) {});
  });
  return Uri.parse('rtsp://127.0.0.1:${server.port}/stream0');
}

String? header(String request, String name) {
  for (final String line in const LineSplitter().convert(request)) {
    if (line.toLowerCase().startsWith('${name.toLowerCase()}:')) {
      return line.substring(name.length + 1).trim();
    }
  }
  return null;
}

void main() {
  test('an open camera answers with its codecs', () async {
    final Uri uri = await serveRtsp((String r, int i) => ok());
    final RtspProbeResult result = (await RtspProbe().describe(uri)).valueOrNull!;
    expect(result.ok, isTrue);
    expect(result.authRequired, isFalse);
    expect(result.videoCodecs, <String>['H265']);
    expect(result.audioCodecs, <String>['PCMU']);
    expect(result.server, 'FakeCam');
  });

  test('the request line carries no credentials', () async {
    String? firstLine;
    final Uri uri = await serveRtsp((String r, int i) {
      firstLine = r.split('\r\n').first;
      return ok();
    });
    final Uri withLogin = uri.replace(userInfo: 'admin:secret');
    await RtspProbe().describe(
      withLogin,
      credentials: const CameraCredentials(username: 'admin', password: 'secret'),
    );
    expect(firstLine, startsWith('DESCRIBE rtsp://127.0.0.1:'));
    expect(firstLine!.contains('@'), isFalse);
    expect(firstLine!.contains('secret'), isFalse);
  });

  test('a Digest challenge is answered correctly', () async {
    const String challenge = 'Digest realm="cam", nonce="abc123", qop="auth"';
    String? sentAuthorization;
    final Uri uri = await serveRtsp((String r, int i) {
      final String? authorization = header(r, 'Authorization');
      if (authorization == null) {
        return unauthorized(challenge);
      }
      sentAuthorization = authorization;
      return ok();
    });
    final RtspProbeResult result = (await RtspProbe().describe(
      uri,
      credentials: const CameraCredentials(username: 'admin', password: 'pw12345'),
    ))
        .valueOrNull!;
    expect(result.ok, isTrue);
    expect(result.authRequired, isTrue);

    // Recompute the response from what the client sent; it must agree.
    final Map<String, String> fields = <String, String>{
      for (final RegExpMatch m
          in RegExp(r'(\w+)=(?:"([^"]*)"|([^,\s]+))').allMatches(sentAuthorization!))
        m.group(1)!: m.group(2) ?? m.group(3)!,
    };
    final String expected = HttpAuth.digest(
      challenge: DigestChallenge.parse(challenge)!,
      method: 'DESCRIBE',
      uri: fields['uri']!,
      username: 'admin',
      password: 'pw12345',
      cnonce: fields['cnonce'],
    );
    expect(sentAuthorization, expected);
  });

  test('a Basic challenge is answered with Basic', () async {
    String? sent;
    final Uri uri = await serveRtsp((String r, int i) {
      sent = header(r, 'Authorization');
      return sent == null ? unauthorized('Basic realm="cam"') : ok();
    });
    final RtspProbeResult result = (await RtspProbe().describe(
      uri,
      credentials: const CameraCredentials(username: 'admin', password: 'pw12345'),
    ))
        .valueOrNull!;
    expect(result.ok, isTrue);
    expect(sent, 'Basic YWRtaW46cHcxMjM0NQ==');
  });

  test('wrong credentials end as an authentication failure', () async {
    final Uri uri = await serveRtsp(
      (String r, int i) => unauthorized('Digest realm="cam", nonce="n", qop="auth"'),
    );
    final RtspProbeResult result = (await RtspProbe().describe(
      uri,
      credentials: const CameraCredentials(username: 'admin', password: 'wrong'),
    ))
        .valueOrNull!;
    expect(result.authRequired, isTrue);
    expect(result.authFailed, isTrue);
    expect(result.ok, isFalse);
  });

  test('a login is required but none was given', () async {
    final Uri uri = await serveRtsp(
      (String r, int i) => unauthorized('Basic realm="cam"'),
    );
    final RtspProbeResult result = (await RtspProbe().describe(uri)).valueOrNull!;
    expect(result.authRequired, isTrue);
    expect(result.authFailed, isTrue);
  });

  test('a wrong path is reported as not found', () async {
    final Uri uri = await serveRtsp((String r, int i) => plain(404, 'Not Found'));
    final RtspProbeResult result = (await RtspProbe().describe(uri)).valueOrNull!;
    expect(result.notFound, isTrue);
    expect(result.statusText, 'Not Found');
  });

  test('nothing listening is a network error', () async {
    final ServerSocket closed =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final int port = closed.port;
    await closed.close();
    final Result<RtspProbeResult> result = await RtspProbe(
      timeout: const Duration(seconds: 2),
    ).describe(Uri.parse('rtsp://127.0.0.1:$port/s'));
    expect(result.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
  });

  test('a camera that never answers times out', () async {
    final ServerSocket silent =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => silent.close());
    silent.listen((Socket socket) {
      addTearDown(socket.destroy);
    });
    final Stopwatch clock = Stopwatch()..start();
    final Result<RtspProbeResult> result = await RtspProbe(
      timeout: const Duration(milliseconds: 400),
    ).describe(Uri.parse('rtsp://127.0.0.1:${silent.port}/s'));
    expect(result.isErr, isTrue);
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('a camera that hangs up without answering is a dropped stream', () async {
    final ServerSocket abrupt =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => abrupt.close());
    abrupt.listen((Socket socket) => socket.destroy());
    final Result<RtspProbeResult> result = await RtspProbe(
      timeout: const Duration(seconds: 2),
    ).describe(Uri.parse('rtsp://127.0.0.1:${abrupt.port}/s'));
    expect(result.isErr, isTrue);
  });
}
