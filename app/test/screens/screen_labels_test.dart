import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/utils/date_formatter.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('every error class has its own sentence, never the fatal fallback', () {
    final String fatal = l10n.errorFatal;
    for (final ErrorClass c in ErrorClass.values) {
      final String text = errorMessage(l10n, AppError(c));
      expect(text, isNotEmpty, reason: '$c');
      if (c != ErrorClass.fatal) {
        expect(
          text,
          isNot(fatal),
          reason: '$c has a message key the labels do not know',
        );
      }
    }
  });

  test('every status and protocol has a label', () {
    for (final StreamStatus s in StreamStatus.values) {
      expect(streamStatusLabel(l10n, s), isNotEmpty);
    }
    for (final StreamProtocol p in StreamProtocol.values) {
      expect(protocolLabel(l10n, p), isNotEmpty);
    }
  });

  test('ages use the right plural', () {
    expect(ageLabel(l10n, const AgeSpan(AgeUnit.seconds, 1)), '1 second ago');
    expect(ageLabel(l10n, const AgeSpan(AgeUnit.minutes, 5)), '5 minutes ago');
    expect(ageLabel(l10n, const AgeSpan(AgeUnit.days, 2)), '2 days ago');
  });

  test('an address is host and port', () {
    expect(cameraAddress('10.0.0.1', 554), '10.0.0.1:554');
  });
}
