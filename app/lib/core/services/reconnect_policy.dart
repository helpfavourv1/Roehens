import 'dart:math';

import 'package:roehens/core/constants/limits.dart';

/// Reconnect schedule for one stream (specification D3): exponential backoff of
/// 1 s, 2 s, 4 s, 8 s and then 15 s, each with up to 20% random jitter, reset
/// after 30 s of healthy playback, and a stop after 10 attempts so the tile
/// shows a manual Retry instead of retrying forever.
///
/// The policy only decides delays. The caller pauses it while the app is in the
/// background and calls [reset] when the person taps Retry.
class ReconnectPolicy {
  ReconnectPolicy({
    this.backoff = Limits.reconnectBackoff,
    this.jitter = Limits.reconnectJitter,
    this.healthyReset = Limits.reconnectHealthyReset,
    this.maxAttempts = Limits.reconnectMaxAttempts,
    Random? random,
  }) : _random = random ?? Random();

  final List<Duration> backoff;

  /// Fraction of random variation applied to each delay: 0.2 means +-20%.
  final double jitter;

  /// Healthy playback of at least this long forgives earlier failures.
  final Duration healthyReset;

  final int maxAttempts;
  final Random _random;
  int _attempts = 0;

  /// Reconnects scheduled since the last reset.
  int get attempts => _attempts;

  /// True once [maxAttempts] reconnects were scheduled without a healthy spell.
  bool get exhausted => _attempts >= maxAttempts;

  /// Delay before the next reconnect, or null when the policy gave up.
  Duration? nextDelay() {
    if (exhausted) {
      return null;
    }
    _attempts++;
    final Duration base = backoff[min(_attempts - 1, backoff.length - 1)];
    if (jitter <= 0) {
      return base;
    }
    final double factor = 1 + (_random.nextDouble() * 2 - 1) * jitter;
    return Duration(microseconds: (base.inMicroseconds * factor).round());
  }

  /// Reports how long the stream played before it dropped again.
  void onHealthyPlayback(Duration playedFor) {
    if (playedFor >= healthyReset) {
      _attempts = 0;
    }
  }

  void reset() {
    _attempts = 0;
  }
}
