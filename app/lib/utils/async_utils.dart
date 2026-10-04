import 'dart:async';

/// Runs the most recent action once [delay] has passed without a new call.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}

/// Completes with [future]'s value, or with [onTimeout]'s value when [limit]
/// passes first.
Future<T> withTimeout<T>(
  Future<T> future,
  Duration limit, {
  required T Function() onTimeout,
}) {
  return future.timeout(limit, onTimeout: onTimeout);
}

/// Completes with [future]'s value, or null when [limit] passes first.
Future<T?> timeoutOrNull<T>(Future<T> future, Duration limit) {
  return future.then<T?>((T value) => value).timeout(
        limit,
        onTimeout: () => null,
      );
}
