/// Unit of an [AgeSpan].
enum AgeUnit { seconds, minutes, hours, days }

/// How long ago something happened, as a number and a unit. The widget layer
/// turns it into a localized phrase with plural rules, so no English text lives
/// here.
class AgeSpan {
  const AgeSpan(this.unit, this.value);

  final AgeUnit unit;
  final int value;

  @override
  bool operator ==(Object other) {
    return other is AgeSpan && other.unit == unit && other.value == value;
  }

  @override
  int get hashCode => Object.hash(unit, value);

  @override
  String toString() => 'AgeSpan($value $unit)';
}

/// Locale-independent date and time formatting for technical values
/// (timestamps on tiles and event rows always use Western digits).
class DateFormatter {
  DateFormatter._();

  /// Age of [then] relative to [now]; never negative.
  static AgeSpan age(DateTime then, DateTime now) {
    final int seconds = now.difference(then).inSeconds;
    if (seconds < 60) {
      return AgeSpan(AgeUnit.seconds, seconds < 0 ? 0 : seconds);
    }
    if (seconds < 3600) {
      return AgeSpan(AgeUnit.minutes, seconds ~/ 60);
    }
    if (seconds < 86400) {
      return AgeSpan(AgeUnit.hours, seconds ~/ 3600);
    }
    return AgeSpan(AgeUnit.days, seconds ~/ 86400);
  }

  /// `HH:mm:ss`, 24-hour.
  static String clock(DateTime time) {
    return '${_two(time.hour)}:${_two(time.minute)}:${_two(time.second)}';
  }

  /// `yyyy-MM-dd`.
  static String isoDate(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-${_two(time.month)}-'
        '${_two(time.day)}';
  }

  /// `yyyy-MM-dd HH:mm:ss`.
  static String dateTime(DateTime time) => '${isoDate(time)} ${clock(time)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
