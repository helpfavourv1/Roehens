import 'dart:async';

import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/platform/network/lan_info.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';
import 'package:roehens/platform/network/subnet_scanner.dart';
import 'package:roehens/platform/network/ws_discovery_socket.dart';

/// One discovery run (D4): the ONVIF probe and the subnet sweep side by side.
/// The sweep is always on; the probe is off on iOS until Apple grants the
/// multicast entitlement. On Android the multicast lock is held for the run.
class DiscoveryService implements DiscoveryContract {
  DiscoveryService({
    required this._lan,
    required this._scanner,
    required this._socket,
    required this._channel,
    this.wsDiscoveryEnabled = true,
    this._logger,
  });

  static const String _tag = 'discovery';

  final LanInfo _lan;
  final SubnetScanner _scanner;
  final WsDiscoverySocket _socket;
  final MulticastLockChannel _channel;
  final LoggerContract? _logger;

  /// False on iOS while the multicast entitlement is pending.
  final bool wsDiscoveryEnabled;

  @override
  Stream<DiscoveryEvent> discover({required Duration timeout}) {
    final StreamController<DiscoveryEvent> controller =
        StreamController<DiscoveryEvent>();
    StreamSubscription<DiscoveryResult>? probeSub;
    StreamSubscription<OpenPort>? sweepSub;
    Timer? deadline;
    bool lockHeld = false;
    bool finished = false;

    Future<void> finish() async {
      if (finished) {
        return;
      }
      finished = true;
      deadline?.cancel();
      await probeSub?.cancel();
      await sweepSub?.cancel();
      if (lockHeld) {
        await _channel.release();
        lockHeld = false;
      }
      if (!controller.isClosed) {
        controller.add(const DiscoveryFinished());
        await controller.close();
      }
    }

    controller.onCancel = () async {
      finished = true;
      deadline?.cancel();
      await probeSub?.cancel();
      await sweepSub?.cancel();
      if (lockHeld) {
        await _channel.release();
      }
    };

    controller.onListen = () async {
      deadline = Timer(timeout, finish);
      try {
        if (wsDiscoveryEnabled) {
          lockHeld = await _channel.acquire();
          probeSub = _socket.probe().listen(
            (DiscoveryResult result) {
              if (!controller.isClosed) {
                controller.add(DiscoveryFound(result));
              }
            },
            onError: (Object error) {
              _logger?.warning(_tag, 'ONVIF probe failed', error: error);
            },
          );
        }
        final LanSnapshot? lan = await _lan.read();
        if (lan == null) {
          _logger?.info(_tag, 'no local network, sweep skipped');
          if (!wsDiscoveryEnabled) {
            await finish();
          }
          return;
        }
        sweepSub = _scanner
            .scan(
              lan.address,
              onProgress: (double fraction) {
                if (!controller.isClosed) {
                  controller.add(DiscoveryProgressed(fraction));
                }
              },
            )
            .listen(
          (OpenPort open) {
            if (!controller.isClosed) {
              controller.add(
                DiscoveryFound(
                  DiscoveryResult(
                    host: open.host,
                    port: open.port,
                    source: DiscoverySource.sweep,
                  ),
                ),
              );
            }
          },
          onError: (Object error) {
            _logger?.warning(_tag, 'sweep failed', error: error);
          },
          onDone: () {
            unawaited(finish());
          },
        );
      } catch (error) {
        _logger?.warning(_tag, 'discovery could not start', error: error);
        await finish();
      }
    };
    return controller.stream;
  }
}
