import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/platform/network/ws_discovery_socket.dart';

String fixture(String name) => File('test/fixtures/onvif/$name').readAsStringSync();

/// A pretend camera: answers every Probe it receives with [reply].
Future<int> startFakeCamera(String reply, {void Function(String probe)? onProbe}) async {
  final RawDatagramSocket socket =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(socket.close);
  socket.listen((RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final Datagram? datagram = socket.receive();
    if (datagram == null) {
      return;
    }
    final String probe = utf8.decode(datagram.data);
    onProbe?.call(probe);
    if (probe.contains('Probe')) {
      socket.send(utf8.encode(reply), datagram.address, datagram.port);
    }
  });
  return socket.port;
}

void main() {
  test('finds a device that answers and reports it once', () async {
    final List<String> probes = <String>[];
    final int port = await startFakeCamera(
      fixture('probe_match.xml'),
      onProbe: probes.add,
    );
    final WsDiscoverySocket discovery = WsDiscoverySocket(
      targetAddress: '127.0.0.1',
      targetPort: port,
    );
    final List<DiscoveryResult> found = await discovery
        .probe(timeout: const Duration(milliseconds: 900))
        .toList();

    // The Probe is sent twice and the camera answers twice, but the device is
    // listed once.
    expect(found.length, 1);
    expect(found.single.host, '192.168.1.64');
    expect(found.single.port, 8080);
    expect(probes.length, greaterThanOrEqualTo(1));
    expect(probes.first, contains('NetworkVideoTransmitter'));
  });

  test('replies that are not ONVIF are ignored', () async {
    final int port = await startFakeCamera('hello there');
    final List<DiscoveryResult> found = await WsDiscoverySocket(
      targetAddress: '127.0.0.1',
      targetPort: port,
    ).probe(timeout: const Duration(milliseconds: 600)).toList();
    expect(found, isEmpty);
  });

  test('silence ends cleanly after the timeout', () async {
    final RawDatagramSocket silent =
        await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(silent.close);
    final Stopwatch clock = Stopwatch()..start();
    final List<DiscoveryResult> found = await WsDiscoverySocket(
      targetAddress: '127.0.0.1',
      targetPort: silent.port,
    ).probe(timeout: const Duration(milliseconds: 400)).toList();
    expect(found, isEmpty);
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(350));
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('cancelling ends the probe early', () async {
    final int port = await startFakeCamera(fixture('probe_match.xml'));
    final Stopwatch clock = Stopwatch()..start();
    final Completer<void> first = Completer<void>();
    final StreamSubscription<DiscoveryResult> subscription = WsDiscoverySocket(
      targetAddress: '127.0.0.1',
      targetPort: port,
    ).probe(timeout: const Duration(seconds: 30)).listen((DiscoveryResult r) {
      if (!first.isCompleted) {
        first.complete();
      }
    });
    await first.future.timeout(const Duration(seconds: 5));
    await subscription.cancel();
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
