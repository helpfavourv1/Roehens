import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/lan_selector.dart';

void main() {
  group('isPrivateIpv4', () {
    test('accepts the three private ranges', () {
      for (final String address in <String>[
        '10.0.0.5',
        '10.255.255.255',
        '172.16.0.1',
        '172.31.255.254',
        '192.168.0.1',
        '192.168.255.1',
      ]) {
        expect(LanSelector.isPrivateIpv4(address), isTrue, reason: address);
      }
    });

    test('rejects everything else', () {
      for (final String address in <String>[
        '172.15.0.1',
        '172.32.0.1',
        '192.169.0.1',
        '8.8.8.8',
        '169.254.1.1',
        '127.0.0.1',
        '100.64.0.1',
        '1.2.3',
        '10.0.0.256',
        'fe80::1',
        '',
      ]) {
        expect(LanSelector.isPrivateIpv4(address), isFalse, reason: address);
      }
    });
  });

  group('chooseLocalAddress', () {
    test('picks the Wi-Fi address', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('lo', <String>['127.0.0.1']),
          LanInterface('wlan0', <String>['192.168.1.20']),
        ]),
        '192.168.1.20',
      );
    });

    test('mobile data and tunnels never count', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('rmnet_data1', <String>['10.20.30.40']),
          LanInterface('tun0', <String>['10.8.0.2']),
          LanInterface('ccmni1', <String>['10.1.1.1']),
        ]),
        isNull,
      );
    });

    test('Wi-Fi wins over an unknown interface regardless of order', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('dummy0', <String>['10.9.9.9']),
          LanInterface('wlan0', <String>['192.168.1.20']),
        ]),
        '192.168.1.20',
      );
    });

    test('an unknown interface is used when there is nothing better', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('dummy0', <String>['10.9.9.9']),
        ]),
        '10.9.9.9',
      );
    });

    test('Apple interface names are recognized', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('pdp_ip0', <String>['10.50.0.2']),
          LanInterface('en0', <String>['192.168.0.15']),
        ]),
        '192.168.0.15',
      );
    });

    test('public and link-local addresses are skipped', () {
      expect(
        LanSelector.chooseLocalAddress(const <LanInterface>[
          LanInterface('wlan0', <String>['169.254.3.3', '203.0.113.9']),
        ]),
        isNull,
      );
    });

    test('no interfaces gives nothing', () {
      expect(LanSelector.chooseLocalAddress(const <LanInterface>[]), isNull);
    });
  });

  group('guessGateway', () {
    test('is the first host of the /24', () {
      expect(LanSelector.guessGateway('192.168.1.20'), '192.168.1.1');
      expect(LanSelector.guessGateway('10.4.7.200'), '10.4.7.1');
    });

    test('is null for an address that is not private', () {
      expect(LanSelector.guessGateway('8.8.8.8'), isNull);
    });
  });
}
