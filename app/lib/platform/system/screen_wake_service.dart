import 'package:roehens/core/contracts/device_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on through the wake-lock plugin. Calls that would not
/// change anything are skipped.
class ScreenWakeService implements ScreenWakeContract {
  ScreenWakeService({
    required this._logger,
    Future<void> Function({required bool enable})? backend,
  }) : _backend = backend ?? _plugin;

  static const String _tag = 'wake';

  final LoggerContract _logger;
  final Future<void> Function({required bool enable}) _backend;
  bool _awake = false;

  static Future<void> _plugin({required bool enable}) {
    return WakelockPlus.toggle(enable: enable);
  }

  @override
  bool get isAwake => _awake;

  @override
  Future<void> setAwake(bool awake) async {
    if (awake == _awake) {
      return;
    }
    try {
      await _backend(enable: awake);
      _awake = awake;
    } on Object catch (error) {
      _logger.warning(_tag, 'could not change screen wake lock', error: error);
    }
  }
}
