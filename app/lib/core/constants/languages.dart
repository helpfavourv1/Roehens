import 'dart:ui';

/// One of the 24 launch languages (D14).
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    this.isRtl = false,
  });

  /// The ARB suffix: `en`, `zh_Hans`, `es_419`, `pt_BR`, `fil`.
  final String code;

  /// The language's own name, which is never translated.
  final String nativeName;
  final bool isRtl;

  Locale get locale => localeFromCode(code)!;
}

/// The launch languages in the order of the specification.
const List<AppLanguage> appLanguages = <AppLanguage>[
  AppLanguage(code: 'en', nativeName: 'English'),
  AppLanguage(code: 'zh_Hans', nativeName: '简体中文'),
  AppLanguage(code: 'es_419', nativeName: 'Español (Latinoamérica)'),
  AppLanguage(code: 'ar', nativeName: 'العربية', isRtl: true),
  AppLanguage(code: 'fr', nativeName: 'Français'),
  AppLanguage(code: 'pt_BR', nativeName: 'Português (Brasil)'),
  AppLanguage(code: 'ru', nativeName: 'Русский'),
  AppLanguage(code: 'hi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা'),
  AppLanguage(code: 'ja', nativeName: '日本語'),
  AppLanguage(code: 'de', nativeName: 'Deutsch'),
  AppLanguage(code: 'ur', nativeName: 'اردو', isRtl: true),
  AppLanguage(code: 'id', nativeName: 'Bahasa Indonesia'),
  AppLanguage(code: 'vi', nativeName: 'Tiếng Việt'),
  AppLanguage(code: 'tr', nativeName: 'Türkçe'),
  AppLanguage(code: 'fa', nativeName: 'فارسی', isRtl: true),
  AppLanguage(code: 'it', nativeName: 'Italiano'),
  AppLanguage(code: 'ko', nativeName: '한국어'),
  AppLanguage(code: 'th', nativeName: 'ไทย'),
  AppLanguage(code: 'pl', nativeName: 'Polski'),
  AppLanguage(code: 'uk', nativeName: 'Українська'),
  AppLanguage(code: 'nl', nativeName: 'Nederlands'),
  AppLanguage(code: 'he', nativeName: 'עברית', isRtl: true),
  AppLanguage(code: 'fil', nativeName: 'Filipino'),
];

/// The locale for a language code such as `zh_Hans`, `es_419` or `pt_BR`.
/// Null for a missing or unsupported code.
Locale? localeFromCode(String? code) {
  if (code == null || !appLanguages.any((AppLanguage l) => l.code == code)) {
    return null;
  }
  final List<String> parts = code.split('_');
  if (parts.length == 1) {
    return Locale(parts.first);
  }
  final String second = parts[1];
  if (second.length == 4) {
    return Locale.fromSubtags(languageCode: parts.first, scriptCode: second);
  }
  return Locale(parts.first, second);
}
