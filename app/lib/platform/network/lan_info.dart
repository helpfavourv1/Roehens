import 'dart:io';

import 'package:roehens/core/services/lan_selector.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';

/// The phone's place on the camera network.
class LanSnapshot {
  const LanSnapshot({
    required this.address,
    required this.gateway,
    required this.gatewayIsGuess,
  });

  /// The phone's IPv4 address on the local network.
  final String address;

  /// The router address, or null when unknown.
  final String? gateway;

  /// True when [gateway] was inferred from [address] rather than read from the
  /// phone.
  final bool gatewayIsGuess;
}

/// Reads the phone's local address and gateway. Returns null from [read] when
/// the phone is not on a local network (mobile data only, or offline).
class LanInfo {
  LanInfo({
    MulticastLockChannel? channel,
    Future<List<LanInterface>> Function()? interfaces,
  })  : _channel = channel ?? MulticastLockChannel(),
        _interfaces = interfaces ?? _systemInterfaces;

  final MulticastLockChannel _channel;
  final Future<List<LanInterface>> Function() _interfaces;

  static Future<List<LanInterface>> _systemInterfaces() async {
    final List<NetworkInterface> found = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return <LanInterface>[
      for (final NetworkInterface interface in found)
        LanInterface(
          interface.name,
          <String>[for (final InternetAddress a in interface.addresses) a.address],
        ),
    ];
  }

  Future<LanSnapshot?> read() async {
    final String? address;
    try {
      address = LanSelector.chooseLocalAddress(await _interfaces());
    } catch (_) {
      return null;
    }
    if (address == null) {
      return null;
    }
    final String? real = await _channel.gateway();
    final String? gateway = real ?? LanSelector.guessGateway(address);
    return LanSnapshot(
      address: address,
      gateway: gateway,
      gatewayIsGuess: real == null && gateway != null,
    );
  }
}
