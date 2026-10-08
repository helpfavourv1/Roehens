import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/network/subnet_scanner.dart';

void main() {
  group('hostsOf', () {
    test('lists the other 253 addresses of the /24', () {
      final List<String> hosts = SubnetScanner.hostsOf('192.168.1.20');
      expect(hosts.length, 253);
      expect(hosts.first, '192.168.1.1');
      expect(hosts.last, '192.168.1.254');
      expect(hosts.contains('192.168.1.20'), isFalse);
      expect(hosts.contains('192.168.1.0'), isFalse);
      expect(hosts.contains('192.168.1.255'), isFalse);
    });

    test('an address that is not dotted IPv4 gives nothing', () {
      expect(SubnetScanner.hostsOf(''), isEmpty);
      expect(SubnetScanner.hostsOf('fe80::1'), isEmpty);
      expect(SubnetScanner.hostsOf('10.0.0'), isEmpty);
      expect(SubnetScanner.hostsOf('10.0.0.999'), isEmpty);
      expect(SubnetScanner.hostsOf('a.b.c.d'), isEmpty);
    });
  });

  group('scan', () {
    test('reports exactly the open host and port pairs', () async {
      final Set<String> open = <String>{
        '192.168.1.64:554',
        '192.168.1.64:80',
        '192.168.1.99:8080',
      };
      final SubnetScanner scanner = SubnetScanner(
        connector: (String host, int port, Duration timeout) async =>
            open.contains('$host:$port'),
      );
      final List<OpenPort> found = await scanner.scan('192.168.1.20').toList();
      expect(
        found.map((OpenPort p) => p.toString()).toSet(),
        open,
      );
    });

    test('tries every host on every port and never the phone itself', () async {
      final List<String> tried = <String>[];
      final SubnetScanner scanner = SubnetScanner(
        connector: (String host, int port, Duration timeout) async {
          tried.add('$host:$port');
          return false;
        },
      );
      await scanner.scan('10.0.5.7').toList();
      expect(tried.length, 253 * 5);
      expect(tried.toSet().length, 253 * 5);
      expect(tried.any((String t) => t.startsWith('10.0.5.7:')), isFalse);
    });

    test('the commonest ports are tried first', () async {
      final List<int> order = <int>[];
      final SubnetScanner scanner = SubnetScanner(
        ports: <int>[554, 80],
        concurrency: 1,
        connector: (String host, int port, Duration timeout) async {
          order.add(port);
          return false;
        },
      );
      await scanner.scan('192.168.0.2').toList();
      expect(order.take(253).every((int p) => p == 554), isTrue);
      expect(order.skip(253).every((int p) => p == 80), isTrue);
    });

    test('never runs more connections at once than the limit', () async {
      int running = 0;
      int highest = 0;
      final SubnetScanner scanner = SubnetScanner(
        concurrency: 10,
        connector: (String host, int port, Duration timeout) async {
          running++;
          if (running > highest) {
            highest = running;
          }
          await Future<void>.delayed(const Duration(milliseconds: 1));
          running--;
          return false;
        },
      );
      await scanner.scan('192.168.1.20').toList();
      expect(highest, lessThanOrEqualTo(10));
      expect(highest, greaterThan(1));
    });

    test('progress only goes up and ends at one', () async {
      final List<double> seen = <double>[];
      final SubnetScanner scanner = SubnetScanner(
        connector: (String host, int port, Duration timeout) async => false,
      );
      await scanner.scan('192.168.1.20', onProgress: seen.add).toList();
      expect(seen, isNotEmpty);
      expect(seen.last, 1.0);
      for (int i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1] - 1e-9));
      }
    });

    test('cancelling stops further connection attempts', () async {
      int attempts = 0;
      final SubnetScanner scanner = SubnetScanner(
        concurrency: 4,
        connector: (String host, int port, Duration timeout) async {
          attempts++;
          await Future<void>.delayed(const Duration(milliseconds: 2));
          return true;
        },
      );
      final Completer<void> first = Completer<void>();
      final StreamSubscription<OpenPort> subscription =
          scanner.scan('192.168.1.20').listen((OpenPort p) {
        if (!first.isCompleted) {
          first.complete();
        }
      });
      await first.future;
      await subscription.cancel();
      final int atCancel = attempts;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(attempts - atCancel, lessThanOrEqualTo(4));
      expect(attempts, lessThan(253 * 5));
    });

    test('a connector that throws counts as closed', () async {
      final SubnetScanner scanner = SubnetScanner(
        ports: <int>[80],
        connector: (String host, int port, Duration timeout) async {
          throw StateError('boom');
        },
      );
      expect(await scanner.scan('192.168.1.20').toList(), isEmpty);
    });

    test('an invalid local address finishes at once with nothing', () async {
      double? last;
      final SubnetScanner scanner = SubnetScanner(
        connector: (String host, int port, Duration timeout) async => true,
      );
      final List<OpenPort> found =
          await scanner.scan('not an ip', onProgress: (double f) => last = f).toList();
      expect(found, isEmpty);
      expect(last, 1.0);
    });
  });
}
