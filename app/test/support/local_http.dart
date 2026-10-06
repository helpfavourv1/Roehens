import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Starts a loopback HTTP server for the rest of the current test and returns
/// the address it listens on. Errors from clients disconnecting mid-write are
/// ignored.
Future<Uri> serveLocal(
  FutureOr<void> Function(HttpRequest request) handler,
) async {
  final HttpServer server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((HttpRequest request) async {
    try {
      await handler(request);
    } catch (_) {
      // The client may close the connection at any moment.
    }
  });
  return Uri.parse('http://127.0.0.1:${server.port}/video.mjpg');
}
