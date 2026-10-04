enum LogLevel { debug, info, warning, error }

class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  @override
  String toString() => '${time.toIso8601String()} ${level.name} [$tag] $message';
}

/// Local-only log kept in a ring buffer. Nothing is uploaded; the person can
/// attach it to a feedback mail. Messages must never contain credentials.
abstract interface class LoggerContract {
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Oldest first.
  List<LogEntry> get entries;

  /// The whole buffer as text, for the feedback attachment.
  String dump();

  void clear();
}

extension LoggerShortcuts on LoggerContract {
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);

  void info(String tag, String message) => log(LogLevel.info, tag, message);

  void warning(String tag, String message, {Object? error}) {
    log(LogLevel.warning, tag, message, error: error);
  }

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }
}
