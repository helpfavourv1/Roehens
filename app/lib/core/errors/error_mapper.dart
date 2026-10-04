import 'dart:async';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';

/// Converts platform exceptions, HTTP and RTSP statuses and player messages to
/// [AppError]. Pure Dart: exception types from `dart:io` are recognized by name
/// so this file does not import it.
class ErrorMapper {
  const ErrorMapper();

  AppError fromException(Object error, [StackTrace? stack]) {
    if (error is AppError) {
      return error;
    }
    if (error is TimeoutException) {
      return AppError(
        ErrorClass.networkUnreachable,
        detail: 'timeout: ${error.message ?? ''}'.trim(),
      );
    }
    final String type = error.runtimeType.toString();
    final String text = error.toString();
    const Set<String> networkTypes = <String>{
      'SocketException',
      'HandshakeException',
      'HttpException',
      'TlsException',
      'WebSocketException',
      'ClientException',
    };
    if (networkTypes.contains(type)) {
      return AppError(classifyMessage(text), detail: '$type: $text');
    }
    return AppError(ErrorClass.fatal, detail: '$type: $text');
  }

  /// HTTP status or RTSP status code.
  AppError fromStatus(int status, {String? detail}) {
    final ErrorClass errorClass;
    if (status == 401 || status == 403) {
      errorClass = ErrorClass.authFailed;
    } else if (status == 404) {
      errorClass = ErrorClass.pathNotFound;
    } else if (status == 415 || status == 461) {
      errorClass = ErrorClass.unsupportedMedia;
    } else {
      errorClass = ErrorClass.networkUnreachable;
    }
    return AppError(errorClass, detail: detail ?? 'status $status');
  }

  /// A free-text message from the player engine or a socket.
  AppError fromPlayerMessage(String message) {
    return AppError(classifyMessage(message), detail: message);
  }

  // A status code stands alone: not part of a longer number, a host name or an
  // IP address octet.
  static final RegExp _authCode = RegExp(r'(^|[^0-9a-z.])(401|403)($|[^0-9a-z.])');
  static final RegExp _notFoundCode = RegExp(r'(^|[^0-9a-z.])404($|[^0-9a-z.])');

  /// Classifies [message] by well-known phrases. DNS failures are checked before
  /// "not found" so an unknown host is not reported as a wrong path.
  static ErrorClass classifyMessage(
    String message, {
    ErrorClass fallback = ErrorClass.networkUnreachable,
  }) {
    final String text = message.toLowerCase();
    bool has(List<String> phrases) {
      return phrases.any(text.contains);
    }

    if (_authCode.hasMatch(text) ||
        has(<String>['unauthorized', 'forbidden', 'authentication'])) {
      return ErrorClass.authFailed;
    }
    if (has(<String>[
      'host lookup',
      'name or service not known',
      'nodename nor servname',
      'no address associated',
    ])) {
      return ErrorClass.networkUnreachable;
    }
    if (_notFoundCode.hasMatch(text) ||
        has(<String>['not found', 'no such stream'])) {
      return ErrorClass.pathNotFound;
    }
    if (has(<String>[
      'codec',
      'unsupported',
      'unrecognized',
      'invalid data found',
      'unknown format',
    ])) {
      return ErrorClass.unsupportedMedia;
    }
    if (has(<String>[
      'connection reset',
      'broken pipe',
      'end of file',
      'eof',
      'stream ended',
    ])) {
      return ErrorClass.streamDropped;
    }
    if (has(<String>[
      'timed out',
      'timeout',
      'refused',
      'unreachable',
      'no route',
      'network is',
    ])) {
      return ErrorClass.networkUnreachable;
    }
    return fallback;
  }
}
