import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';

/// Local ring-buffer log. Nothing is written to disk or uploaded; the person can
/// attach the buffer to a feedback mail. Credentials embedded in URLs are
/// masked before a message is stored.
class LoggerService implements LoggerContract {
  LoggerService({
    this._clock = const SystemClock(),
    this._capacity = Limits.logRingSize,
  });

  final ClockContract _clock;
  final int _capacity;
  final ListQueue<LogEntry> _buffer = ListQueue<LogEntry>();

  static final RegExp _urlCredentials = RegExp(r'([A-Za-z][A-Za-z0-9+.-]*://)[^/@\s]+:[^/@\s]+@');

  /// Masks `user:password@` in any URL inside [text].
  static String redact(String text) {
    return text.replaceAllMapped(
      _urlCredentials,
      (Match m) => '${m.group(1)}***@',
    );
  }

  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final StringBuffer text = StringBuffer(message);
    if (error != null) {
      text.write(' | error: $error');
    }
    if (stackTrace != null) {
      text.write(' | ${stackTrace.toString().split('\n').take(4).join(' / ')}');
    }
    final LogEntry entry = LogEntry(
      time: _clock.now(),
      level: level,
      tag: tag,
      message: redact(text.toString()),
    );
    _buffer.addLast(entry);
    while (_buffer.length > _capacity) {
      _buffer.removeFirst();
    }
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  @override
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_buffer);

  @override
  String dump() => _buffer.map((LogEntry e) => e.toString()).join('\n');

  @override
  void clear() => _buffer.clear();
}
