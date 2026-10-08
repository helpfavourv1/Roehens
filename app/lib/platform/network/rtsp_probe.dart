import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/http_auth.dart';

/// The answer to an RTSP DESCRIBE.
class RtspProbeResult {
  RtspProbeResult({
    required this.statusCode,
    required this.statusText,
    required this.authRequired,
    required this.elapsed,
    this.server,
    String sdp = '',
  })  : videoCodecs = _codecs(sdp, 'video'),
        audioCodecs = _codecs(sdp, 'audio');

  final int statusCode;
  final String statusText;

  /// The camera asked for a login (answered 401 to the first request).
  final bool authRequired;
  final Duration elapsed;
  final String? server;

  /// Codec names from the stream description, for example `H264` or `H265`.
  final List<String> videoCodecs;
  final List<String> audioCodecs;

  bool get ok => statusCode == 200;
  bool get authFailed => statusCode == 401 || statusCode == 403;
  bool get notFound => statusCode == 404;

  static List<String> _codecs(String sdp, String media) {
    final List<String> found = <String>[];
    String? current;
    for (final String line in const LineSplitter().convert(sdp)) {
      if (line.startsWith('m=')) {
        current = line.substring(2).split(' ').first;
      } else if (line.startsWith('a=rtpmap:') && current == media) {
        final List<String> parts = line.split(' ');
        if (parts.length > 1) {
          final String name = parts[1].split('/').first.toUpperCase();
          if (!found.contains(name)) {
            found.add(name);
          }
        }
      }
    }
    return found;
  }
}

class _Reply {
  const _Reply(this.status, this.text, this.headers, this.body);

  final int status;
  final String text;
  final Map<String, List<String>> headers;
  final String body;
}

/// Sends an RTSP DESCRIBE to see whether a camera is reachable, whether it
/// wants a login, whether the path exists, and what codecs it offers. Answers a
/// Basic or Digest challenge with the given credentials. No media is requested.
class RtspProbe {
  RtspProbe({
    this.timeout = const Duration(seconds: 8),
    this.errorMapper = const ErrorMapper(),
  });

  final Duration timeout;
  final ErrorMapper errorMapper;

  Future<Result<RtspProbeResult>> describe(
    Uri uri, {
    CameraCredentials credentials = CameraCredentials.none,
  }) async {
    final Stopwatch clock = Stopwatch()..start();
    try {
      final _Reply first = await _exchange(uri, null);
      _Reply last = first;
      if (first.status == 401 && !credentials.isEmpty) {
        final String? authorization = HttpAuth.answer(
          headers: first.headers['www-authenticate'] ?? const <String>[],
          method: 'DESCRIBE',
          uri: _target(uri),
          username: credentials.username,
          password: credentials.password,
        );
        if (authorization != null) {
          last = await _exchange(uri, authorization);
        }
      }
      return Ok<RtspProbeResult>(
        RtspProbeResult(
          statusCode: last.status,
          statusText: last.text,
          authRequired: first.status == 401,
          elapsed: clock.elapsed,
          server: last.headers['server']?.first,
          sdp: last.body,
        ),
      );
    } on AppError catch (error) {
      return Err<RtspProbeResult>(error);
    } catch (error) {
      return Err<RtspProbeResult>(errorMapper.fromException(error));
    }
  }

  /// The request address without credentials.
  static String _target(Uri uri) {
    return Uri(
      scheme: 'rtsp',
      host: uri.host,
      port: uri.hasPort ? uri.port : 554,
      path: uri.path.isEmpty ? '/' : uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }

  Future<_Reply> _exchange(Uri uri, String? authorization) async {
    final int port = uri.hasPort ? uri.port : 554;
    final Socket socket =
        await Socket.connect(uri.host, port, timeout: timeout);
    try {
      final StringBuffer request = StringBuffer()
        ..write('DESCRIBE ${_target(uri)} RTSP/1.0\r\n')
        ..write('CSeq: ${authorization == null ? 1 : 2}\r\n')
        ..write('Accept: application/sdp\r\n')
        ..write('User-Agent: Roehens\r\n');
      if (authorization != null) {
        request.write('Authorization: $authorization\r\n');
      }
      request.write('\r\n');
      socket.write(request.toString());
      await socket.flush();

      final BytesBuilder received = BytesBuilder();
      await for (final Uint8List chunk in socket.timeout(timeout)) {
        received.add(chunk);
        if (_isComplete(received.toBytes())) {
          break;
        }
      }
      final Uint8List bytes = received.toBytes();
      if (bytes.isEmpty) {
        throw const AppError(
          ErrorClass.streamDropped,
          detail: 'connection closed without an answer',
        );
      }
      return _parse(bytes);
    } finally {
      socket.destroy();
    }
  }

  static int _headerEnd(Uint8List bytes) {
    for (int i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10 && bytes[i + 2] == 13 && bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  static bool _isComplete(Uint8List bytes) {
    final int end = _headerEnd(bytes);
    if (end < 0) {
      return false;
    }
    final String head = latin1.decode(bytes.sublist(0, end)).toLowerCase();
    final Match? length = RegExp(r'content-length:\s*(\d+)').firstMatch(head);
    final int expected = length == null ? 0 : int.parse(length.group(1)!);
    return bytes.length - (end + 4) >= expected;
  }

  static _Reply _parse(Uint8List bytes) {
    final int end = _headerEnd(bytes);
    final String head =
        latin1.decode(end < 0 ? bytes : bytes.sublist(0, end));
    final List<String> lines = const LineSplitter().convert(head);
    final List<String> status = lines.first.split(' ');
    final int code = status.length > 1 ? int.tryParse(status[1]) ?? 0 : 0;
    final String text = status.length > 2 ? status.sublist(2).join(' ') : '';
    final Map<String, List<String>> headers = <String, List<String>>{};
    for (final String line in lines.skip(1)) {
      final int colon = line.indexOf(':');
      if (colon > 0) {
        headers
            .putIfAbsent(line.substring(0, colon).trim().toLowerCase(), () => <String>[])
            .add(line.substring(colon + 1).trim());
      }
    }
    final String body =
        end < 0 ? '' : utf8.decode(bytes.sublist(end + 4), allowMalformed: true);
    return _Reply(code, text, headers, body);
  }
}
