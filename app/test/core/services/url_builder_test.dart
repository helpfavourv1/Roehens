import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/url_builder.dart';

import '../../support/fakes.dart';

Camera camera({
  String host = '192.168.1.64',
  int port = 554,
  String main = '/stream0',
  String? sub = '/stream1',
  StreamProtocol protocol = StreamProtocol.rtsp,
}) {
  return testCamera().copyWith(
    host: host,
    port: port,
    mainPath: main,
    subPath: sub,
    protocol: protocol,
  );
}

void main() {
  group('expand', () {
    test('fills every placeholder', () {
      expect(UrlBuilder.expand('/Streaming/Channels/{channel}01'), '/Streaming/Channels/101');
      expect(UrlBuilder.expand('/Streaming/Channels/{channel}01', channel: 3), '/Streaming/Channels/301');
      expect(UrlBuilder.expand('/ch{channel0}', channel: 1), '/ch0');
      expect(UrlBuilder.expand('/Preview_{channel2}_main', channel: 1), '/Preview_01_main');
      expect(UrlBuilder.expand('/Preview_{channel2}_main', channel: 12), '/Preview_12_main');
    });

    test('a template without placeholders is unchanged', () {
      expect(UrlBuilder.expand('/live'), '/live');
    });

    test('a query with several placeholders is expanded', () {
      expect(
        UrlBuilder.expand('/cam/realmonitor?channel={channel}&subtype=0', channel: 2),
        '/cam/realmonitor?channel=2&subtype=0',
      );
    });
  });

  group('pathsFor', () {
    const CameraBrandProfile brand = CameraBrandProfile(
      id: 'x',
      displayName: 'X',
      defaultPorts: <int>[554],
      mainPathTemplates: <String>['/m{channel}'],
      subPathTemplates: <String>['/s{channel}'],
      mjpegTemplates: <String>['/j'],
      snapshotTemplates: <String>['/p{channel2}'],
    );

    test('each kind lists its own paths', () {
      expect(UrlBuilder.pathsFor(brand, kind: PathKind.main, channel: 2), <String>['/m2']);
      expect(UrlBuilder.pathsFor(brand, kind: PathKind.sub), <String>['/s1']);
      expect(UrlBuilder.pathsFor(brand, kind: PathKind.mjpeg), <String>['/j']);
      expect(UrlBuilder.pathsFor(brand, kind: PathKind.snapshot), <String>['/p01']);
    });
  });

  group('isValidHost', () {
    test('accepts names and addresses', () {
      for (final String host in <String>['192.168.1.5', 'cam.local', 'my-cam_2', 'fe80::1']) {
        expect(UrlBuilder.isValidHost(host), isTrue, reason: host);
      }
    });

    test('rejects what cannot be a host', () {
      for (final String host in <String>['', 'a b', 'a/b', 'cam@x', 'a?b', 'a#b']) {
        expect(UrlBuilder.isValidHost(host), isFalse, reason: host);
      }
    });
  });

  group('normalizePath', () {
    test('adds the missing slash and keeps queries', () {
      expect(UrlBuilder.normalizePath('stream0'), '/stream0');
      expect(UrlBuilder.normalizePath('/stream0'), '/stream0');
      expect(UrlBuilder.normalizePath('  /a?b=1 '), '/a?b=1');
      expect(UrlBuilder.normalizePath(''), '/');
    });
  });

  group('streamUri', () {
    test('an RTSP camera gives an rtsp address with its port', () {
      final Uri uri = UrlBuilder.streamUri(camera())!;
      expect(uri.toString(), 'rtsp://192.168.1.64:554/stream0');
    });

    test('the substream is used when asked and when the camera has one', () {
      expect(
        UrlBuilder.streamUri(camera(), kind: StreamKind.sub)!.path,
        '/stream1',
      );
      expect(
        UrlBuilder.streamUri(camera(sub: null), kind: StreamKind.sub)!.path,
        '/stream0',
      );
      expect(
        UrlBuilder.streamUri(camera(sub: ''), kind: StreamKind.sub)!.path,
        '/stream0',
      );
    });

    test('an HTTP camera gives an http address', () {
      final Uri uri = UrlBuilder.streamUri(
        camera(port: 8080, main: '/axis-cgi/mjpg/video.cgi', protocol: StreamProtocol.mjpeg),
      )!;
      expect(uri.toString(), 'http://192.168.1.64:8080/axis-cgi/mjpg/video.cgi');
    });

    test('a query string stays a query string', () {
      final Uri uri = UrlBuilder.streamUri(
        camera(main: '/cam/realmonitor?channel=1&subtype=0'),
      )!;
      expect(uri.path, '/cam/realmonitor');
      expect(uri.query, 'channel=1&subtype=0');
    });

    test('a path without a slash gets one', () {
      expect(UrlBuilder.streamUri(camera(main: 'live'))!.path, '/live');
    });

    test('host names and IPv6 hosts are accepted', () {
      expect(UrlBuilder.streamUri(camera(host: 'cam.local'))!.host, 'cam.local');
      final Uri v6 = UrlBuilder.streamUri(camera(host: '[fe80::1]'))!;
      expect(v6.host, 'fe80::1');
    });

    test('no address is built from unusable settings', () {
      expect(UrlBuilder.streamUri(camera(host: '')), isNull);
      expect(UrlBuilder.streamUri(camera(host: '   ')), isNull);
      expect(UrlBuilder.streamUri(camera(port: 0)), isNull);
      expect(UrlBuilder.streamUri(camera(port: 70000)), isNull);
      expect(UrlBuilder.streamUri(camera(host: 'bad host name')), isNull);
    });

    test('credentials never appear in the address', () {
      final Uri uri = UrlBuilder.streamUri(camera())!;
      expect(uri.userInfo, isEmpty);
      expect(uri.toString().contains('@'), isFalse);
    });
  });
}
