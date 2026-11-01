import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/constants/languages.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/onboarding_state.dart';
import 'package:roehens/core/providers/locale_provider.dart';
import 'package:roehens/core/providers/onboarding_provider.dart';
import 'package:roehens/core/providers/settings_provider.dart';
import 'package:roehens/core/providers/theme_provider.dart';

import '../../support/fakes.dart';

void main() {
  late FakeKeyValueStore store;
  late SettingsProvider settings;

  setUp(() {
    store = FakeKeyValueStore();
    settings = SettingsProvider(store: store, logger: FakeLogger());
  });

  tearDown(() => settings.dispose());

  group('SettingsProvider', () {
    test('starts with defaults when nothing is saved', () async {
      await settings.load();
      expect(settings.value, const AppSettings());
    });

    test('saves every change and reads it back after a restart', () async {
      await settings.setThemeMode(AppThemeMode.light);
      await settings.setHaptics(enabled: false);

      final SettingsProvider restarted =
          SettingsProvider(store: store, logger: FakeLogger());
      await restarted.load();

      expect(restarted.value.themeMode, AppThemeMode.light);
      expect(restarted.value.hapticsEnabled, isFalse);
      restarted.dispose();
    });

    test('an unreadable file gives defaults', () async {
      store.values[StorageKeys.settings] = '{{{ not json';
      await settings.load();
      expect(settings.value, const AppSettings());

      store.values[StorageKeys.settings] = jsonEncode(<String, Object?>{
        'themeMode': 'sepia',
      });
      await settings.load();
      expect(settings.value, const AppSettings());
    });

    test('an unsupported auto-cycle interval falls back to the default', () async {
      await settings.setAutoCycle(enabled: true, seconds: 7);
      expect(settings.value.autoCycleSeconds, Limits.defaultAutoCycleSeconds);

      await settings.setAutoCycle(enabled: true, seconds: 30);
      expect(settings.value.autoCycleSeconds, 30);
    });

    test('a null language follows the system', () async {
      await settings.setLocaleCode('fr');
      expect(settings.value.localeCode, 'fr');
      await settings.setLocaleCode(null);
      expect(settings.value.localeCode, isNull);
    });

    test('reset returns to defaults and clears the saved file', () async {
      await settings.setKeepAwake(enabled: false);
      await settings.reset();
      expect(settings.value, const AppSettings());
      expect(store.values.containsKey(StorageKeys.settings), isFalse);
    });

    test('a late save after dispose does not throw', () async {
      final SettingsProvider short =
          SettingsProvider(store: store, logger: FakeLogger());
      final Future<void> pending = short.setThemeMode(AppThemeMode.dark);
      short.dispose();
      await pending;
    });
  });

  group('ThemeProvider', () {
    test('follows the settings in both directions', () async {
      final ThemeProvider theme = ThemeProvider(settings: settings);
      expect(theme.value, AppThemeMode.system);

      await theme.setMode(AppThemeMode.dark);
      expect(theme.value, AppThemeMode.dark);
      expect(settings.value.themeMode, AppThemeMode.dark);

      await settings.setThemeMode(AppThemeMode.light);
      expect(theme.value, AppThemeMode.light);
      theme.dispose();
    });
  });

  group('LocaleProvider', () {
    test('maps codes with scripts and regions to locales', () async {
      final LocaleProvider locale = LocaleProvider(settings: settings);
      expect(locale.value, isNull);

      await locale.setLanguage('zh_Hans');
      expect(locale.value, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      await locale.setLanguage('es_419');
      expect(locale.value, const Locale('es', '419'));
      await locale.setLanguage('pt_BR');
      expect(locale.value, const Locale('pt', 'BR'));
      await locale.setLanguage('fil');
      expect(locale.value, const Locale('fil'));
      locale.dispose();
    });

    test('an unsupported code means the system language', () async {
      final LocaleProvider locale = LocaleProvider(settings: settings);
      await locale.setLanguage('en');
      await locale.setLanguage('klingon');
      expect(locale.value, isNull);
      expect(settings.value.localeCode, isNull);
      locale.dispose();
    });

    test('the language list matches the specification', () {
      expect(appLanguages, hasLength(24));
      expect(appLanguages.map((AppLanguage l) => l.code).toSet(), hasLength(24));
      expect(
        appLanguages.where((AppLanguage l) => l.isRtl).map((AppLanguage l) => l.code),
        <String>['ar', 'ur', 'fa', 'he'],
      );
      for (final AppLanguage language in appLanguages) {
        expect(language.locale, isNotNull);
      }
    });
  });

  group('OnboardingProvider', () {
    test('a first run needs onboarding and finishing it is remembered', () async {
      final OnboardingProvider onboarding = OnboardingProvider(store: store);
      expect(onboarding.isLoaded, isFalse);
      await onboarding.load();
      expect(onboarding.isLoaded, isTrue);
      expect(onboarding.needsOnboarding, isTrue);

      await onboarding.markLocalNetworkRationaleSeen();
      await onboarding.complete();

      final OnboardingProvider restarted = OnboardingProvider(store: store);
      await restarted.load();
      expect(restarted.needsOnboarding, isFalse);
      expect(restarted.value.localNetworkRationaleSeen, isTrue);
      onboarding.dispose();
      restarted.dispose();
    });

    test('an older completed version shows onboarding again', () async {
      store.values[StorageKeys.onboarding] = jsonEncode(
        const OnboardingState(completedVersion: AppConstants.onboardingVersion - 1)
            .toJson(),
      );
      final OnboardingProvider onboarding = OnboardingProvider(store: store);
      await onboarding.load();
      expect(onboarding.needsOnboarding, isTrue);
      onboarding.dispose();
    });

    test('an unreadable file runs onboarding again', () async {
      store.values[StorageKeys.onboarding] = 'garbage';
      final OnboardingProvider onboarding = OnboardingProvider(store: store);
      await onboarding.load();
      expect(onboarding.needsOnboarding, isTrue);
      expect(onboarding.isLoaded, isTrue);
      onboarding.dispose();
    });
  });
}
