import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/utils/async_utils.dart';
import 'package:roehens/utils/date_formatter.dart';
import 'package:roehens/utils/number_formatter.dart';

void main() {
  group('DateFormatter.age', () {
    final DateTime now = DateTime.utc(2026, 10, 31, 12);

    test('uses the largest whole unit', () {
      expect(DateFormatter.age(now.subtract(const Duration(seconds: 5)), now), const AgeSpan(AgeUnit.seconds, 5));
      expect(DateFormatter.age(now.subtract(const Duration(seconds: 59)), now), const AgeSpan(AgeUnit.seconds, 59));
      expect(DateFormatter.age(now.subtract(const Duration(seconds: 60)), now), const AgeSpan(AgeUnit.minutes, 1));
      expect(DateFormatter.age(now.subtract(const Duration(minutes: 59, seconds: 59)), now), const AgeSpan(AgeUnit.minutes, 59));
      expect(DateFormatter.age(now.subtract(const Duration(hours: 1)), now), const AgeSpan(AgeUnit.hours, 1));
      expect(DateFormatter.age(now.subtract(const Duration(hours: 23, minutes: 59)), now), const AgeSpan(AgeUnit.hours, 23));
      expect(DateFormatter.age(now.subtract(const Duration(days: 1)), now), const AgeSpan(AgeUnit.days, 1));
      expect(DateFormatter.age(now.subtract(const Duration(days: 40)), now), const AgeSpan(AgeUnit.days, 40));
    });

    test('a time in the future is zero seconds, never negative', () {
      expect(DateFormatter.age(now.add(const Duration(minutes: 5)), now), const AgeSpan(AgeUnit.seconds, 0));
    });

    test('spans compare by value and print readably', () {
      expect(const AgeSpan(AgeUnit.hours, 2), const AgeSpan(AgeUnit.hours, 2));
      expect(const AgeSpan(AgeUnit.hours, 2).hashCode, const AgeSpan(AgeUnit.hours, 2).hashCode);
      expect(const AgeSpan(AgeUnit.hours, 2), isNot(const AgeSpan(AgeUnit.days, 2)));
      expect(const AgeSpan(AgeUnit.hours, 2).toString(), contains('2'));
    });
  });

  group('DateFormatter text', () {
    test('clock, date and date-time use Western digits and fixed widths', () {
      final DateTime t = DateTime(2026, 1, 5, 7, 3, 9);
      expect(DateFormatter.clock(t), '07:03:09');
      expect(DateFormatter.isoDate(t), '2026-01-05');
      expect(DateFormatter.dateTime(t), '2026-01-05 07:03:09');
    });

    test('a year below 1000 is padded to four digits', () {
      expect(DateFormatter.isoDate(DateTime(987, 12, 31)), '0987-12-31');
    });
  });

  group('NumberFormatter', () {
    test('bitrate', () {
      expect(NumberFormatter.bitrate(0), '0 kbps');
      expect(NumberFormatter.bitrate(850000), '850 kbps');
      expect(NumberFormatter.bitrate(999999), '1000 kbps');
      expect(NumberFormatter.bitrate(1000000), '1 Mbps');
      expect(NumberFormatter.bitrate(2500000), '2.5 Mbps');
      expect(NumberFormatter.bitrate(12000000), '12 Mbps');
      expect(NumberFormatter.bitrate(-5), '0 kbps');
    });

    test('resolution uses the multiplication sign', () {
      expect(NumberFormatter.resolution(1920, 1080), '1920\u00D71080');
    });

    test('frame rate rounds to whole frames', () {
      expect(NumberFormatter.frameRate(25), '25 fps');
      expect(NumberFormatter.frameRate(29.97), '30 fps');
      expect(NumberFormatter.frameRate(-1), '0 fps');
    });

    test('bytes use decimal units like the storage tables', () {
      expect(NumberFormatter.bytes(0), '0 B');
      expect(NumberFormatter.bytes(512), '512 B');
      expect(NumberFormatter.bytes(1500), '1.5 KB');
      expect(NumberFormatter.bytes(1000), '1 KB');
      expect(NumberFormatter.bytes(38000000), '38 MB');
      expect(NumberFormatter.bytes(3600000000), '3.6 GB');
      expect(NumberFormatter.bytes(-9), '0 B');
    });
  });

  group('Debouncer', () {
    test('runs only the last action after the delay', () async {
      final List<int> ran = <int>[];
      final Debouncer debouncer = Debouncer(const Duration(milliseconds: 30));
      debouncer.run(() => ran.add(1));
      debouncer.run(() => ran.add(2));
      debouncer.run(() => ran.add(3));
      expect(ran, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(ran, <int>[3]);
    });

    test('cancel and dispose drop a pending action', () async {
      final List<int> ran = <int>[];
      final Debouncer debouncer = Debouncer(const Duration(milliseconds: 20));
      debouncer.run(() => ran.add(1));
      debouncer.cancel();
      debouncer.run(() => ran.add(2));
      debouncer.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(ran, isEmpty);
    });
  });

  group('timeouts', () {
    test('withTimeout gives the value in time and the fallback otherwise', () async {
      expect(await withTimeout<int>(Future<int>.value(1), const Duration(milliseconds: 50), onTimeout: () => -1), 1);
      final Completer<int> never = Completer<int>();
      expect(await withTimeout<int>(never.future, const Duration(milliseconds: 20), onTimeout: () => -1), -1);
    });

    test('timeoutOrNull gives null when the limit passes', () async {
      expect(await timeoutOrNull<int>(Future<int>.value(7), const Duration(milliseconds: 50)), 7);
      final Completer<int> never = Completer<int>();
      expect(await timeoutOrNull<int>(never.future, const Duration(milliseconds: 20)), isNull);
    });
  });
}
