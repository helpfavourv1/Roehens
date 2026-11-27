import 'dart:async';
import 'dart:io';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/services/public_address.dart';

/// Asks one public service which address the internet sees for this phone.
///
/// The service is `api.ipify.org` over HTTPS (docs/DECISIONS.md). The request
/// carries no camera data, no person data and no app identity: no query, no
/// cookies and no user-agent header. It runs only when the person presses the
/// button on the Diagnostics screen, never by itself, and it is disclosed in
/// the privacy policy and the store privacy forms.
class PublicIpLookup {
  PublicIpLookup({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 6),
    HttpClient Function()? clientFactory,
  }) : endpoint = endpoint ?? defaultEndpoint,
       _clientFactory = clientFactory ?? HttpClient.new;

  static final Uri defaultEndpoint = Uri.parse('https://api.ipify.org');

  final Uri endpoint;
  final Duration timeout;
  final HttpClient Function() _clientFactory;

  Future<Result<String>> fetch() async {
    final HttpClient client = _clientFactory()
      ..connectionTimeout = timeout
      ..userAgent = null;
    try {
      final HttpClientRequest request = await client
          .getUrl(endpoint)
          .timeout(timeout);
      final HttpClientResponse response = await request.close().timeout(
        timeout,
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return const Err<String>(AppError(ErrorClass.networkUnreachable));
      }
      final StringBuffer body = StringBuffer();
      await for (final String chunk
          in response.transform(const SystemEncoding().decoder).timeout(
            timeout,
          )) {
        body.write(chunk);
        if (body.length > 256) {
          break;
        }
      }
      final String? address = PublicAddress.parse(body.toString());
      if (address == null) {
        return const Err<String>(
          AppError(ErrorClass.networkUnreachable, detail: 'unexpected answer'),
        );
      }
      return Ok<String>(address);
    } on TimeoutException {
      return const Err<String>(AppError(ErrorClass.networkUnreachable));
    } on SocketException {
      return const Err<String>(AppError(ErrorClass.networkUnreachable));
    } on HandshakeException {
      return const Err<String>(AppError(ErrorClass.networkUnreachable));
    } on HttpException {
      return const Err<String>(AppError(ErrorClass.networkUnreachable));
    } finally {
      client.close(force: true);
    }
  }
}
