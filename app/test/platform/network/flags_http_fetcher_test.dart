import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/platform/network/flags_http_fetcher.dart';

import '../../support/local_http.dart';

void main() {
  const Duration timeout = Duration(seconds: 2);

  test('returns the body of a 200 response', () async {
    final Uri url = await serveLocal((HttpRequest request) async {
      request.response.write('{"schemaVersion":1}');
      await request.response.close();
    });

    expect(await fetchFlagsText(url, timeout), '{"schemaVersion":1}');
  });

  test('sends no cookies or credentials', () async {
    final List<String> seen = <String>[];
    final Uri url = await serveLocal((HttpRequest request) async {
      request.headers.forEach((String name, List<String> _) => seen.add(name));
      await request.response.close();
    });
    await fetchFlagsText(url, timeout);

    expect(seen, isNot(contains('cookie')));
    expect(seen, isNot(contains('authorization')));
  });

  test('throws on a non-200 status', () async {
    final Uri url = await serveLocal((HttpRequest request) async {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
    });

    expect(fetchFlagsText(url, timeout), throwsA(isA<HttpException>()));
  });

  test('throws when the file is larger than the limit', () async {
    final Uri url = await serveLocal((HttpRequest request) async {
      request.response.write('x' * (Limits.flagsMaxBytes + 10));
      await request.response.close();
    });

    expect(fetchFlagsText(url, timeout), throwsA(isA<HttpException>()));
  });

  test('throws when the server does not answer in time', () async {
    final Uri url = await serveLocal((HttpRequest request) async {
      await Future<void>.delayed(const Duration(seconds: 5));
    });

    await expectLater(
      fetchFlagsText(url, const Duration(milliseconds: 300)),
      throwsA(anything),
    );
  });
}
