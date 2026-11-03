import 'dart:async';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// Starts a one-shot timer. Replaced in tests.
typedef TimerFactory = Timer Function(Duration delay, void Function() onFire);

Timer _realTimer(Duration delay, void Function() onFire) =>
    Timer(delay, onFire);

/// Local timer behind auto-cycle (D15). In the grid the screen advances a page
/// on every tick; in fullscreen it advances the camera. Any touch restarts the
/// wait, so the screen never changes under a finger, and the cycle stops while
/// the app is not on screen.
class AutoCycleProvider extends SafeValueNotifier<bool> {
  AutoCycleProvider({TimerFactory? timerFactory})
    : _timerFactory = timerFactory ?? _realTimer,
      super(false);

  final TimerFactory _timerFactory;

  /// Counts ticks. Screens listen and advance when it changes.
  final SafeValueNotifier<int> ticks = SafeValueNotifier<int>(0);

  Timer? _timer;
  bool _enabled = false;
  int _seconds = Limits.defaultAutoCycleSeconds;
  bool _foreground = true;
  bool _viewing = false;

  /// The interval in force: the layout's own, else the global one.
  static int effectiveSeconds(AppSettings settings, GridLayout layout) {
    return layout.autoCycleSeconds ?? settings.autoCycleSeconds;
  }

  /// True while a timer is counting.
  bool get isRunning => value;

  /// Applies the settings. Safe to call whenever they change.
  void configure({required bool enabled, required int seconds}) {
    _enabled = enabled;
    _seconds = Limits.autoCycleSeconds.contains(seconds)
        ? seconds
        : Limits.defaultAutoCycleSeconds;
    _reschedule();
  }

  /// Tell the provider whether a screen that cycles (Live or Fullscreen) is
  /// showing.
  void setViewing({required bool viewing}) {
    _viewing = viewing;
    _reschedule();
  }

  /// False while the app is in the background.
  void setForeground({required bool foreground}) {
    _foreground = foreground;
    _reschedule();
  }

  /// A touch: wait one full interval before the next advance.
  void userInteracted() {
    if (value) {
      _reschedule();
    }
  }

  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    final bool shouldRun = _enabled && _foreground && _viewing;
    setIfAlive(shouldRun);
    if (shouldRun) {
      _timer = _timerFactory(Duration(seconds: _seconds), _fire);
    }
  }

  void _fire() {
    if (isDisposed || !value) {
      return;
    }
    ticks.setIfAlive(ticks.value + 1);
    _reschedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    ticks.dispose();
    super.dispose();
  }
}
