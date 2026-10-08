/// A network interface of the phone with its IPv4 addresses.
class LanInterface {
  const LanInterface(this.name, this.addresses);

  final String name;
  final List<String> addresses;
}

/// Chooses which of the phone's addresses is on the local network the cameras
/// are on. Pure logic; the platform layer supplies the interfaces.
class LanSelector {
  LanSelector._();

  /// 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16.
  static bool isPrivateIpv4(String address) {
    final List<int?> parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((int? p) => p == null || p < 0 || p > 255)) {
      return false;
    }
    final int a = parts[0]!;
    final int b = parts[1]!;
    return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  }

  /// Interfaces that carry mobile data or tunnels, never a camera network.
  static bool _isMobileOrTunnel(String name) {
    final String lower = name.toLowerCase();
    return const <String>['rmnet', 'ccmni', 'pdp', 'tun', 'ppp', 'ipsec', 'utun']
        .any(lower.startsWith);
  }

  static bool _looksLikeWifiOrEthernet(String name) {
    final String lower = name.toLowerCase();
    return const <String>['wlan', 'wifi', 'eth', 'en0', 'en1']
        .any(lower.startsWith);
  }

  /// The phone's address on the camera network, or null when it is not on one
  /// (for example on mobile data only). Wi-Fi and Ethernet are preferred.
  static String? chooseLocalAddress(List<LanInterface> interfaces) {
    String? fallback;
    for (final LanInterface interface in interfaces) {
      if (_isMobileOrTunnel(interface.name)) {
        continue;
      }
      for (final String address in interface.addresses) {
        if (!isPrivateIpv4(address)) {
          continue;
        }
        if (_looksLikeWifiOrEthernet(interface.name)) {
          return address;
        }
        fallback ??= address;
      }
    }
    return fallback;
  }

  /// A router address guessed from the phone's address: the first host of its
  /// /24. Only a guess; the Android channel reports the real gateway.
  static String? guessGateway(String address) {
    if (!isPrivateIpv4(address)) {
      return null;
    }
    final List<String> parts = address.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}.1';
  }
}
