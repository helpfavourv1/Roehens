import 'package:roehens/core/errors/app_error.dart';

/// Either a value or an [AppError]. Services return this instead of throwing
/// for expected failures.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  T? get valueOrNull {
    return switch (this) {
      Ok<T>(:final T value) => value,
      Err<T>() => null,
    };
  }

  AppError? get errorOrNull {
    return switch (this) {
      Ok<T>() => null,
      Err<T>(:final AppError error) => error,
    };
  }

  R fold<R>(R Function(T value) onOk, R Function(AppError error) onErr) {
    return switch (this) {
      Ok<T>(:final T value) => onOk(value),
      Err<T>(:final AppError error) => onErr(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;
}
