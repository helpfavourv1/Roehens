import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/stream_protocol.dart';

void main() {
  test('defaults follow the specification', () {
    const AppSettings s = AppSettings();
    expect(s.themeMode, AppThemeMode.system);
    expect(s.localeCode, isNull);
    expect(s.defaultTransport, StreamTransport.auto);
    expect(s.gridSubstreamDefault, isTrue);
    expect(s.keepAwake, isTrue);
    expect(s.autoCycleEnabled, isFalse);
    expect(s.autoCycleSeconds, 10);
  });

  test('survives a JSON round trip', () {
    const AppSettings s = AppSettings(
      themeMode: AppThemeMode.dark,
      localeCode: 'ar',
      defaultTransport: StreamTransport.udp,
      gridSubstreamDefault: false,
      keepAwake: false,
      showOverlayLabels: false,
      hapticsEnabled: false,
      autoCycleEnabled: true,
      autoCycleSeconds: 30,
    );
    final AppSettings back = AppSettings.fromJson(
      jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
    );
    expect(back, s);
    expect(back.hashCode, s.hashCode);
  });

  test('missing keys fall back to defaults and unknown keys are ignored', () {
    final AppSettings s = AppSettings.fromJson(<String, Object?>{
      'themeMode': 'light',
      'someFutureKey': 123,
    });
    expect(s.themeMode, AppThemeMode.light);
    expect(s.keepAwake, isTrue);
    expect(s.autoCycleSeconds, 10);
  });

  test('copyWith can clear the language back to the system language', () {
    const AppSettings s = AppSettings(localeCode: 'fr');
    expect(s.copyWith(themeMode: AppThemeMode.dark).localeCode, 'fr');
    expect(s.copyWith(localeCode: null).localeCode, isNull);
  });
}
