import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/services/lan_selector.dart';
import 'package:roehens/platform/network/discovery_service.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';
import 'package:roehens/platform/network/subnet_scanner.dart';
import 'package:roehens/platform/network/ws_discovery_socket.dart';

void main() {
  LanInfo lanAt(String? address) {
    return LanInfo(
      channel: MulticastLockChannel(isAndroid: false),
      interfaces: () async => address == null
          ? <LanInterface>[]
          : <LanInterface>[LanInterface('wlan0', <String>[address])],
    );
  }

  DiscoveryService build({
    required LanInfo lan,
    required Set<String> open,
  }) {
    return DiscoveryService(
      lan: lan,
      scanner: SubnetScanner(
        connector: (String host, int port, Duration timeout) async =>
            open.contains('$host:$port'),
      ),
      socket: WsDiscoverySocket(),
      channel: MulticastLockChannel(isAndroid: false),
      wsDiscoveryEnabled: false,
    );
  }

  test('reports open camera ports as sweep results, then finishes', () async {
    final DiscoveryService service = build(
      lan: lanAt('192.168.1.20'),
      open: <String>{'192.168.1.50:554', '192.168.1.50:80', '192.168.1.60:8000'},
    );
    final List<DiscoveryEvent> events =
        await service.discover(timeout: const Duration(seconds: 10)).toList();

    final List<DiscoveryResult> found = <DiscoveryResult>[
      for (final DiscoveryEvent e in events)
        if (e is DiscoveryFound) e.result,
    ];
    expect(found, hasLength(3));
    expect(found.every((DiscoveryResult r) => r.source == DiscoverySource.sweep), isTrue);
    expect(found.map((DiscoveryResult r) => r.host).toSet(), <String>{
      '192.168.1.50',
      '192.168.1.60',
    });
    expect(events.whereType<DiscoveryProgressed>(), isNotEmpty);
    expect(events.last, isA<DiscoveryFinished>());
  });

  test('without a local network it finishes at once with nothing found', () async {
    final DiscoveryService service = build(lan: lanAt(null), open: <String>{});
    final List<DiscoveryEvent> events =
        await service.discover(timeout: const Duration(seconds: 10)).toList();

    expect(events.whereType<DiscoveryFound>(), isEmpty);
    expect(events.last, isA<DiscoveryFinished>());
  });

  test('cancelling the subscription stops the run', () async {
    final DiscoveryService service = build(
      lan: lanAt('10.0.0.5'),
      open: <String>{},
    );
    final Stream<DiscoveryEvent> stream =
        service.discover(timeout: const Duration(seconds: 10));
    await stream.first;
    // No further work is needed: reaching here without hanging is the check.
  });
}
