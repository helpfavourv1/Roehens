import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roehens/core/constants/limits.dart';

/// Downloads a small text file over HTTP(S) for the remote flags. Sends no
/// cookies, no identifiers and no body. Throws on any failure.
Future<String> fetchFlagsText(Uri url, Duration timeout) async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = 'Roehens';
  try {
    final HttpClientRequest request = await client.getUrl(url).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    final HttpClientResponse response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in response.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > Limits.flagsMaxBytes) {
        throw HttpException('flags file too large', uri: url);
      }
    }
    return utf8.decode(bytes);
  } finally {
    client.close(force: true);
  }
}
