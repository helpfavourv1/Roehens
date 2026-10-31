import 'package:flutter/services.dart';
import 'package:roehens/core/contracts/device_contract.dart';

/// Haptics through the platform's own feedback calls, so no dependency is
/// needed. [isEnabled] is read on every call, so the setting takes effect at
/// once.
class HapticsService implements HapticsContract {
  HapticsService({required this._isEnabled});

  final bool Function() _isEnabled;

  @override
  Future<void> light() => _run(HapticFeedback.lightImpact);

  @override
  Future<void> selection() => _run(HapticFeedback.selectionClick);

  @override
  Future<void> success() => _run(HapticFeedback.mediumImpact);

  @override
  Future<void> warning() => _run(HapticFeedback.heavyImpact);

  Future<void> _run(Future<void> Function() feedback) async {
    if (!_isEnabled()) {
      return;
    }
    try {
      await feedback();
    } on Object {
      // A device without a vibration motor is not an error.
    }
  }
}
