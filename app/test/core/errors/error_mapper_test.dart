import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';

void main() {
  const ErrorMapper mapper = ErrorMapper();

  group('message classification', () {
    final Map<String, ErrorClass> cases = <String, ErrorClass>{
      'RTSP/1.0 401 Unauthorized': ErrorClass.authFailed,
      'HTTP 403 Forbidden': ErrorClass.authFailed,
      'Authentication failed': ErrorClass.authFailed,
      'RTSP/1.0 404 Not Found': ErrorClass.pathNotFound,
      'Unsupported codec: hevc': ErrorClass.unsupportedMedia,
      'Invalid data found when processing input': ErrorClass.unsupportedMedia,
      'Connection reset by peer': ErrorClass.streamDropped,
      'Broken pipe': ErrorClass.streamDropped,
      'Connection refused': ErrorClass.networkUnreachable,
      'Operation timed out': ErrorClass.networkUnreachable,
      'No route to host': ErrorClass.networkUnreachable,
      "Failed host lookup: 'cam.local'": ErrorClass.networkUnreachable,
    };
    cases.forEach((String message, ErrorClass expected) {
      test('"$message" is $expected', () {
        expect(ErrorMapper.classifyMessage(message), expected);
      });
    });

    test('status codes inside hosts, ports and addresses are not statuses', () {
      expect(
        ErrorMapper.classifyMessage("Failed host lookup: 'cam404.local'"),
        ErrorClass.networkUnreachable,
      );
      expect(
        ErrorMapper.classifyMessage('rtsp://10.0.0.140:8401/x timed out'),
        ErrorClass.networkUnreachable,
      );
      expect(
        ErrorMapper.classifyMessage('connect to 192.168.4.401 failed'),
        ErrorClass.networkUnreachable,
      );
    });

    test('an unknown message uses the fallback', () {
      expect(
        ErrorMapper.classifyMessage('something odd'),
        ErrorClass.networkUnreachable,
      );
      expect(
        ErrorMapper.classifyMessage('something odd', fallback: ErrorClass.fatal),
        ErrorClass.fatal,
      );
    });
  });

  group('statuses', () {
    test('map to the documented classes', () {
      expect(mapper.fromStatus(401).errorClass, ErrorClass.authFailed);
      expect(mapper.fromStatus(403).errorClass, ErrorClass.authFailed);
      expect(mapper.fromStatus(404).errorClass, ErrorClass.pathNotFound);
      expect(mapper.fromStatus(461).errorClass, ErrorClass.unsupportedMedia);
      expect(mapper.fromStatus(503).errorClass, ErrorClass.networkUnreachable);
    });
  });

  group('exceptions', () {
    test('an AppError passes through unchanged', () {
      const AppError original = AppError(ErrorClass.authFailed, detail: 'x');
      expect(mapper.fromException(original), same(original));
    });

    test('a timeout is a network problem', () {
      final AppError error = mapper.fromException(
        TimeoutException('no answer', const Duration(seconds: 4)),
      );
      expect(error.errorClass, ErrorClass.networkUnreachable);
    });

    test('an unknown exception is fatal and keeps its detail', () {
      final AppError error = mapper.fromException(StateError('boom'));
      expect(error.errorClass, ErrorClass.fatal);
      expect(error.detail, contains('boom'));
    });
  });

  group('error classes', () {
    test('every class has a distinct localization key', () {
      final Set<String> keys =
          ErrorClass.values.map((ErrorClass c) => c.messageKey).toSet();
      expect(keys.length, ErrorClass.values.length);
    });

    test('only transient classes retry on their own', () {
      final Set<ErrorClass> auto = ErrorClass.values
          .where((ErrorClass c) => c.autoRetry)
          .toSet();
      expect(auto, <ErrorClass>{
        ErrorClass.networkUnreachable,
        ErrorClass.streamDropped,
      });
      for (final ErrorClass c in auto) {
        expect(c.retriable, isTrue);
      }
    });

    test('authentication and path errors are not retriable', () {
      expect(ErrorClass.authFailed.retriable, isFalse);
      expect(ErrorClass.pathNotFound.retriable, isFalse);
    });
  });

  group('Result', () {
    test('Ok carries a value', () {
      const Result<int> r = Ok<int>(3);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 3);
      expect(r.errorOrNull, isNull);
      expect(r.fold((int v) => v + 1, (AppError e) => -1), 4);
    });

    test('Err carries an error', () {
      const Result<int> r = Err<int>(AppError(ErrorClass.fatal));
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull?.errorClass, ErrorClass.fatal);
      expect(r.fold((int v) => v, (AppError e) => -1), -1);
    });
  });
}
