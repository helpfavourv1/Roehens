/// What kind of address a public-address lookup returned.
enum AddressKind { public, private, shared, loopback, linkLocal, invalid }

/// Reading and classifying the address the lookup service reports.
class PublicAddress {
  PublicAddress._();

  /// The address in a lookup response, or null when the text is not a single
  /// IPv4 or IPv6 address. Anything else (a web page, an error message) is
  /// rejected so it is never shown as an address.
  static String? parse(String response) {
    final String text = response.trim();
    if (text.isEmpty || text.length > 45 || text.contains(RegExp(r'\s'))) {
      return null;
    }
    return _v4(text) != null || _isV6(text) ? text : null;
  }

  static AddressKind classify(String address) {
    final List<int>? v4 = _v4(address);
    if (v4 != null) {
      final int a = v4[0];
      final int b = v4[1];
      if (a == 127) {
        return AddressKind.loopback;
      }
      if (a == 10 ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 168)) {
        return AddressKind.private;
      }
      if (a == 100 && b >= 64 && b <= 127) {
        return AddressKind.shared;
      }
      if (a == 169 && b == 254) {
        return AddressKind.linkLocal;
      }
      return AddressKind.public;
    }
    if (_isV6(address)) {
      final String lower = address.toLowerCase();
      if (lower == '::1') {
        return AddressKind.loopback;
      }
      if (lower.startsWith('fe80')) {
        return AddressKind.linkLocal;
      }
      if (lower.startsWith('fc') || lower.startsWith('fd')) {
        return AddressKind.private;
      }
      return AddressKind.public;
    }
    return AddressKind.invalid;
  }

  static List<int>? _v4(String text) {
    final List<String> parts = text.split('.');
    if (parts.length != 4) {
      return null;
    }
    final List<int> numbers = <int>[];
    for (final String p in parts) {
      if (p.isEmpty || p.length > 3 || !RegExp(r'^\d+$').hasMatch(p)) {
        return null;
      }
      final int n = int.parse(p);
      if (n > 255) {
        return null;
      }
      numbers.add(n);
    }
    return numbers;
  }

  static bool _isV6(String text) {
    if (!text.contains(':') || !RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(text)) {
      return false;
    }
    if (text.contains(':::')) {
      return false;
    }
    final int doubles = '::'.allMatches(text).length;
    if (doubles > 1) {
      return false;
    }
    final List<String> groups = text.split(':');
    if (doubles == 0 && groups.length != 8) {
      return false;
    }
    if (groups.length > 8) {
      return false;
    }
    return groups.every((String g) => g.length <= 4 || g.contains('.'));
  }
}
