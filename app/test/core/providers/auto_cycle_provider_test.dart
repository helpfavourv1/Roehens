import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/providers/auto_cycle_provider.dart';

/// A timer the test fires by hand.
class _ManualTimer implements Timer {
  _ManualTimer(this.delay, this._onFire);

  final Duration delay;
  final void Function() _onFire;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    fired = true;
    _onFire();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => 0;
}

void main() {
  late List<_ManualTimer> timers;
  late AutoCycleProvider provider;

  _ManualTimer? active() {
    final Iterable<_ManualTimer> live = timers.where((_ManualTimer t) => t.isActive);
    return live.isEmpty ? null : live.last;
  }

  setUp(() {
    timers = <_ManualTimer>[];
    provider = AutoCycleProvider(
      timerFactory: (Duration delay, void Function() onFire) {
        final _ManualTimer timer = _ManualTimer(delay, onFire);
        timers.add(timer);
        return timer;
      },
    );
  });

  tearDown(() => provider.dispose());

  test('does nothing until enabled and a cycling screen is showing', () {
    provider.configure(enabled: true, seconds: 10);
    expect(provider.isRunning, isFalse);
    expect(active(), isNull);

    provider.setViewing(viewing: true);
    expect(provider.isRunning, isTrue);
    expect(active()?.delay, const Duration(seconds: 10));
  });

  test('every tick counts once and the timer starts again', () {
    provider
      ..configure(enabled: true, seconds: 5)
      ..setViewing(viewing: true);

    active()!.fire();
    expect(provider.ticks.value, 1);
    active()!.fire();
    expect(provider.ticks.value, 2);
    expect(active()?.delay, const Duration(seconds: 5));
  });

  test('a touch restarts the wait for a full interval', () {
    provider
      ..configure(enabled: true, seconds: 15)
      ..setViewing(viewing: true);
    final _ManualTimer first = active()!;

    provider.userInteracted();

    expect(first.cancelled, isTrue);
    expect(active(), isNot(same(first)));
    expect(active()?.delay, const Duration(seconds: 15));
    expect(provider.ticks.value, 0);
  });

  test('a touch while stopped does not start it', () {
    provider.userInteracted();
    expect(active(), isNull);
  });

  test('stops when the app goes to the background and resumes after', () {
    provider
      ..configure(enabled: true, seconds: 10)
      ..setViewing(viewing: true)
      ..setForeground(foreground: false);
    expect(provider.isRunning, isFalse);
    expect(active(), isNull);

    provider.setForeground(foreground: true);
    expect(provider.isRunning, isTrue);
    expect(active(), isNotNull);
  });

  test('stops when the person leaves the cycling screens', () {
    provider
      ..configure(enabled: true, seconds: 10)
      ..setViewing(viewing: true)
      ..setViewing(viewing: false);
    expect(provider.isRunning, isFalse);
    expect(active(), isNull);
  });

  test('turning it off in settings stops the timer', () {
    provider
      ..configure(enabled: true, seconds: 10)
      ..setViewing(viewing: true)
      ..configure(enabled: false, seconds: 10);
    expect(provider.isRunning, isFalse);
    expect(active(), isNull);
  });

  test('an unsupported interval uses the default', () {
    provider
      ..configure(enabled: true, seconds: 3)
      ..setViewing(viewing: true);
    expect(active()?.delay, const Duration(seconds: 10));
  });

  test('the layout interval overrides the global one', () {
    const AppSettings settings = AppSettings(autoCycleSeconds: 30);
    final GridLayout plain = GridLayout.forPageSize(id: 'a', pageSize: 4);

    expect(AutoCycleProvider.effectiveSeconds(settings, plain), 30);
    expect(
      AutoCycleProvider.effectiveSeconds(settings, plain.copyWith(autoCycleSeconds: 5)),
      5,
    );
  });

  test('a timer that fires after dispose does nothing', () {
    provider
      ..configure(enabled: true, seconds: 10)
      ..setViewing(viewing: true);
    final _ManualTimer timer = active()!;
    provider.dispose();
    timer.fire();
    provider = AutoCycleProvider();
  });
}
