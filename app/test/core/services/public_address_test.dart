import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/public_address.dart';

void main() {
  group('parse', () {
    test('takes one IPv4 or IPv6 address, trimmed', () {
      expect(PublicAddress.parse(' 203.0.113.7\n'), '203.0.113.7');
      expect(PublicAddress.parse('2001:db8::1'), '2001:db8::1');
    });

    test('rejects anything that is not an address', () {
      for (final String bad in <String>[
        '',
        '<html>blocked</html>',
        '999.1.1.1',
        '1.2.3',
        '1.2.3.4.5',
        '203.0.113.7 extra',
        'error: rate limited',
        '1:2:3:4:5:6:7:8:9',
        ':::',
        '1::2::3',
        'a' * 60,
      ]) {
        expect(PublicAddress.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('classify', () {
    test('public, private, shared (CGNAT), loopback and link-local IPv4', () {
      expect(PublicAddress.classify('203.0.113.7'), AddressKind.public);
      expect(PublicAddress.classify('10.1.2.3'), AddressKind.private);
      expect(PublicAddress.classify('172.16.0.1'), AddressKind.private);
      expect(PublicAddress.classify('172.31.255.1'), AddressKind.private);
      expect(PublicAddress.classify('172.32.0.1'), AddressKind.public);
      expect(PublicAddress.classify('192.168.1.1'), AddressKind.private);
      expect(PublicAddress.classify('100.64.0.1'), AddressKind.shared);
      expect(PublicAddress.classify('100.127.255.254'), AddressKind.shared);
      expect(PublicAddress.classify('100.128.0.1'), AddressKind.public);
      expect(PublicAddress.classify('127.0.0.1'), AddressKind.loopback);
      expect(PublicAddress.classify('169.254.1.1'), AddressKind.linkLocal);
    });

    test('IPv6 kinds', () {
      expect(PublicAddress.classify('::1'), AddressKind.loopback);
      expect(PublicAddress.classify('fe80::1'), AddressKind.linkLocal);
      expect(PublicAddress.classify('fd12:3456::1'), AddressKind.private);
      expect(PublicAddress.classify('2001:db8::1'), AddressKind.public);
    });

    test('text that is not an address is invalid', () {
      expect(PublicAddress.classify('hello'), AddressKind.invalid);
    });
  });
}
