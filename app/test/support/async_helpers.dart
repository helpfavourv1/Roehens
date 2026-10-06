import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Polls [condition] until it holds, or fails the test after [timeout].
Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String reason = 'condition not met in time',
}) async {
  final Stopwatch clock = Stopwatch()..start();
  while (!condition()) {
    if (clock.elapsed > timeout) {
      fail(reason);
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
