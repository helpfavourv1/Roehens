import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/global_error_handler.dart';

void main() {
  late List<AppError> reported;
  late GlobalErrorHandler handler;

  setUp(() {
    reported = <AppError>[];
    handler = GlobalErrorHandler(onReport: (AppError error, StackTrace? stack) => reported.add(error));
  });

  tearDown(() => handler.dispose());

  test('reports every error it classifies', () {
    handler.handle(StateError('boom'));
    handler.handle(const AppError(ErrorClass.networkUnreachable));
    expect(reported, hasLength(2));
  });

  test('an unexpected error is fatal and sets the fallback state', () {
    expect(handler.fatalError.value, isNull);
    handler.handle(StateError('boom'));
    expect(handler.fatalError.value?.errorClass, ErrorClass.fatal);
  });

  test('a known recoverable error does not trigger the fallback screen', () {
    handler.handle(const AppError(ErrorClass.networkUnreachable));
    expect(handler.fatalError.value, isNull);
  });

  test('clearFatal ends the fallback state', () {
    handler.handle(StateError('boom'));
    handler.clearFatal();
    expect(handler.fatalError.value, isNull);
  });

  test('listeners hear about a fatal error', () {
    int heard = 0;
    handler.fatalError.addListener(() => heard++);
    handler.handle(StateError('boom'));
    expect(heard, 1);
  });

  test('the platform error hook says it handled the error', () {
    expect(handler.onPlatformError(StateError('boom'), StackTrace.current), isTrue);
    expect(reported, hasLength(1));
  });

  test('errors thrown inside a guarded zone are caught and reported', () async {
    final Completer<void> done = Completer<void>();
    handler.runGuarded(() {
      Future<void>.delayed(Duration.zero, () {
        throw StateError('late');
      });
      Future<void>.delayed(const Duration(milliseconds: 20), done.complete);
    });
    await done.future;
    expect(reported, hasLength(1));
    expect(handler.fatalError.value, isNotNull);
  });

  test('the Flutter error hook feeds the handler', () {
    final FlutterExceptionHandler? original = FlutterError.onError;
    addTearDown(() => FlutterError.onError = original);
    handler.installFlutterErrorHook();
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('framework')));
    expect(reported, hasLength(1));
    expect(handler.fatalError.value, isNotNull);
  });
}
