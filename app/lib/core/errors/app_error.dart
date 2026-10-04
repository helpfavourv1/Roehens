import 'package:roehens/core/errors/error_class.dart';

/// A classified failure. [detail] is diagnostic text for the optional feedback
/// attachment; it is never shown by default and never contains credentials.
class AppError implements Exception {
  const AppError(this.errorClass, {this.detail});

  final ErrorClass errorClass;
  final String? detail;

  String get messageKey => errorClass.messageKey;
  bool get retriable => errorClass.retriable;
  bool get autoRetry => errorClass.autoRetry;

  @override
  bool operator ==(Object other) {
    return other is AppError &&
        other.errorClass == errorClass &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(errorClass, detail);

  @override
  String toString() {
    final String suffix = detail == null ? '' : ': $detail';
    return 'AppError(${errorClass.name}$suffix)';
  }
}
