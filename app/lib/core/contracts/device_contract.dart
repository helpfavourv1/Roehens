/// Short tactile feedback. Every method is a no-op when the person turned
/// haptics off, and none of them throws.
abstract interface class HapticsContract {
  /// Primary actions.
  Future<void> light();

  /// Layout change or selection.
  Future<void> selection();

  /// Snapshot taken.
  Future<void> success();

  /// Errors.
  Future<void> warning();
}

/// Keeps the screen on while cameras are on screen.
abstract interface class ScreenWakeContract {
  /// Idempotent. Failures are logged, never thrown.
  Future<void> setAwake(bool awake);

  bool get isAwake;
}

/// Orientation and system bars for the viewer.
abstract interface class OrientationContract {
  /// Normal behavior: follow the device.
  Future<void> allowAll();

  Future<void> lockLandscape();

  Future<void> lockPortrait();

  /// Hides the system bars for fullscreen video; false restores them.
  Future<void> setImmersive({required bool immersive});
}
