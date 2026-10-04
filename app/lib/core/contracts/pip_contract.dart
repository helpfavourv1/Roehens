import 'package:flutter/foundation.dart';

/// Android picture-in-picture. On iOS [isSupported] is false and every method
/// does nothing.
abstract interface class PipContract {
  bool get isSupported;

  /// True while the app window is in picture-in-picture.
  ValueListenable<bool> get isInPip;

  /// Enters picture-in-picture with a 16:9 window. Returns false when the
  /// system refuses or the feature is unsupported.
  Future<bool> enter();
}
