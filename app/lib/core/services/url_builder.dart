import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// Which list of paths of a brand.
enum PathKind { main, sub, mjpeg, snapshot }

/// Builds stream addresses from a camera's settings and from brand templates.
/// Credentials never appear in a built address.
class UrlBuilder {
  UrlBuilder._();

  /// Fills the placeholders of a brand path template: `{channel}` (1, 2, ...),
  /// `{channel0}` (0, 1, ...) and `{channel2}` (01, 02, ...).
  static String expand(String template, {int channel = 1}) {
    return template
        .replaceAll('{channel}', '$channel')
        .replaceAll('{channel0}', '${channel - 1}')
        .replaceAll('{channel2}', channel.toString().padLeft(2, '0'));
  }

  /// The ready-to-try paths of [brand] for [kind] and [channel].
  static List<String> pathsFor(
    CameraBrandProfile brand, {
    required PathKind kind,
    int channel = 1,
  }) {
    final List<String> templates = switch (kind) {
      PathKind.main => brand.mainPathTemplates,
      PathKind.sub => brand.subPathTemplates,
      PathKind.mjpeg => brand.mjpegTemplates,
      PathKind.snapshot => brand.snapshotTemplates,
    };
    return <String>[for (final String t in templates) expand(t, channel: channel)];
  }

  /// A host name, an IPv4 address or an IPv6 address: letters, digits, dots,
  /// hyphens, underscores and (for IPv6) colons. Anything else, such as spaces
  /// or slashes, cannot be a camera address.
  static bool isValidHost(String host) {
    return host.isNotEmpty && RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(host);
  }

  /// A path with a leading slash. A query string is kept.
  static String normalizePath(String path) {
    final String trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '/';
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  /// The address of one of a camera's streams: `rtsp://host:port/path` for RTSP
  /// cameras and `http://host:port/path` for the others. Null when the host,
  /// port or path cannot make a valid address. The grid asks for the substream
  /// and falls back to the main stream when a camera has none.
  static Uri? streamUri(Camera camera, {StreamKind kind = StreamKind.main}) {
    final String host = camera.host.trim().replaceAll(RegExp(r'^\[|\]$'), '');
    if (!isValidHost(host) || camera.port < 1 || camera.port > 65535) {
      return null;
    }
    final String raw = normalizePath(
      kind == StreamKind.sub && camera.hasSubstream
          ? camera.subPath!
          : camera.mainPath,
    );
    final int question = raw.indexOf('?');
    final String path = question < 0 ? raw : raw.substring(0, question);
    final String? query = question < 0 || question == raw.length - 1
        ? null
        : raw.substring(question + 1);
    try {
      return Uri(
        scheme: camera.protocol == StreamProtocol.rtsp ? 'rtsp' : 'http',
        host: host,
        port: camera.port,
        path: path,
        query: query,
      );
    } on FormatException {
      return null;
    }
  }
}
