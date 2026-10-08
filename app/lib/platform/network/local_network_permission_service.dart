import 'dart:async';
import 'dart:io';

import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/services/lan_selector.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';
import 'package:url_launcher/url_launcher.dart';

/// What a probe of the local network found.
enum LocalNetworkOutcome { reachable, blocked, inconclusive }

/// The iOS local network permission, and the Android equivalent (none).
///
/// iOS has no call that reports this permission. The first connection to a local
/// address makes the system ask; if the person said no, later connections fail
/// with "no route to host". [requestLocalNetwork] makes such a connection and
/// reads the result. This logic has not been verified on a device: no iPhone is
/// available, so it is marked unverified in `docs/QA_MATRIX.md`.
class LocalNetworkPermissionService implements PermissionContract {
  LocalNetworkPermissionService({
    LanInfo? lan,
    MulticastLockChannel? channel,
    bool? isIos,
    Future<LocalNetworkOutcome> Function(String host)? probe,
  })  : _lan = lan ?? LanInfo(),
        _channel = channel ?? MulticastLockChannel(),
        _isIos = isIos ?? Platform.isIOS,
        _probe = probe ?? _tcpProbe;

  final LanInfo _lan;
  final MulticastLockChannel _channel;
  final bool _isIos;
  final Future<LocalNetworkOutcome> Function(String host) _probe;

  PermissionStatus _last = PermissionStatus.unknown;

  /// Maps what a connection attempt did to an outcome. `EHOSTUNREACH` (65 on
  /// Apple platforms) is what iOS returns while local network access is denied;
  /// `ECONNREFUSED` (61) means the host answered, so the network is reachable.
  static LocalNetworkOutcome outcomeFor({
    required bool connected,
    required bool timedOut,
    int? errorCode,
  }) {
    if (connected) {
      return LocalNetworkOutcome.reachable;
    }
    if (errorCode == 61 || errorCode == 111) {
      return LocalNetworkOutcome.reachable;
    }
    if (errorCode == 65 || errorCode == 113) {
      return LocalNetworkOutcome.blocked;
    }
    if (timedOut) {
      return LocalNetworkOutcome.inconclusive;
    }
    return LocalNetworkOutcome.inconclusive;
  }

  static PermissionStatus statusFor(LocalNetworkOutcome outcome) {
    switch (outcome) {
      case LocalNetworkOutcome.reachable:
        return PermissionStatus.granted;
      case LocalNetworkOutcome.blocked:
        return PermissionStatus.permanentlyDenied;
      case LocalNetworkOutcome.inconclusive:
        return PermissionStatus.unknown;
    }
  }

  static Future<LocalNetworkOutcome> _tcpProbe(String host) async {
    try {
      final Socket socket =
          await Socket.connect(host, 80, timeout: const Duration(milliseconds: 1500));
      socket.destroy();
      return outcomeFor(connected: true, timedOut: false);
    } on SocketException catch (error) {
      return outcomeFor(
        connected: false,
        timedOut: error.osError == null,
        errorCode: error.osError?.errorCode,
      );
    } on TimeoutException {
      return outcomeFor(connected: false, timedOut: true);
    } catch (_) {
      return LocalNetworkOutcome.inconclusive;
    }
  }

  @override
  Future<PermissionStatus> localNetworkStatus() async {
    if (!_isIos) {
      return PermissionStatus.notRequired;
    }
    return _last;
  }

  @override
  Future<PermissionStatus> requestLocalNetwork() async {
    if (!_isIos) {
      return PermissionStatus.notRequired;
    }
    final LanSnapshot? lan = await _lan.read();
    final String? target = lan?.gateway ??
        (lan == null ? null : LanSelector.guessGateway(lan.address));
    if (target == null) {
      return _last = PermissionStatus.unknown;
    }
    _last = statusFor(await _probe(target));
    return _last;
  }

  @override
  Future<bool> openAppSettings() async {
    if (_isIos) {
      return launchUrl(
        Uri.parse('app-settings:'),
        mode: LaunchMode.externalApplication,
      );
    }
    return _channel.openAppSettings();
  }
}
