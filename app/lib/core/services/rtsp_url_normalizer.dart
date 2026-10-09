import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// A pasted camera address taken apart.
class ParsedStreamAddress {
  const ParsedStreamAddress({
    required this.protocol,
    required this.host,
    required this.port,
    required this.path,
    this.username,
    this.password,
    this.schemeAssumed = false,
  });

  final StreamProtocol protocol;
  final String host;
  final int port;

  /// Path with its query string, always starting with `/`.
  final String path;

  /// Login found in the address. It belongs in the secure vault, never in the
  /// stored path.
  final String? username;
  final String? password;

  /// The text had no scheme, so `rtsp://` was assumed.
  final bool schemeAssumed;
}

/// Understands what people paste into the address field: full RTSP and HTTP
/// addresses with or without a login, or just `host/path`.
class RtspUrlNormalizer {
  RtspUrlNormalizer._();

  static Result<ParsedStreamAddress> parse(String input) {
    String text = input.trim();
    if (text.isEmpty) {
      return _error(ErrorClass.pathNotFound, 'address is empty');
    }
    bool assumed = false;
    if (!text.contains('://')) {
      text = 'rtsp://$text';
      assumed = true;
    }
    final Uri uri;
    try {
      uri = Uri.parse(text);
    } on FormatException {
      return _error(ErrorClass.pathNotFound, 'address is not valid');
    }

    final String scheme = uri.scheme.toLowerCase();
    if (scheme == 'rtsps' || scheme == 'https') {
      return _error(ErrorClass.unsupportedMedia, 'encrypted addresses are not supported');
    }
    if (scheme != 'rtsp' && scheme != 'http') {
      return _error(ErrorClass.unsupportedMedia, 'unknown address type "$scheme"');
    }
    final String host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return _error(ErrorClass.pathNotFound, 'address has no host');
    }

    final bool isRtsp = scheme == 'rtsp';
    final int port = uri.hasPort ? uri.port : (isRtsp ? 554 : 80);
    if (port < 1 || port > 65535) {
      return _error(ErrorClass.pathNotFound, 'port is out of range');
    }

    final String rawPath = uri.path.isEmpty ? '/' : uri.path;
    final String path = uri.hasQuery ? '$rawPath?${uri.query}' : rawPath;

    String? username;
    String? password;
    if (uri.userInfo.isNotEmpty) {
      final int colon = uri.userInfo.indexOf(':');
      final String user = colon < 0 ? uri.userInfo : uri.userInfo.substring(0, colon);
      final String pass = colon < 0 ? '' : uri.userInfo.substring(colon + 1);
      username = _decode(user);
      password = _decode(pass);
    }

    return Ok<ParsedStreamAddress>(
      ParsedStreamAddress(
        protocol: isRtsp ? StreamProtocol.rtsp : _httpKind(path),
        host: host,
        port: port,
        path: path,
        username: username,
        password: password,
        schemeAssumed: assumed,
      ),
    );
  }

  /// A still-image address is polled; anything else is treated as MJPEG.
  static StreamProtocol _httpKind(String path) {
    final String lower = path.toLowerCase();
    final bool isStill = lower.contains('snapshot') ||
        lower.contains('/image') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.contains('/picture');
    final bool isStream = lower.contains('mjpg') ||
        lower.contains('mjpeg') ||
        lower.contains('video') ||
        lower.contains('stream');
    return isStill && !isStream ? StreamProtocol.httpSnapshot : StreamProtocol.mjpeg;
  }

  static String _decode(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
  }

  static Result<ParsedStreamAddress> _error(ErrorClass errorClass, String detail) {
    return Err<ParsedStreamAddress>(AppError(errorClass, detail: detail));
  }
}
