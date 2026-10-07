import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/services/ws_discovery_codec.dart';
import 'package:xml/xml.dart';

String fixture(String name) => File('test/fixtures/onvif/$name').readAsStringSync();

void main() {
  const WsDiscoveryCodec codec = WsDiscoveryCodec();

  group('probe message', () {
    test('is well-formed and asks for network video transmitters', () {
      final String probe = codec.buildProbe(messageId: 'abc-123');
      final XmlDocument document = XmlDocument.parse(probe);
      expect(document.rootElement.name.local, 'Envelope');
      expect(probe, contains('uuid:abc-123'));
      expect(probe, contains('ws/2005/04/discovery/Probe'));
      expect(probe, contains('dn:NetworkVideoTransmitter'));
      expect(probe, contains('urn:schemas-xmlsoap-org:ws:2005:04:discovery'));
    });
  });

  group('probe match', () {
    test('a real-looking reply becomes a discovery result', () {
      final DiscoveryResult result =
          codec.parseProbeMatch(fixture('probe_match.xml'))!;
      expect(result.host, '192.168.1.64');
      expect(result.port, 8080);
      expect(result.source, DiscoverySource.onvif);
      expect(result.name, 'Front Gate');
      expect(result.model, 'IPC-5MP');
      expect(result.xaddrs, <String>[
        'http://192.168.1.64:8080/onvif/device_service',
      ]);
      expect(result.scopes.length, 5);
      expect(result.scopes, contains('onvif://www.onvif.org/type/ptz'));
    });

    test('the port defaults to 80 when the address has none', () {
      final String text = fixture('probe_match.xml').replaceAll(
        'http://192.168.1.64:8080/onvif/device_service',
        'http://192.168.1.64/onvif/device_service',
      );
      expect(codec.parseProbeMatch(text)!.port, 80);
    });

    test('an IPv4 address is preferred over other addresses', () {
      final String text = fixture('probe_match.xml').replaceAll(
        'http://192.168.1.64:8080/onvif/device_service',
        'http://cam.local:80/onvif/device_service '
            'http://10.0.0.7:80/onvif/device_service',
      );
      final DiscoveryResult result = codec.parseProbeMatch(text)!;
      expect(result.host, '10.0.0.7');
      expect(result.xaddrs.length, 2);
    });

    test('a reply without a usable address is ignored', () {
      final String text = fixture('probe_match.xml').replaceAll(
        'http://192.168.1.64:8080/onvif/device_service',
        '',
      );
      expect(codec.parseProbeMatch(text), isNull);
    });

    test('anything else is ignored without throwing', () {
      expect(codec.parseProbeMatch(''), isNull);
      expect(codec.parseProbeMatch('not xml at all'), isNull);
      expect(codec.parseProbeMatch('<a><b/></a>'), isNull);
      expect(codec.parseProbeMatch(fixture('stream_uri.xml')), isNull);
    });

    test('a device name without a scope is simply absent', () {
      final String text = fixture('probe_match.xml')
          .replaceAll('onvif://www.onvif.org/name/Front_Gate', '')
          .replaceAll('onvif://www.onvif.org/hardware/IPC-5MP', '');
      final DiscoveryResult result = codec.parseProbeMatch(text)!;
      expect(result.name, isNull);
      expect(result.model, isNull);
    });
  });
}
