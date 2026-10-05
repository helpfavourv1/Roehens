import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/reconnect_policy.dart';

void main() {
  test('delays follow 1, 2, 4, 8, then 15 seconds', () {
    final ReconnectPolicy policy = ReconnectPolicy(jitter: 0);
    final List<int> seconds = <int>[
      for (int i = 0; i < 10; i++) policy.nextDelay()!.inSeconds,
    ];
    expect(seconds, <int>[1, 2, 4, 8, 15, 15, 15, 15, 15, 15]);
  });

  test('it gives up after ten attempts', () {
    final ReconnectPolicy policy = ReconnectPolicy(jitter: 0);
    for (int i = 0; i < 10; i++) {
      expect(policy.exhausted, isFalse);
      expect(policy.nextDelay(), isNotNull);
    }
    expect(policy.exhausted, isTrue);
    expect(policy.nextDelay(), isNull);
    expect(policy.attempts, 10);
  });

  test('jitter stays within 20 percent of the base delay', () {
    final Random random = Random(42);
    for (int run = 0; run < 200; run++) {
      final ReconnectPolicy policy = ReconnectPolicy(random: random);
      final Duration first = policy.nextDelay()!;
      expect(first.inMilliseconds, inInclusiveRange(800, 1200));
      policy.nextDelay();
      policy.nextDelay();
      policy.nextDelay();
      final Duration fifth = policy.nextDelay()!;
      expect(fifth.inMilliseconds, inInclusiveRange(12000, 18000));
    }
  });

  test('jitter actually varies the delay', () {
    final Random random = Random(1);
    final Set<int> seen = <int>{};
    for (int i = 0; i < 20; i++) {
      seen.add(ReconnectPolicy(random: random).nextDelay()!.inMilliseconds);
    }
    expect(seen.length, greaterThan(10));
  });

  test('thirty seconds of healthy playback forgives earlier failures', () {
    final ReconnectPolicy policy = ReconnectPolicy(jitter: 0);
    policy.nextDelay();
    policy.nextDelay();
    policy.nextDelay();
    expect(policy.attempts, 3);

    policy.onHealthyPlayback(const Duration(seconds: 29));
    expect(policy.attempts, 3);

    policy.onHealthyPlayback(const Duration(seconds: 30));
    expect(policy.attempts, 0);
    expect(policy.nextDelay(), const Duration(seconds: 1));
  });

  test('a manual retry starts the schedule again', () {
    final ReconnectPolicy policy = ReconnectPolicy(jitter: 0);
    for (int i = 0; i < 10; i++) {
      policy.nextDelay();
    }
    expect(policy.exhausted, isTrue);
    policy.reset();
    expect(policy.exhausted, isFalse);
    expect(policy.nextDelay(), const Duration(seconds: 1));
  });
}
