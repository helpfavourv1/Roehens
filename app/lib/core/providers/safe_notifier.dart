import 'package:flutter/foundation.dart';

/// A [ValueNotifier] that ignores writes after it was disposed, so a slow
/// storage call that finishes late cannot throw.
class SafeValueNotifier<T> extends ValueNotifier<T> {
  SafeValueNotifier(super.value);

  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// Sets [next] unless this notifier was disposed.
  void setIfAlive(T next) {
    if (!_disposed) {
      value = next;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
