import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';

/// Routes every unhandled error into one path: classify, report, and publish
/// fatal ones on [fatalError] so the app can show the fallback screen.
///
/// The three hooks of specification D5 are wired by the bootstrap:
/// `FlutterError.onError` through [installFlutterErrorHook],
/// `PlatformDispatcher.instance.onError` through [onPlatformError], and the root
/// zone through [runGuarded].
class GlobalErrorHandler {
  GlobalErrorHandler({this.mapper = const ErrorMapper(), this.onReport});

  final ErrorMapper mapper;

  /// Receives every classified error, for example the local log.
  final void Function(AppError error, StackTrace? stack)? onReport;

  /// Set to the latest fatal error; the app listens and shows the fallback.
  final ValueNotifier<AppError?> fatalError = ValueNotifier<AppError?>(null);

  void handle(Object error, [StackTrace? stack]) {
    final AppError mapped = mapper.fromException(error, stack);
    onReport?.call(mapped, stack);
    if (mapped.errorClass == ErrorClass.fatal) {
      fatalError.value = mapped;
    }
  }

  void installFlutterErrorHook() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      handle(details.exception, details.stack);
    };
  }

  /// Assign to `PlatformDispatcher.instance.onError`. Returns true: handled.
  bool onPlatformError(Object error, StackTrace stack) {
    handle(error, stack);
    return true;
  }

  /// Runs [body] in a guarded zone; uncaught errors go to [handle].
  R? runGuarded<R>(R Function() body) {
    return runZonedGuarded<R>(body, handle);
  }

  /// Clears the fatal state, for the fallback screen's Retry action.
  void clearFatal() {
    fatalError.value = null;
  }

  void dispose() {
    fatalError.dispose();
  }
}
