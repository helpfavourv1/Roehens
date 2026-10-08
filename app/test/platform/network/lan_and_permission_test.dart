import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/services/lan_selector.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/local_network_permission_service.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';

LanInfo lanWith(List<LanInterface> interfaces, {String? gateway}) {
  const MethodChannel channel = MethodChannel('test/lan');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    return call.method == 'gateway' ? gateway : null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  return LanInfo(
    channel: MulticastLockChannel(channel: channel, isAndroid: gateway != null),
    interfaces: () async => interfaces,
  );
}

const List<LanInterface> wifi = <LanInterface>[
  LanInterface('wlan0', <String>['192.168.1.20']),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanInfo', () {
    test('uses the real gateway when the phone reports one', () async {
      final LanSnapshot snapshot =
          (await lanWith(wifi, gateway: '192.168.1.254').read())!;
      expect(snapshot.address, '192.168.1.20');
      expect(snapshot.gateway, '192.168.1.254');
      expect(snapshot.gatewayIsGuess, isFalse);
    });

    test('guesses the gateway when the phone cannot say', () async {
      final LanSnapshot snapshot = (await lanWith(wifi).read())!;
      expect(snapshot.gateway, '192.168.1.1');
      expect(snapshot.gatewayIsGuess, isTrue);
    });

    test('is null when the phone is not on a local network', () async {
      expect(
        await lanWith(const <LanInterface>[
          LanInterface('rmnet_data0', <String>['10.1.2.3']),
        ]).read(),
        isNull,
      );
    });

    test('is null when the interfaces cannot be read', () async {
      final LanInfo info = LanInfo(
        channel: MulticastLockChannel(isAndroid: false),
        interfaces: () async => throw StateError('no access'),
      );
      expect(await info.read(), isNull);
    });
  });

  group('outcomes', () {
    test('a connection or a refusal means the network is reachable', () {
      expect(
        LocalNetworkPermissionService.outcomeFor(connected: true, timedOut: false),
        LocalNetworkOutcome.reachable,
      );
      for (final int code in <int>[61, 111]) {
        expect(
          LocalNetworkPermissionService.outcomeFor(
            connected: false,
            timedOut: false,
            errorCode: code,
          ),
          LocalNetworkOutcome.reachable,
        );
      }
    });

    test('no route to host means access is blocked', () {
      for (final int code in <int>[65, 113]) {
        expect(
          LocalNetworkPermissionService.outcomeFor(
            connected: false,
            timedOut: false,
            errorCode: code,
          ),
          LocalNetworkOutcome.blocked,
        );
      }
    });

    test('a timeout or an unknown error proves nothing', () {
      expect(
        LocalNetworkPermissionService.outcomeFor(connected: false, timedOut: true),
        LocalNetworkOutcome.inconclusive,
      );
      expect(
        LocalNetworkPermissionService.outcomeFor(
          connected: false,
          timedOut: false,
          errorCode: 999,
        ),
        LocalNetworkOutcome.inconclusive,
      );
    });

    test('outcomes map to permission states', () {
      expect(
        LocalNetworkPermissionService.statusFor(LocalNetworkOutcome.reachable),
        PermissionStatus.granted,
      );
      expect(
        LocalNetworkPermissionService.statusFor(LocalNetworkOutcome.blocked),
        PermissionStatus.permanentlyDenied,
      );
      expect(
        LocalNetworkPermissionService.statusFor(LocalNetworkOutcome.inconclusive),
        PermissionStatus.unknown,
      );
    });
  });

  group('service', () {
    test('Android needs no permission', () async {
      final LocalNetworkPermissionService service = LocalNetworkPermissionService(
        lan: lanWith(wifi),
        channel: MulticastLockChannel(isAndroid: false),
        isIos: false,
        probe: (String host) async => fail('must not probe'),
      );
      expect(await service.localNetworkStatus(), PermissionStatus.notRequired);
      expect(await service.requestLocalNetwork(), PermissionStatus.notRequired);
    });

    test('iOS probes the gateway and remembers the answer', () async {
      String? probed;
      final LocalNetworkPermissionService service = LocalNetworkPermissionService(
        lan: lanWith(wifi),
        isIos: true,
        probe: (String host) async {
          probed = host;
          return LocalNetworkOutcome.blocked;
        },
      );
      expect(await service.localNetworkStatus(), PermissionStatus.unknown);
      expect(await service.requestLocalNetwork(), PermissionStatus.permanentlyDenied);
      expect(probed, '192.168.1.1');
      expect(await service.localNetworkStatus(), PermissionStatus.permanentlyDenied);
    });

    test('iOS reports granted when the network answers', () async {
      final LocalNetworkPermissionService service = LocalNetworkPermissionService(
        lan: lanWith(wifi),
        isIos: true,
        probe: (String host) async => LocalNetworkOutcome.reachable,
      );
      expect(await service.requestLocalNetwork(), PermissionStatus.granted);
    });

    test('iOS without a local network cannot tell', () async {
      final LocalNetworkPermissionService service = LocalNetworkPermissionService(
        lan: lanWith(const <LanInterface>[]),
        isIos: true,
        probe: (String host) async => fail('must not probe'),
      );
      expect(await service.requestLocalNetwork(), PermissionStatus.unknown);
    });
  });
}
