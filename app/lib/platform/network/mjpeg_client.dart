import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/mjpeg_stream_parser.dart';

/// HTTP client for MJPEG cameras and single-image snapshot addresses.
///
/// Implemented in Dart rather than through the player engine because the
/// bundled FFmpeg build cannot read the multipart format cameras send. It
/// behaves the same on both platforms and hands over the JPEG frames directly.
///
/// Authentication is Basic or Digest, whichever the camera asks for. Every
/// failure is thrown as an [AppError].
class MjpegClient {
  MjpegClient({
    this.connectTimeout = const Duration(seconds: 8),
    this.idleTimeout = const Duration(seconds: 10),
    this.errorMapper = const ErrorMapper(),
    HttpClient Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? HttpClient.new;

  /// How long to wait for the connection and the response headers.
  final Duration connectTimeout;

  /// How long the stream may stay silent before it counts as dropped.
  final Duration idleTimeout;

  final ErrorMapper errorMapper;
  final HttpClient Function() _clientFactory;

  /// JPEG frames of the stream at [uri], until the server closes it or the
  /// caller cancels. Cancelling closes the connection.
  Stream<Uint8List> frames(
    Uri uri, {
    CameraCredentials credentials = CameraCredentials.none,
  }) async* {
    final HttpClient client = _newClient(credentials);
    try {
      final HttpClientResponse response = await _open(client, uri);
      if (_isSingleImage(response)) {
        yield await _collectJpeg(response);
        return;
      }
      final MjpegStreamParser parser = MjpegStreamParser(
        boundary: MjpegStreamParser.boundaryFromContentType(
          response.headers.contentType?.toString(),
        ),
      );
      await for (final List<int> chunk in response.timeout(idleTimeout)) {
        final Uint8List bytes =
            chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        for (final Uint8List frame in parser.add(bytes)) {
          yield frame;
        }
      }
    } on AppError {
      rethrow;
    } catch (error) {
      throw errorMapper.fromException(error);
    } finally {
      client.close(force: true);
    }
  }

  /// One JPEG image from a snapshot address.
  Future<Uint8List> fetchSnapshot(
    Uri uri, {
    CameraCredentials credentials = CameraCredentials.none,
  }) async {
    final HttpClient client = _newClient(credentials);
    try {
      final HttpClientResponse response = await _open(client, uri);
      return await _collectJpeg(response);
    } on AppError {
      rethrow;
    } catch (error) {
      throw errorMapper.fromException(error);
    } finally {
      client.close(force: true);
    }
  }

  HttpClient _newClient(CameraCredentials credentials) {
    final HttpClient client = _clientFactory()..connectionTimeout = connectTimeout;
    if (!credentials.isEmpty) {
      client.authenticate = (Uri url, String scheme, String? realm) async {
        final HttpClientCredentials secret = scheme.toLowerCase() == 'digest'
            ? HttpClientDigestCredentials(
                credentials.username,
                credentials.password,
              )
            : HttpClientBasicCredentials(
                credentials.username,
                credentials.password,
              );
        client.addCredentials(url, realm ?? '', secret);
        return true;
      };
    }
    return client;
  }

  Future<HttpClientResponse> _open(HttpClient client, Uri uri) async {
    final HttpClientRequest request =
        await client.getUrl(uri).timeout(connectTimeout);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'multipart/x-mixed-replace, image/jpeg',
    );
    final HttpClientResponse response =
        await request.close().timeout(connectTimeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw errorMapper.fromStatus(response.statusCode);
    }
    return response;
  }

  bool _isSingleImage(HttpClientResponse response) {
    return response.headers.contentType?.mimeType == 'image/jpeg';
  }

  Future<Uint8List> _collectJpeg(HttpClientResponse response) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in response.timeout(idleTimeout)) {
      builder.add(chunk);
    }
    final Uint8List bytes = builder.takeBytes();
    final bool isJpeg = bytes.length >= 4 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9;
    if (!isJpeg) {
      throw const AppError(
        ErrorClass.unsupportedMedia,
        detail: 'response is not a complete JPEG image',
      );
    }
    return bytes;
  }
}
