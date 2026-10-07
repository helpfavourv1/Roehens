import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/services/onvif_response_parser.dart';

String fixture(String name) => File('test/fixtures/onvif/$name').readAsStringSync();

String fault(String code, String reason) {
  return '<?xml version="1.0"?>'
      '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body>'
      '<s:Fault><s:Code><s:Value>s:Sender</s:Value>'
      '<s:Subcode><s:Value>$code</s:Value></s:Subcode></s:Code>'
      '<s:Reason><s:Text xml:lang="en">$reason</s:Text></s:Reason>'
      '</s:Fault></s:Body></s:Envelope>';
}

void main() {
  const OnvifResponseParser parser = OnvifResponseParser();

  test('device information', () {
    final OnvifDeviceInfo info =
        parser.parseDeviceInformation(fixture('device_information.xml')).valueOrNull!;
    expect(info.manufacturer, 'Example Cameras Ltd');
    expect(info.model, 'IPC-5MP-H265');
    expect(info.firmwareVersion, 'V5.3.1 build 250101');
    expect(info.serialNumber, 'EX2025A1B2C3');
    expect(info.hardwareId, '1.0');
  });

  group('profiles', () {
    test('both profiles are read with their stream details', () {
      final List<OnvifProfile> profiles =
          parser.parseProfiles(fixture('get_profiles.xml')).valueOrNull!;
      expect(profiles.length, 2);

      final OnvifProfile main = profiles[0];
      expect(main.token, 'profile_1');
      expect(main.name, 'MainStream');
      expect(main.videoEncoding, 'H265');
      expect(main.width, 2592);
      expect(main.height, 1944);
      expect(main.frameRateLimit, 25);
      expect(main.bitrateLimitKbps, 4096);
      expect(main.hasPtz, isTrue);

      final OnvifProfile sub = profiles[1];
      expect(sub.token, 'profile_2');
      expect(sub.videoEncoding, 'H264');
      expect(sub.width, 640);
      expect(sub.height, 360);
      expect(sub.hasPtz, isFalse);
      expect(main.pixels, greaterThan(sub.pixels));
    });

    test('a profile without a token is skipped', () {
      final String text = fixture('get_profiles.xml')
          .replaceFirst('token="profile_1"', '');
      final List<OnvifProfile> profiles = parser.parseProfiles(text).valueOrNull!;
      expect(profiles.map((OnvifProfile p) => p.token), <String>['profile_2']);
    });

    test('a profile with no video configuration still lists', () {
      const String text = '<s:Envelope xmlns:s="x"><s:Body>'
          '<trt:GetProfilesResponse xmlns:trt="y">'
          '<trt:Profiles token="only"><Name xmlns="z">Bare</Name></trt:Profiles>'
          '</trt:GetProfilesResponse></s:Body></s:Envelope>';
      final OnvifProfile profile = parser.parseProfiles(text).valueOrNull!.single;
      expect(profile.token, 'only');
      expect(profile.width, isNull);
      expect(profile.videoEncoding, isNull);
      expect(profile.pixels, 0);
    });
  });

  test('stream address', () {
    final Uri uri = parser.parseStreamUri(fixture('stream_uri.xml')).valueOrNull!;
    expect(uri.scheme, 'rtsp');
    expect(uri.host, '192.168.1.64');
    expect(uri.port, 554);
    expect(uri.path, '/Streaming/Channels/101');
  });

  group('clock offset', () {
    String time(int hour) => '<s:Envelope xmlns:s="x"><s:Body>'
        '<tds:GetSystemDateAndTimeResponse xmlns:tds="y" xmlns:tt="z">'
        '<tds:SystemDateAndTime><tt:UTCDateTime>'
        '<tt:Time><tt:Hour>$hour</tt:Hour><tt:Minute>0</tt:Minute>'
        '<tt:Second>0</tt:Second></tt:Time>'
        '<tt:Date><tt:Year>2026</tt:Year><tt:Month>10</tt:Month>'
        '<tt:Day>5</tt:Day></tt:Date>'
        '</tt:UTCDateTime></tds:SystemDateAndTime>'
        '</tds:GetSystemDateAndTimeResponse></s:Body></s:Envelope>';

    test('a camera ahead of us has a positive offset', () {
      final Duration offset = parser
          .parseTimeOffset(time(20), nowUtc: DateTime.utc(2026, 10, 5, 12))
          .valueOrNull!;
      expect(offset, const Duration(hours: 8));
    });

    test('a camera behind us has a negative offset', () {
      final Duration offset = parser
          .parseTimeOffset(time(10), nowUtc: DateTime.utc(2026, 10, 5, 12))
          .valueOrNull!;
      expect(offset, const Duration(hours: -2));
    });

    test('a response without a time is an error', () {
      expect(
        parser
            .parseTimeOffset(fixture('stream_uri.xml'), nowUtc: DateTime.utc(2026))
            .isErr,
        isTrue,
      );
    });
  });

  group('faults and bad responses', () {
    test('not authorized becomes an authentication failure', () {
      final Result<List<OnvifProfile>> result = parser.parseProfiles(
        fault('ter:NotAuthorized', 'Sender not Authorized'),
      );
      expect(result.errorOrNull!.errorClass, ErrorClass.authFailed);
    });

    test('other faults are reported as the camera refusing the request', () {
      final AppError error = parser
          .parseAcknowledgement(fault('ter:ActionNotSupported', 'Optional Action Not Implemented'))
          .errorOrNull!;
      expect(error.errorClass, ErrorClass.unsupportedMedia);
      expect(error.detail, contains('Optional Action Not Implemented'));
    });

    test('a fault is found whatever the request was', () {
      final String text = fault('ter:NotAuthorized', 'x');
      expect(parser.parseDeviceInformation(text).isErr, isTrue);
      expect(parser.parseStreamUri(text).isErr, isTrue);
      expect(parser.parseAcknowledgement(text).isErr, isTrue);
    });

    test('malformed XML never throws', () {
      for (final String text in <String>['', 'nope', '<a><b></a>']) {
        expect(parser.parseProfiles(text).isErr, isTrue);
        expect(parser.parseDeviceInformation(text).isErr, isTrue);
        expect(parser.parseStreamUri(text).isErr, isTrue);
        expect(parser.parseAcknowledgement(text).isErr, isTrue);
      }
    });

    test('a response to a different request is unexpected', () {
      expect(parser.parseProfiles(fixture('stream_uri.xml')).isErr, isTrue);
      expect(parser.parseStreamUri(fixture('get_profiles.xml')).isErr, isTrue);
    });

    test('an empty successful reply is a good acknowledgement', () {
      const String ok = '<s:Envelope xmlns:s="x"><s:Body>'
          '<tptz:ContinuousMoveResponse xmlns:tptz="y"/></s:Body></s:Envelope>';
      expect(parser.parseAcknowledgement(ok).isOk, isTrue);
    });
  });
}
