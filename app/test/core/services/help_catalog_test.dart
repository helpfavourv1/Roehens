import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';
import 'package:roehens/core/services/help_catalog.dart';

HelpCatalog loadReal() {
  final String source = File('assets/help/help_structure.json')
      .readAsStringSync();
  return HelpCatalog.parse(source).valueOrNull!;
}

Map<String, String> english() {
  return HelpStrings.parseFile(
    File('assets/help/strings/help_en.json').readAsStringSync(),
  );
}

void main() {
  test('the bundled structure is sound', () {
    final HelpCatalog catalog = loadReal();
    expect(catalog.problems(), isEmpty);
    expect(catalog.articles.length, 10);
    expect(catalog.wizardPaths.map((WizardPath p) => p.id), <String>[
      'vpn',
      'ddns_forward',
      'static_ip_forward',
      'relay',
    ]);
  });

  test('the ten articles are the ones the specification names', () {
    expect(loadReal().articles.map((HelpArticle a) => a.id).toSet(), <String>{
      'lan_setup',
      'vpn',
      'ddns_forward',
      'static_ip_forward',
      'relay',
      'cgnat',
      'port_selection',
      'port_security',
      'codecs_bandwidth',
      'router_notes',
    });
  });

  test('every hub group has articles', () {
    final HelpCatalog catalog = loadReal();
    expect(catalog.inGroup(HelpGroup.sameWifi), isNotEmpty);
    expect(catalog.inGroup(HelpGroup.away), isNotEmpty);
  });

  test('English has every key the structure needs, and nothing unused', () {
    final HelpCatalog catalog = loadReal();
    final Set<String> have = english().keys.toSet();
    final Set<String> need = catalog.requiredKeys;
    expect(need.difference(have), isEmpty, reason: 'missing English text');
    expect(have.difference(need), isEmpty, reason: 'text nothing uses');
    for (final MapEntry<String, String> e in english().entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
    }
  });

  test('Help has no outbound web links, in structure or text', () {
    final String structure = File('assets/help/help_structure.json')
        .readAsStringSync();
    final RegExp link = RegExp(
      r'https?://|www\.|mailto:',
      caseSensitive: false,
    );
    expect(link.hasMatch(structure), isFalse);
    for (final MapEntry<String, String> e in english().entries) {
      expect(link.hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test('copyable values are technical values, kept as written', () {
    final HelpCatalog catalog = loadReal();
    final HelpStep step = catalog
        .article('lan_setup')!
        .steps
        .firstWhere((HelpStep s) => s.id == 'enable');
    expect(step.copyValues.map((HelpCopyValue c) => c.value), contains('554'));
  });

  test('targets are in-app places or the phone settings', () {
    expect(HelpTarget.parse('add_camera')!.kind, HelpTargetKind.addCamera);
    expect(
      HelpTarget.parse('phone_settings')!.kind,
      HelpTargetKind.phoneSettings,
    );
    expect(HelpTarget.parse('article:vpn')!.articleId, 'vpn');
    expect(HelpTarget.parse('https://example.com'), isNull);
    expect(HelpTarget.parse('article:'), isNull);
    expect(HelpTarget.parse(null), isNull);
  });

  Map<String, Object?> structure() {
    return jsonDecode(
      File('assets/help/help_structure.json').readAsStringSync(),
    ) as Map<String, Object?>;
  }

  test('a broken edge rejects the whole structure', () {
    final Map<String, Object?> s = structure();
    final List<Object?> nodes =
        (s['troubleshooter']! as Map<String, Object?>)['nodes']!
            as List<Object?>;
    final Map<String, Object?> first = nodes.first! as Map<String, Object?>;
    ((first['edges']! as List<Object?>).first! as Map<String, Object?>)['to'] =
        'nowhere';
    final result = HelpCatalog.parse(jsonEncode(s));
    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.errorClass, ErrorClass.invalidFile);
  });

  test('an unknown target, a missing article or a missing wizard article is rejected', () {
    Map<String, Object?> s = structure();
    final Map<String, Object?> node =
        ((s['troubleshooter']! as Map<String, Object?>)['nodes']!
                    as List<Object?>)
                .firstWhere(
                  (Object? n) =>
                      (n! as Map<String, Object?>)['outcome'] != null,
                )!
            as Map<String, Object?>;
    (node['outcome']! as Map<String, Object?>)['targets'] = <String>[
      'https://x',
    ];
    expect(HelpCatalog.parse(jsonEncode(s)).isErr, isTrue);

    s = structure();
    ((s['wizard']! as List<Object?>).first!
            as Map<String, Object?>)['article'] =
        'gone';
    expect(HelpCatalog.parse(jsonEncode(s)).isErr, isTrue);

    expect(HelpCatalog.parse('not json').isErr, isTrue);
    expect(HelpCatalog.parse('[]').isErr, isTrue);
  });

  test('strings fall back to English, never to a key', () {
    const HelpStrings strings = HelpStrings(
      primary: <String, String>{'a': 'Hola'},
      fallback: <String, String>{'a': 'Hello', 'b': 'World'},
    );
    expect(strings.text('a'), 'Hola');
    expect(strings.text('b'), 'World');
    expect(strings.isFallback('b'), isTrue);
    expect(strings.text('zzz'), '');
  });
}
