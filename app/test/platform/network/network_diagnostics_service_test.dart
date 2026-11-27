import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/diagnostics_report.dart';
import 'package:roehens/core/services/connection_tester.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';
import 'package:roehens/platform/network/network_diagnostics_service.dart';
import 'package:roehens/platform/network/public_ip_lookup.dart';

import '../../support/fake_probes.dart';
import '../../support/live_fakes.dart';
import '../../support/local_http.dart';

void main() {
  late FakeProbes probes;
  List<LanInterface> interfaces = <LanInterface>[
    const LanInterface('wlan0', <String>['192.168.1.23']),
  ];
  late Future<List<InternetAddress>> Function(String) resolver;
  late Uri lookupUri;

  NetworkDiagnosticsService service() {
    return NetworkDiagnosticsService(
      lan: LanInfo(
        channel: MulticastLockChannel(isAndroid: false),
        interfaces: () async => interfaces,
      ),
      probes: probes,
      tester: ConnectionTester(probes: probes),
      lookup: PublicIpLookup(endpoint: lookupUri),
      resolver: resolver,
      resolveTimeout: const Duration(milliseconds: 300),
    );
  }

  setUp(() async {
    probes = FakeProbes();
    interfaces = <LanInterface>[
      const LanInterface('wlan0', <String>['192.168.1.23']),
    ];
    resolver = (String host) async => <InternetAddress>[
      InternetAddress('203.0.113.9'),
    ];
    lookupUri = await serveLocal((HttpRequest r) async {
      r.response.write('203.0.113.7');
      await r.response.close();
    });
  });

  test('local network reports this phone and its gateway guess', () async {
    final CheckOutcome out = await service().localNetwork();
    expect(out.status, CheckStatus.passed);
    expect(out.detail, startsWith('192.168.1.23'));
    expect(out.detail, contains('192.168.1.1'));
  });

  test('no local network is a failure with a reason', () async {
    interfaces = <LanInterface>[];
    final CheckOutcome out = await service().localNetwork();
    expect(out.status, CheckStatus.failed);
    expect(out.error!.errorClass, ErrorClass.networkUnreachable);
  });

  test('host resolution lists the addresses', () async {
    final CheckOutcome out = await service().hostResolution('home.example');
    expect(out.status, CheckStatus.passed);
    expect(out.detail, '203.0.113.9');
  });

  test('a name that does not resolve fails', () async {
    resolver = (String host) async => throw const SocketException('no host');
    expect(
      (await service().hostResolution('nope.invalid')).status,
      CheckStatus.failed,
    );
    resolver = (String host) async => <InternetAddress>[];
    expect(
      (await service().hostResolution('empty.invalid')).status,
      CheckStatus.failed,
    );
  });

  test('a slow resolver times out', () async {
    resolver = (String host) => Completer<List<InternetAddress>>().future;
    expect(
      (await service().hostResolution('slow.invalid')).status,
      CheckStatus.failed,
    );
  });

  test(
    'host and port: connects, with the time; or fails with the reason',
    () async {
      CheckOutcome out = await service().hostPort('home.example', 18554);
      expect(out.status, CheckStatus.passed);
      expect(out.detail, endsWith(' ms'));
      expect(probes.calls, contains('tcp home.example:18554'));

      probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));
      out = await service().hostPort('home.example', 18554);
      expect(out.status, CheckStatus.failed);
      expect(out.error!.errorClass, ErrorClass.networkUnreachable);
    },
  );

  test('LAN reachability uses the connection tester', () async {
    final Camera camera = cameraWithSub(id: 'a');
    CheckOutcome out = await service().lanReachability(
      camera,
      CameraCredentials.none,
    );
    expect(out.status, CheckStatus.passed);

    probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));
    out = await service().lanReachability(camera, CameraCredentials.none);
    expect(out.status, CheckStatus.failed);
    expect(out.error, isNotNull);
  });

  test('the public address check returns the address, or fails', () async {
    CheckOutcome out = await service().publicAddress();
    expect(out.status, CheckStatus.passed);
    expect(out.detail, '203.0.113.7');

    lookupUri = await serveLocal((HttpRequest r) async {
      r.response.statusCode = 500;
      await r.response.close();
    });
    out = await service().publicAddress();
    expect(out.status, CheckStatus.failed);
  });

  test('nothing runs until a check is called', () async {
    service();
    expect(probes.calls, isEmpty);
  });
}
