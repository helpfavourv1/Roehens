/// Source of the current time, replaceable in tests.
abstract interface class ClockContract {
  DateTime now();
}

/// The real clock.
class SystemClock implements ClockContract {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
