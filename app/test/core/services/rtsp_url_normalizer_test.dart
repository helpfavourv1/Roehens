import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/rtsp_url_normalizer.dart';

ParsedStreamAddress ok(String input) => RtspUrlNormalizer.parse(input).valueOrNull!;

ErrorClass? errorOf(String input) =>
    RtspUrlNormalizer.parse(input).errorOrNull?.errorClass;

void main() {
  group('RTSP addresses', () {
    test('a full address with a login is taken apart', () {
      final ParsedStreamAddress a =
          ok('rtsp://admin:pw12345@192.168.1.64:554/Streaming/Channels/101');
      expect(a.protocol, StreamProtocol.rtsp);
      expect(a.host, '192.168.1.64');
      expect(a.port, 554);
      expect(a.path, '/Streaming/Channels/101');
      expect(a.username, 'admin');
      expect(a.password, 'pw12345');
      expect(a.schemeAssumed, isFalse);
    });

    test('the default port is 554', () {
      expect(ok('rtsp://cam.local/stream0').port, 554);
    });

    test('an address without a scheme is treated as RTSP', () {
      final ParsedStreamAddress a = ok('192.168.1.64:8554/live');
      expect(a.protocol, StreamProtocol.rtsp);
      expect(a.port, 8554);
      expect(a.path, '/live');
      expect(a.schemeAssumed, isTrue);
    });

    test('just a host gives the root path', () {
      expect(ok('192.168.1.64').path, '/');
    });

    test('surrounding spaces and an upper-case scheme and host are tolerated', () {
      final ParsedStreamAddress a = ok('  RTSP://Cam.LOCAL/Stream0  ');
      expect(a.host, 'cam.local');
      expect(a.path, '/Stream0');
    });

    test('a query string is kept in the path', () {
      expect(
        ok('rtsp://10.0.0.5/cam/realmonitor?channel=1&subtype=0').path,
        '/cam/realmonitor?channel=1&subtype=0',
      );
    });

    test('a fragment is dropped', () {
      expect(ok('rtsp://10.0.0.5/stream#top').path, '/stream');
    });

    test('percent-encoded credentials are decoded', () {
      final ParsedStreamAddress a = ok('rtsp://us%40er:p%20w%3Ard@10.0.0.5/s');
      expect(a.username, 'us@er');
      expect(a.password, 'p w:rd');
    });

    test('a login without a password has an empty password', () {
      final ParsedStreamAddress a = ok('rtsp://admin@10.0.0.5/s');
      expect(a.username, 'admin');
      expect(a.password, '');
    });

    test('an address with no login has no credentials', () {
      final ParsedStreamAddress a = ok('rtsp://10.0.0.5/s');
      expect(a.username, isNull);
      expect(a.password, isNull);
    });

    test('an IPv6 host in brackets is understood', () {
      final ParsedStreamAddress a = ok('rtsp://[fe80::1]:554/s');
      expect(a.host, 'fe80::1');
      expect(a.port, 554);
    });
  });

  group('HTTP addresses', () {
    test('a stream address is MJPEG', () {
      final ParsedStreamAddress a = ok('http://10.0.0.5:8080/axis-cgi/mjpg/video.cgi');
      expect(a.protocol, StreamProtocol.mjpeg);
      expect(a.port, 8080);
    });

    test('the default HTTP port is 80', () {
      expect(ok('http://10.0.0.5/video.mjpg').port, 80);
    });

    test('a still-image address is polled as a snapshot', () {
      expect(ok('http://10.0.0.5/snapshot.jpg').protocol, StreamProtocol.httpSnapshot);
      expect(ok('http://10.0.0.5/cgi-bin/snapshot.cgi').protocol, StreamProtocol.httpSnapshot);
      expect(ok('http://10.0.0.5/jpg/image.jpg').protocol, StreamProtocol.httpSnapshot);
    });

    test('a stream address that mentions an image stays MJPEG', () {
      expect(ok('http://10.0.0.5/video/image.mjpg').protocol, StreamProtocol.mjpeg);
    });
  });

  group('addresses that cannot be used', () {
    test('empty input', () {
      expect(errorOf(''), isNotNull);
      expect(errorOf('   '), isNotNull);
    });

    test('encrypted schemes are not supported', () {
      expect(errorOf('rtsps://cam/s'), ErrorClass.unsupportedMedia);
      expect(errorOf('https://cam/s'), ErrorClass.unsupportedMedia);
    });

    test('other schemes are not supported', () {
      expect(errorOf('ftp://cam/s'), ErrorClass.unsupportedMedia);
      expect(errorOf('file:///etc/passwd'), isNotNull);
    });

    test('a missing host', () {
      expect(errorOf('rtsp:///stream0'), isNotNull);
    });

    test('a port out of range', () {
      expect(errorOf('rtsp://cam:70000/s'), isNotNull);
      expect(errorOf('rtsp://cam:0/s'), isNotNull);
    });

    test('garbage never throws', () {
      for (final String text in <String>['%%%', '://', 'rtsp://[', 'rtsp://a b/c']) {
        expect(() => RtspUrlNormalizer.parse(text), returnsNormally);
      }
    });
  });
}
