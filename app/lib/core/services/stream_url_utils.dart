import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// Pure helpers for turning a camera's settings into what the engine needs.
class StreamUrlUtils {
  StreamUrlUtils._();

  /// [uri] with [credentials] placed in its user-info part, for engines that
  /// take credentials from the address. Characters such as `@` and spaces are
  /// percent-encoded. The result must never be logged.
  static Uri withCredentials(Uri uri, CameraCredentials credentials) {
    if (credentials.isEmpty) {
      return uri;
    }
    // Uri.replace does not encode user-info, so each part is encoded here.
    final String user = Uri.encodeComponent(credentials.username);
    final String password = Uri.encodeComponent(credentials.password);
    return uri.replace(userInfo: '$user:$password');
  }

  /// The RTSP transport to force, or null to let the engine choose.
  ///
  /// While the bundled engine has no UDP support ([udpAvailable] false), `udp`
  /// and `auto` both fall back to TCP, which every camera accepts.
  static String? rtspTransportOption(
    StreamTransport transport, {
    required bool udpAvailable,
  }) {
    switch (transport) {
      case StreamTransport.tcp:
        return 'tcp';
      case StreamTransport.udp:
        return udpAvailable ? 'udp' : 'tcp';
      case StreamTransport.auto:
        return udpAvailable ? null : 'tcp';
    }
  }
}
