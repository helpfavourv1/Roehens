import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/services/ws_discovery_codec.dart';

/// Sends a WS-Discovery Probe to the multicast group and collects the ONVIF
/// devices that answer. Replies arrive as unicast datagrams, so no group
/// membership is needed; on Android the multicast lock still has to be held
/// (see `MulticastLockChannel`) for some phones to deliver them.
class WsDiscoverySocket {
  WsDiscoverySocket({
    this.codec = const WsDiscoveryCodec(),
    String? targetAddress,
    int? targetPort,
  })  : targetAddress = targetAddress ?? Limits.wsDiscoveryAddress,
        targetPort = targetPort ?? Limits.wsDiscoveryPort;

  final WsDiscoveryCodec codec;

  /// Where the Probe goes. The multicast group in production; a loopback address
  /// in tests.
  final String targetAddress;
  final int targetPort;

  /// Devices that answer within [timeout], each reported once (by host and
  /// port). The Probe is sent twice, 300 ms apart, because UDP can drop it.
  Stream<DiscoveryResult> probe({
    Duration timeout = const Duration(seconds: 4),
  }) {
    final StreamController<DiscoveryResult> controller =
        StreamController<DiscoveryResult>();
    RawDatagramSocket? socket;
    Timer? stopTimer;
    Timer? resendTimer;

    Future<void> shutdown() async {
      stopTimer?.cancel();
      resendTimer?.cancel();
      socket?.close();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onCancel = shutdown;
    controller.onListen = () async {
      try {
        final RawDatagramSocket bound =
            await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket = bound;
        final Set<String> seen = <String>{};
        bound.listen((RawSocketEvent event) {
          if (event != RawSocketEvent.read) {
            return;
          }
          Datagram? datagram = bound.receive();
          while (datagram != null) {
            final DiscoveryResult? result =
                codec.parseProbeMatch(utf8.decode(datagram.data, allowMalformed: true));
            if (result != null && seen.add('${result.host}:${result.port}')) {
              if (!controller.isClosed) {
                controller.add(result);
              }
            }
            datagram = bound.receive();
          }
        });

        final List<int> message =
            utf8.encode(codec.buildProbe(messageId: generateCameraId()));
        final InternetAddress target = InternetAddress(targetAddress);
        bound.send(message, target, targetPort);
        resendTimer = Timer(const Duration(milliseconds: 300), () {
          bound.send(message, target, targetPort);
        });
        stopTimer = Timer(timeout, shutdown);
      } catch (_) {
        await shutdown();
      }
    };
    return controller.stream;
  }
}
