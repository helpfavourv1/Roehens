import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/providers/help_provider.dart';
import 'package:roehens/core/services/help_catalog.dart';

import '../../support/fakes.dart';

void main() {
  final String structure = File('assets/help/help_structure.json')
      .readAsStringSync();
  final String english = File('assets/help/strings/help_en.json')
      .readAsStringSync();
  late Map<String, String> files;
  late List<String> loaded;
  late HelpProvider provider;

  setUp(() {
    loaded = <String>[];
    files = <String, String>{
      HelpProvider.structurePath: structure,
      HelpProvider.filePath('en'): english,
    };
    provider = HelpProvider(
      loader: (String path) async {
        loaded.add(path);
        final String? text = files[path];
        if (text == null) {
          throw StateError('no asset $path');
        }
        return text;
      },
      logger: FakeLogger(),
    );
  });

  tearDown(() => provider.dispose());

  test('tags match the ARB suffixes', () {
    expect(HelpProvider.tagFor(const Locale('fr')), 'fr');
    expect(HelpProvider.tagFor(const Locale('pt', 'BR')), 'pt_BR');
    expect(HelpProvider.tagFor(const Locale('es', '419')), 'es_419');
    expect(
      HelpProvider.tagFor(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      'zh_Hans',
    );
  });

  test('English loads the structure and the text', () async {
    await provider.load();
    expect(provider.value.isReady, isTrue);
    expect(provider.value.strings!.text(HelpCatalog.titleKey('vpn')), 'VPN');
  });

  test('a language without a file shows English', () async {
    await provider.load(languageTag: 'fr');
    expect(provider.value.isReady, isTrue);
    expect(provider.value.strings!.text(HelpCatalog.titleKey('vpn')), 'VPN');
    expect(
      provider.value.strings!.isFallback(HelpCatalog.titleKey('vpn')),
      isTrue,
    );
  });

  test('a language file wins, and missing keys fall back', () async {
    files[HelpProvider.filePath('fr')] = '{"article.vpn.title": "RPV"}';
    await provider.load(languageTag: 'fr');
    final HelpStrings s = provider.value.strings!;
    expect(s.text(HelpCatalog.titleKey('vpn')), 'RPV');
    expect(s.text(HelpCatalog.titleKey('relay')), 'Third-party relay');
  });

  test(
    'the structure is read once and the same language twice does nothing',
    () async {
      await provider.load();
      await provider.load();
      await provider.load(languageTag: 'fr');
      expect(
        loaded.where((String p) => p == HelpProvider.structurePath).length,
        1,
      );
      expect(
        loaded.where((String p) => p == HelpProvider.filePath('en')).length,
        1,
      );
    },
  );

  test('a broken structure is reported, not shown', () async {
    files[HelpProvider.structurePath] = '{"articles": []}';
    await provider.load();
    expect(provider.value.isReady, isFalse);
    expect(provider.value.error!.errorClass, ErrorClass.invalidFile);
  });

  test(
    'a missing structure leaves the content unready without throwing',
    () async {
      files.remove(HelpProvider.structurePath);
      await provider.load();
      expect(provider.value.isReady, isFalse);
    },
  );
}
