import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/platform/system/logger_service.dart';

import '../../support/fakes.dart';

void main() {
  test('credentials inside URLs are masked', () {
    final LoggerService logger = LoggerService(clock: FakeClock());
    logger.info('player', 'opening rtsp://admin:hunter22@10.0.0.5/stream0 now');
    final String text = logger.dump();
    expect(text.contains('hunter22'), isFalse);
    expect(text.contains('admin'), isFalse);
    expect(text, contains('rtsp://***@10.0.0.5/stream0'));
  });

  test('the buffer keeps only the newest entries', () {
    final LoggerService logger = LoggerService(clock: FakeClock(), capacity: 3);
    for (int i = 0; i < 5; i++) {
      logger.info('t', 'message $i');
    }
    expect(logger.entries.length, 3);
    expect(logger.entries.first.message, 'message 2');
    expect(logger.entries.last.message, 'message 4');
  });

  test('errors and levels are recorded and the buffer can be cleared', () {
    final LoggerService logger = LoggerService(clock: FakeClock());
    logger.error('db', 'failed', error: StateError('boom'));
    expect(logger.entries.single.level, LogLevel.error);
    expect(logger.entries.single.message, contains('boom'));
    logger.clear();
    expect(logger.entries, isEmpty);
  });
}
