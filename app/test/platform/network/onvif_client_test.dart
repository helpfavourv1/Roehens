import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/onvif_response_parser.dart';
import 'package:roehens/platform/network/onvif_client.dart';

import '../../support/fakes.dart';
import '../../support/local_http.dart';

String fixture(String name) => File('test/fixtures/onvif/$name').readAsStringSync();

const CameraCredentials login =
    CameraCredentials(username: 'admin', password: 'pw12345');

String timeResponse(int hour) => '<s:Envelope xmlns:s="x"><s:Body>'
    '<tds:GetSystemDateAndTimeResponse xmlns:tds="y" xmlns:tt="z">'
    '<tds:SystemDateAndTime><tt:UTCDateTime>'
    '<tt:Time><tt:Hour>$hour</tt:Hour><tt:Minute>0</tt:Minute><tt:Second>0</tt:Second></tt:Time>'
    '<tt:Date><tt:Year>2026</tt:Year><tt:Month>10</tt:Month><tt:Day>5</tt:Day></tt:Date>'
    '</tt:UTCDateTime></tds:SystemDateAndTime>'
    '</tds:GetSystemDateAndTimeResponse></s:Body></s:Envelope>';

const String ack = '<s:Envelope xmlns:s="x"><s:Body>'
    '<tptz:ContinuousMoveResponse xmlns:tptz="y"/></s:Body></s:Envelope>';

String fault(String code, String reason) => '<s:Envelope xmlns:s="x"><s:Body>'
    '<s:Fault><s:Code><s:Value>s:Sender</s:Value>'
    '<s:Subcode><s:Value>$code</s:Value></s:Subcode></s:Code>'
    '<s:Reason><s:Text>$reason</s:Text></s:Reason></s:Fault></s:Body></s:Envelope>';

/// A pretend camera. [overrides] replaces the answer for one action name.
Future<(Uri, List<String>)> serveOnvif({
  Map<String, (int, String)> overrides = const <String, (int, String)>{},
}) async {
  final List<String> requests = <String>[];
  late Uri base;
  base = await serveLocal((HttpRequest r) async {
    final String body = await utf8.decodeStream(r);
    requests.add(body);
    const List<String> actions = <String>[
      'GetSystemDateAndTime',
      'GetDeviceInformation',
      'GetCapabilities',
      'GetProfiles',
      'GetStreamUri',
      'ContinuousMove',
    ];
    final String action = actions.firstWhere(body.contains, orElse: () => 'Unknown');
    (int, String) answer;
    if (overrides.containsKey(action)) {
      answer = overrides[action]!;
    } else {
      switch (action) {
        case 'GetSystemDateAndTime':
          answer = (200, timeResponse(14));
        case 'GetDeviceInformation':
          answer = (200, fixture('device_information.xml'));
        case 'GetCapabilities':
          answer = (
            200,
            fixture('capabilities.xml').replaceAll('10.99.0.5:8080', '10.99.0.5:${base.port}'),
          );
        case 'GetProfiles':
          answer = (200, fixture('get_profiles.xml'));
        case 'GetStreamUri':
          answer = (200, fixture('stream_uri.xml'));
        case 'ContinuousMove':
          answer = (200, ack);
        default:
          answer = (400, fault('ter:InvalidArgVal', 'unknown request'));
      }
    }
    r.response.statusCode = answer.$1;
    r.response.headers.contentType = ContentType('application', 'soap+xml');
    r.response.write(answer.$2);
    await r.response.close();
  });
  return (base.replace(path: '/onvif/device_service'), requests);
}

String actionOf(String body) {
  return <String>[
    'GetSystemDateAndTime',
    'GetDeviceInformation',
    'GetCapabilities',
    'GetProfiles',
  ].firstWhere(body.contains, orElse: () => 'other');
}

void main() {
  late FakeClock clock;
  late OnvifClient client;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 10, 5, 12));
    client = OnvifClient(clock: clock, timeout: const Duration(seconds: 3));
  });

  group('connect', () {
    test('learns the clock, device, services and profiles', () async {
      final (Uri service, List<String> requests) = await serveOnvif();
      final OnvifDevice device = (await client.connect(service, login)).valueOrNull!;

      expect(device.info.model, 'IPC-5MP-H265');
      expect(device.profiles.map((OnvifProfile p) => p.token), <String>['profile_1', 'profile_2']);
      expect(device.clockOffset, const Duration(hours: 2));
      expect(device.ptzService, isNotNull);
      expect(device.ptzService!.path, '/onvif/ptz_service');
      // The camera advertised an internal address; the reachable host replaces it.
      expect(device.mediaService.host, '127.0.0.1');
      expect(device.mediaService.port, service.port);
      expect(device.mediaService.path, '/onvif/media_service');

      expect(requests.map(actionOf), <String>[
        'GetSystemDateAndTime',
        'GetDeviceInformation',
        'GetCapabilities',
        'GetProfiles',
      ]);
      expect(selectMainAndSub(device.profiles).main!.token, 'profile_1');
    });

    test('the clock request is unsigned and the others are signed', () async {
      final (Uri service, List<String> requests) = await serveOnvif();
      await client.connect(service, login);
      expect(requests[0].contains('UsernameToken'), isFalse);
      for (final String signed in requests.skip(1)) {
        expect(signed, contains('<wsse:Username>admin</wsse:Username>'));
        expect(signed.contains('pw12345'), isFalse);
      }
    });

    test('signatures use the camera clock, not ours', () async {
      final (Uri service, List<String> requests) = await serveOnvif();
      await client.connect(service, login);
      // Our clock says 12:00, the camera says 14:00.
      expect(requests[1], contains('<wsu:Created>2026-10-05T14:00:00Z</wsu:Created>'));
    });

    test('a camera that cannot report its services still connects', () async {
      final (Uri service, List<String> requests) = await serveOnvif(
        overrides: <String, (int, String)>{
          'GetCapabilities': (400, fault('ter:ActionNotSupported', 'no')),
        },
      );
      final OnvifDevice device = (await client.connect(service, login)).valueOrNull!;
      expect(device.mediaService, service);
      expect(device.ptzService, isNull);
      expect(requests.map(actionOf).last, 'GetProfiles');
    });

    test('a camera whose clock cannot be read still connects', () async {
      final (Uri service, List<String> requests) = await serveOnvif(
        overrides: <String, (int, String)>{
          'GetSystemDateAndTime': (500, fault('ter:Action', 'no clock')),
        },
      );
      final OnvifDevice device = (await client.connect(service, login)).valueOrNull!;
      expect(device.clockOffset, Duration.zero);
      expect(requests.length, 4);
    });

    test('wrong credentials end as an authentication failure', () async {
      final (Uri service, _) = await serveOnvif(
        overrides: <String, (int, String)>{
          'GetDeviceInformation': (400, fault('ter:NotAuthorized', 'Sender not Authorized')),
        },
      );
      final Result<OnvifDevice> result = await client.connect(service, login);
      expect(result.errorOrNull!.errorClass, ErrorClass.authFailed);
    });

    test('a plain HTTP login rejection is an authentication failure', () async {
      final Uri service = (await serveLocal((HttpRequest r) async {
        await utf8.decodeStream(r);
        r.response.statusCode = HttpStatus.unauthorized;
        r.response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Basic realm="cam"');
        await r.response.close();
      }))
          .replace(path: '/onvif/device_service');
      final Result<OnvifDevice> result = await client.connect(service, login);
      expect(result.errorOrNull!.errorClass, ErrorClass.authFailed);
    });

    test('a camera with no profiles is reported', () async {
      final (Uri service, _) = await serveOnvif(
        overrides: <String, (int, String)>{
          'GetProfiles': (
            200,
            '<s:Envelope xmlns:s="x"><s:Body>'
                '<trt:GetProfilesResponse xmlns:trt="y"/></s:Body></s:Envelope>',
          ),
        },
      );
      final Result<OnvifDevice> result = await client.connect(service, login);
      expect(result.errorOrNull!.errorClass, ErrorClass.unsupportedMedia);
    });

    test('an unreachable camera is a network error', () async {
      final HttpServer closed =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final int port = closed.port;
      await closed.close(force: true);
      final Result<OnvifDevice> result = await client.connect(
        Uri.parse('http://127.0.0.1:$port/onvif/device_service'),
        login,
      );
      expect(result.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
    });
  });

  group('single calls', () {
    test('stream address for a profile', () async {
      final (Uri service, List<String> requests) = await serveOnvif();
      final Uri uri =
          (await client.streamUri(service, 'profile_2', login)).valueOrNull!;
      expect(uri.scheme, 'rtsp');
      expect(uri.path, '/Streaming/Channels/101');
      expect(requests.single, contains('<trt:ProfileToken>profile_2</trt:ProfileToken>'));
    });

    test('a PTZ command is acknowledged', () async {
      final (Uri service, List<String> requests) = await serveOnvif();
      final Result<void> result = await client.ptz(
        service,
        'profile_1',
        PtzCommand.continuous(pan: 1, speed: 0.5),
        login,
      );
      expect(result.isOk, isTrue);
      expect(requests.single, contains('<tt:PanTilt x="0.500" y="0.000"/>'));
    });

    test('a PTZ command the camera refuses is an error', () async {
      final (Uri service, _) = await serveOnvif(
        overrides: <String, (int, String)>{
          'ContinuousMove': (400, fault('ter:ActionNotSupported', 'No PTZ')),
        },
      );
      final Result<void> result = await client.ptz(
        service,
        'profile_1',
        PtzCommand.continuous(pan: 1),
        login,
      );
      expect(result.errorOrNull!.errorClass, ErrorClass.unsupportedMedia);
    });

    test('an empty answer is an error', () async {
      final Uri service = (await serveLocal((HttpRequest r) async {
        await utf8.decodeStream(r);
        await r.response.close();
      }))
          .replace(path: '/onvif/device_service');
      expect((await client.deviceInfo(service, login)).isErr, isTrue);
    });
  });
}
