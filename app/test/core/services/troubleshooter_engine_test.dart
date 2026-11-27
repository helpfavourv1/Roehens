import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/core/services/troubleshooter_engine.dart';

void main() {
  final HelpCatalog catalog = HelpCatalog.parse(
    File('assets/help/help_structure.json').readAsStringSync(),
  ).valueOrNull!;
  final TroubleshooterEngine engine = TroubleshooterEngine(catalog);

  test('it starts on the first question and cannot go back', () {
    final TroubleshootSession s = engine.start();
    expect(s.currentId, 'wifi_works');
    expect(s.canGoBack, isFalse);
    expect(engine.back(s).currentId, 'wifi_works');
  });

  test('works at home but not away leads to the CGNAT advice', () {
    TroubleshootSession s = engine.start();
    s = engine.answer(s, 'yes'); // works at home
    s = engine.answer(s, 'yes'); // fails only away
    s = engine.answer(s, 'no'); // no VPN
    s = engine.answer(s, 'different'); // router address differs
    final TroubleshootNode end = engine.current(s);
    expect(end.isOutcome, isTrue);
    expect(end.outcome!.articleIds, containsAll(<String>['cgnat', 'vpn']));
  });

  test('not working at home leads to the setup advice', () {
    TroubleshootSession s = engine.start();
    s = engine.answer(s, 'no');
    s = engine.answer(s, 'unreachable');
    expect(engine.current(s).outcome!.articleIds, contains('lan_setup'));
  });

  test('back steps one question and restart returns to the first', () {
    TroubleshootSession s = engine.start();
    s = engine.answer(s, 'no');
    expect(s.canGoBack, isTrue);
    s = engine.back(s);
    expect(s.currentId, 'wifi_works');
    s = engine.answer(engine.answer(s, 'no'), 'auth');
    expect(engine.restart(s).currentId, 'wifi_works');
  });

  test('an answer the question does not offer changes nothing', () {
    final TroubleshootSession s = engine.start();
    expect(engine.answer(s, 'maybe').currentId, 'wifi_works');
  });

  test('every path ends in an outcome, with no loops and no dead ends', () {
    int outcomes = 0;
    void walk(TroubleshootSession s, Set<String> seen) {
      final String id = s.currentId;
      expect(seen.contains(id), isFalse, reason: 'loop at $id');
      final TroubleshootNode node = engine.current(s);
      if (node.isOutcome) {
        outcomes++;
        // Every end has text in the language files (checked by the catalog
        // test); here it is enough that it is a real end.
        expect(node.edges, isEmpty);
        return;
      }
      expect(node.edges.length, greaterThanOrEqualTo(2), reason: id);
      for (final TroubleshootEdge e in node.edges) {
        walk(engine.answer(s, e.answerId), <String>{...seen, id});
      }
    }

    walk(engine.start(), <String>{});
    expect(outcomes, greaterThanOrEqualTo(8));
  });
}
