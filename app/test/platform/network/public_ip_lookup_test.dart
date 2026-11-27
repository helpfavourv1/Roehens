import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/platform/network/public_ip_lookup.dart';

import '../../support/local_http.dart';

void main() {
  test('reads the address from a plain-text answer', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.write('203.0.113.7');
      await r.response.close();
    });
    final Result<String> result = await PublicIpLookup(endpoint: uri).fetch();
    expect(result.valueOrNull, '203.0.113.7');
  });

  test('sends no query, no cookies and no user agent', () async {
    HttpHeaders? seen;
    String? query;
    final Uri uri = await serveLocal((HttpRequest r) async {
      seen = r.headers;
      query = r.uri.query;
      r.response.write('203.0.113.7');
      await r.response.close();
    });
    await PublicIpLookup(endpoint: uri).fetch();
    expect(query, isEmpty);
    expect(seen!.value(HttpHeaders.userAgentHeader), isNull);
    expect(seen!.value(HttpHeaders.cookieHeader), isNull);
  });

  test('a page that is not an address is rejected, not shown', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.write('<html>captive portal</html>');
      await r.response.close();
    });
    final Result<String> result = await PublicIpLookup(endpoint: uri).fetch();
    expect(result.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
  });

  test('an error status is a failure', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      r.response.statusCode = 503;
      await r.response.close();
    });
    final Result<String> result = await PublicIpLookup(endpoint: uri).fetch();
    expect(result.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
  });

  test('no connection is a failure', () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final int port = server.port;
    await server.close(force: true);
    final Result<String> result = await PublicIpLookup(
      endpoint: Uri.parse('http://127.0.0.1:$port'),
      timeout: const Duration(seconds: 2),
    ).fetch();
    expect(result.errorOrNull!.errorClass, ErrorClass.networkUnreachable);
  });

  test('a stalled answer times out', () async {
    final Uri uri = await serveLocal((HttpRequest r) async {
      await Future<void>.delayed(const Duration(seconds: 3));
      await r.response.close();
    });
    final Result<String> result = await PublicIpLookup(
      endpoint: uri,
      timeout: const Duration(milliseconds: 300),
    ).fetch();
    expect(result.isErr, isTrue);
  });

  test('the service is named in one place', () {
    expect(PublicIpLookup.defaultEndpoint.toString(), 'https://api.ipify.org');
  });
}
