import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/onvif_message_builder.dart';
import 'package:xml/xml.dart';

import '../../support/fakes.dart';

XmlElement find(XmlDocument document, String local) {
  return document.rootElement.descendantElements
      .firstWhere((XmlElement e) => e.name.local == local);
}

void main() {
  final OnvifMessageBuilder builder = OnvifMessageBuilder(clock: FakeClock());
  const CameraCredentials login =
      CameraCredentials(username: 'admin', password: 'pw12345');

  test('the password digest matches the WS-Security reference value', () {
    // Example from the WS-Security UsernameToken profile.
    final String digest = OnvifMessageBuilder.passwordDigest(
      nonce: base64.decode('LKqI6G/AikKCQrN0zqZFlg=='),
      created: '2010-09-16T07:50:45Z',
      password: 'userpassword',
    );
    expect(digest, 'tuOSpGlFlIXsozq4HFNeeGeFLEI=');
  });

  group('envelope', () {
    test('a signed request carries a UsernameToken with digest and nonce', () {
      final Uint8List nonce = Uint8List.fromList(base64.decode('LKqI6G/AikKCQrN0zqZFlg=='));
      final String text = builder.envelope(
        '<tds:GetDeviceInformation/>',
        auth: const OnvifAuth(login),
        nonce: nonce,
        created: DateTime.utc(2010, 9, 16, 7, 50, 45),
      );
      final XmlDocument document = XmlDocument.parse(text);
      expect(find(document, 'Username').innerText, 'admin');
      expect(find(document, 'Created').innerText, '2010-09-16T07:50:45Z');
      expect(find(document, 'Nonce').innerText, 'LKqI6G/AikKCQrN0zqZFlg==');
      expect(
        find(document, 'Password').innerText,
        OnvifMessageBuilder.passwordDigest(
          nonce: nonce,
          created: '2010-09-16T07:50:45Z',
          password: 'pw12345',
        ),
      );
      expect(text.contains('pw12345'), isFalse, reason: 'password must not be sent');
    });

    test('the time offset moves the signed timestamp', () {
      final OnvifMessageBuilder offset = OnvifMessageBuilder(
        clock: FakeClock(DateTime.utc(2026, 10, 5, 12)),
      );
      final String text = offset.envelope(
        '<tds:GetProfiles/>',
        auth: const OnvifAuth(login, timeOffset: Duration(hours: 8)),
      );
      expect(find(XmlDocument.parse(text), 'Created').innerText, '2026-10-05T20:00:00Z');
    });

    test('a fresh random nonce is used each time', () {
      final String a = builder.getProfiles(auth: const OnvifAuth(login));
      final String b = builder.getProfiles(auth: const OnvifAuth(login));
      expect(
        find(XmlDocument.parse(a), 'Nonce').innerText,
        isNot(find(XmlDocument.parse(b), 'Nonce').innerText),
      );
    });

    test('without credentials the request is unsigned', () {
      final String text = builder.getProfiles();
      expect(text.contains('Security'), isFalse);
      expect(
        builder.getProfiles(auth: const OnvifAuth(CameraCredentials.none)).contains('Security'),
        isFalse,
      );
    });

    test('special characters in the username are escaped', () {
      final String text = builder.getDeviceInformation(
        auth: const OnvifAuth(CameraCredentials(username: 'a<b&c', password: 'x')),
      );
      expect(find(XmlDocument.parse(text), 'Username').innerText, 'a<b&c');
    });
  });

  group('requests', () {
    test('every request is well-formed XML', () {
      final List<String> requests = <String>[
        builder.getSystemDateAndTime(),
        builder.getDeviceInformation(auth: const OnvifAuth(login)),
        builder.getProfiles(auth: const OnvifAuth(login)),
        builder.getStreamUri('profile_1', auth: const OnvifAuth(login)),
        builder.stopMove('profile_1', auth: const OnvifAuth(login)),
        builder.gotoHome('profile_1', auth: const OnvifAuth(login)),
        builder.gotoPreset('profile_1', '7', auth: const OnvifAuth(login)),
      ];
      for (final String text in requests) {
        expect(() => XmlDocument.parse(text), returnsNormally);
      }
    });

    test('GetStreamUri asks for RTSP and names the profile', () {
      final XmlDocument document =
          XmlDocument.parse(builder.getStreamUri('profile_1'));
      expect(find(document, 'ProfileToken').innerText, 'profile_1');
      expect(find(document, 'Protocol').innerText, 'RTSP');
      expect(find(document, 'Stream').innerText, 'RTP-Unicast');
    });

    test('a profile token is escaped', () {
      final String text = builder.getStreamUri('a<b');
      expect(find(XmlDocument.parse(text), 'ProfileToken').innerText, 'a<b');
    });

    test('continuous move carries the velocities', () {
      final XmlDocument document = XmlDocument.parse(
        builder.ptzRequest(
          PtzCommand.continuous(pan: 1, tilt: -0.5, zoom: 0.25, speed: 0.5),
          'profile_1',
        ),
      );
      final XmlElement panTilt = find(document, 'PanTilt');
      expect(panTilt.getAttribute('x'), '0.500');
      expect(panTilt.getAttribute('y'), '-0.250');
      expect(find(document, 'Zoom').getAttribute('x'), '0.125');
      expect(find(document, 'ContinuousMove').name.local, 'ContinuousMove');
    });

    test('each command kind produces its own request', () {
      String root(PtzCommand c) => XmlDocument.parse(builder.ptzRequest(c, 'p'))
          .rootElement
          .descendantElements
          .firstWhere((XmlElement e) => e.parentElement?.name.local == 'Body')
          .name
          .local;
      expect(root(const PtzCommand.stop()), 'Stop');
      expect(root(const PtzCommand.home()), 'GotoHomePosition');
      expect(root(const PtzCommand.preset('9')), 'GotoPreset');
      expect(root(PtzCommand.continuous(pan: 1)), 'ContinuousMove');
    });

    test('stop halts both pan-tilt and zoom', () {
      final XmlDocument document = XmlDocument.parse(builder.stopMove('p'));
      final List<String> flags = document.rootElement.descendantElements
          .where((XmlElement e) => e.name.local == 'PanTilt' || e.name.local == 'Zoom')
          .map((XmlElement e) => e.innerText)
          .toList();
      expect(flags, <String>['true', 'true']);
    });

    test('a preset request names the preset', () {
      final XmlDocument document =
          XmlDocument.parse(builder.ptzRequest(const PtzCommand.preset('9'), 'p'));
      expect(find(document, 'PresetToken').innerText, '9');
    });
  });

  test('GetCapabilities asks for every category', () {
    final XmlDocument document = XmlDocument.parse(builder.getCapabilities());
    expect(find(document, 'Category').innerText, 'All');
  });
}
