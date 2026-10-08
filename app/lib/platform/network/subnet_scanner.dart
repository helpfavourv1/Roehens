import 'dart:async';
import 'dart:io';

import 'package:roehens/core/constants/limits.dart';

/// A host that accepted a connection on a camera-like port.
class OpenPort {
  const OpenPort(this.host, this.port);

  final String host;
  final int port;

  @override
  bool operator ==(Object other) {
    return other is OpenPort && other.host == host && other.port == port;
  }

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => '$host:$port';
}

/// Tries to open a TCP connection; true when it succeeds within [timeout].
typedef PortConnector = Future<bool> Function(
  String host,
  int port,
  Duration timeout,
);

Future<bool> _tcpConnect(String host, int port, Duration timeout) async {
  try {
    final Socket socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Sweeps the /24 network of the phone for hosts with camera ports open
/// (specification D4): ports 80, 554, 8000, 8080 and 8554, 48 connections at a
/// time, 400 ms each.
class SubnetScanner {
  SubnetScanner({
    PortConnector? connector,
    this.ports = Limits.sweepPorts,
    this.concurrency = Limits.sweepConcurrency,
    this.connectTimeout = Limits.sweepConnectTimeout,
  }) : _connector = connector ?? _tcpConnect;

  final PortConnector _connector;
  final List<int> ports;
  final int concurrency;
  final Duration connectTimeout;

  /// Every address of the /24 around [localAddress] except the phone itself, the
  /// network address and the broadcast address. Empty when [localAddress] is
  /// not a dotted IPv4 address.
  static List<String> hostsOf(String localAddress) {
    final List<String> parts = localAddress.split('.');
    if (parts.length != 4) {
      return const <String>[];
    }
    final List<int?> numbers = parts.map(int.tryParse).toList();
    if (numbers.any((int? n) => n == null || n < 0 || n > 255)) {
      return const <String>[];
    }
    final String prefix = '${numbers[0]}.${numbers[1]}.${numbers[2]}';
    final int own = numbers[3]!;
    return <String>[
      for (int host = 1; host <= 254; host++)
        if (host != own) '$prefix.$host',
    ];
  }

  /// Open ports as they are found. Ports are tried one after another across all
  /// hosts (port-major), so the commonest camera ports report first. Cancelling
  /// the subscription stops the sweep. [onProgress] gets 0..1.
  Stream<OpenPort> scan(
    String localAddress, {
    void Function(double fraction)? onProgress,
  }) {
    final StreamController<OpenPort> controller = StreamController<OpenPort>();
    bool cancelled = false;
    controller.onCancel = () {
      cancelled = true;
    };
    unawaited(
      _run(localAddress, controller, () => cancelled, onProgress)
          .whenComplete(() async {
        if (!controller.isClosed) {
          await controller.close();
        }
      }),
    );
    return controller.stream;
  }

  Future<void> _run(
    String localAddress,
    StreamController<OpenPort> controller,
    bool Function() isCancelled,
    void Function(double fraction)? onProgress,
  ) async {
    final List<String> hosts = hostsOf(localAddress);
    final List<OpenPort> tasks = <OpenPort>[
      for (final int port in ports)
        for (final String host in hosts) OpenPort(host, port),
    ];
    if (tasks.isEmpty) {
      onProgress?.call(1);
      return;
    }
    int next = 0;
    int finished = 0;

    Future<void> worker() async {
      while (!isCancelled()) {
        final int index = next++;
        if (index >= tasks.length) {
          return;
        }
        final OpenPort task = tasks[index];
        bool open = false;
        try {
          open = await _connector(task.host, task.port, connectTimeout);
        } catch (_) {
          open = false;
        }
        if (isCancelled()) {
          return;
        }
        if (open && !controller.isClosed) {
          controller.add(task);
        }
        finished++;
        onProgress?.call(finished / tasks.length);
      }
    }

    await Future.wait(<Future<void>>[
      for (int i = 0; i < concurrency; i++) worker(),
    ]);
  }
}
