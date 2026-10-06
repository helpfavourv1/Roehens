import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/stream_url_utils.dart';

void main() {
  group('withCredentials', () {
    test('empty credentials leave the address alone', () {
      final Uri uri = Uri.parse('rtsp://192.168.1.10:554/stream0');
      expect(StreamUrlUtils.withCredentials(uri, CameraCredentials.none), uri);
    });

    test('credentials go into the user-info part and the rest is kept', () {
      final Uri result = StreamUrlUtils.withCredentials(
        Uri.parse('rtsp://192.168.1.10:554/stream0?ch=1'),
        const CameraCredentials(username: 'admin', password: 'pw12345'),
      );
      expect(result.userInfo, 'admin:pw12345');
      expect(result.host, '192.168.1.10');
      expect(result.port, 554);
      expect(result.path, '/stream0');
      expect(result.query, 'ch=1');
    });

    test('special characters are percent-encoded and survive a round trip', () {
      final Uri result = StreamUrlUtils.withCredentials(
        Uri.parse('rtsp://cam.local/s'),
        const CameraCredentials(username: 'a@b', password: 'p w:rd/#'),
      );
      final String text = result.toString();
      expect('@'.allMatches(text).length, 1);
      expect(text.contains(' '), isFalse);
      expect(text.contains('#'), isFalse);
      final Uri parsed = Uri.parse(text);
      expect(parsed.host, 'cam.local');
      final List<String> parts = parsed.userInfo.split(':');
      expect(Uri.decodeComponent(parts.first), 'a@b');
    });
  });

  group('rtspTransportOption', () {
    test('tcp is always tcp', () {
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.tcp,
          udpAvailable: false,
        ),
        'tcp',
      );
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.tcp,
          udpAvailable: true,
        ),
        'tcp',
      );
    });

    test('without UDP support udp and auto fall back to tcp', () {
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.udp,
          udpAvailable: false,
        ),
        'tcp',
      );
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.auto,
          udpAvailable: false,
        ),
        'tcp',
      );
    });

    test('with UDP support udp is honored and auto lets the engine choose', () {
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.udp,
          udpAvailable: true,
        ),
        'udp',
      );
      expect(
        StreamUrlUtils.rtspTransportOption(
          StreamTransport.auto,
          udpAvailable: true,
        ),
        isNull,
      );
    });
  });
}
