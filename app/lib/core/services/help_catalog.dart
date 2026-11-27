import 'dart:convert';

import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';

/// The language-neutral shape of the Help section: articles and their steps,
/// the remote-access wizard paths, and the troubleshooter's decision tree.
/// All visible text is in per-language files, read with [HelpStrings].
class HelpCatalog {
  HelpCatalog._({
    required this.articles,
    required this.wizardPaths,
    required this.troubleshooterStart,
    required this._nodes,
  });

  /// Reads `help_structure.json`. A structure with a broken reference (an
  /// edge to a missing node, an unknown target, an outcome article that does
  /// not exist) is rejected whole, so the screens never meet one.
  static Result<HelpCatalog> parse(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        return _invalid('not an object');
      }
      final List<HelpArticle> articles = <HelpArticle>[
        for (final Object? a in decoded['articles']! as List<Object?>)
          _article(a! as Map<String, Object?>),
      ];
      final List<WizardPath> paths = <WizardPath>[
        for (final Object? p in decoded['wizard']! as List<Object?>)
          WizardPath(
            id: _map(p)['id']! as String,
            articleId: _map(p)['article']! as String,
          ),
      ];
      final Map<String, Object?> trouble =
          decoded['troubleshooter']! as Map<String, Object?>;
      final Map<String, TroubleshootNode> nodes = <String, TroubleshootNode>{
        for (final Object? n in trouble['nodes']! as List<Object?>)
          _map(n)['id']! as String: _node(_map(n)),
      };
      final HelpCatalog catalog = HelpCatalog._(
        articles: articles,
        wizardPaths: paths,
        troubleshooterStart: trouble['start']! as String,
        nodes: nodes,
      );
      final List<String> problems = catalog.problems();
      if (problems.isNotEmpty) {
        return _invalid(problems.first);
      }
      return Ok<HelpCatalog>(catalog);
    } catch (error) {
      return _invalid('$error');
    }
  }

  static Map<String, Object?> _map(Object? value) {
    return value! as Map<String, Object?>;
  }

  static Result<HelpCatalog> _invalid(String detail) {
    return Err<HelpCatalog>(AppError(ErrorClass.invalidFile, detail: detail));
  }

  static HelpArticle _article(Map<String, Object?> json) {
    return HelpArticle(
      id: json['id']! as String,
      group: json['group'] == 'same_wifi' ? HelpGroup.sameWifi : HelpGroup.away,
      steps: <HelpStep>[
        for (final Object? s in json['steps']! as List<Object?>)
          _step(s! as Map<String, Object?>),
      ],
    );
  }

  static HelpStep _step(Map<String, Object?> json) {
    return HelpStep(
      id: json['id']! as String,
      hasCallout: json['callout'] == true,
      target: HelpTarget.parse(json['target'] as String?),
      copyValues: <HelpCopyValue>[
        for (final Object? c in (json['copy'] as List<Object?>?) ?? <Object?>[])
          HelpCopyValue(
            id: _map(c)['id']! as String,
            value: _map(c)['value']! as String,
          ),
      ],
    );
  }

  static TroubleshootNode _node(Map<String, Object?> json) {
    final Map<String, Object?>? outcome =
        json['outcome'] as Map<String, Object?>?;
    return TroubleshootNode(
      id: json['id']! as String,
      edges: <TroubleshootEdge>[
        for (final Object? e
            in (json['edges'] as List<Object?>?) ?? <Object?>[])
          TroubleshootEdge(
            answerId: _map(e)['answer']! as String,
            to: _map(e)['to']! as String,
          ),
      ],
      outcome: outcome == null
          ? null
          : TroubleshootOutcome(
              articleIds: <String>[
                for (final Object? a
                    in (outcome['articles'] as List<Object?>?) ?? <Object?>[])
                  a! as String,
              ],
              targets: <HelpTarget>[
                for (final Object? t
                    in (outcome['targets'] as List<Object?>?) ?? <Object?>[])
                  HelpTarget.parse(t as String?) ??
                      (throw FormatException('unknown target $t')),
              ],
            ),
    );
  }

  final List<HelpArticle> articles;
  final List<WizardPath> wizardPaths;
  final String troubleshooterStart;
  final Map<String, TroubleshootNode> _nodes;

  HelpArticle? article(String id) {
    for (final HelpArticle a in articles) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  TroubleshootNode? node(String id) => _nodes[id];

  List<HelpArticle> inGroup(HelpGroup group) {
    return <HelpArticle>[
      for (final HelpArticle a in articles)
        if (a.group == group) a,
    ];
  }

  /// Every broken reference in the structure, in words. Empty when sound.
  List<String> problems() {
    final List<String> found = <String>[];
    final Set<String> ids = <String>{};
    for (final HelpArticle a in articles) {
      if (!ids.add(a.id)) {
        found.add('duplicate article ${a.id}');
      }
      if (a.steps.isEmpty) {
        found.add('article ${a.id} has no steps');
      }
      final Set<String> stepIds = <String>{};
      for (final HelpStep s in a.steps) {
        if (!stepIds.add(s.id)) {
          found.add('duplicate step ${a.id}/${s.id}');
        }
        final HelpTarget? t = s.target;
        if (t != null &&
            t.kind == HelpTargetKind.article &&
            !articles.any((HelpArticle x) => x.id == t.articleId)) {
          found.add('step ${a.id}/${s.id} points at a missing article');
        }
      }
    }
    for (final WizardPath p in wizardPaths) {
      if (!ids.contains(p.articleId)) {
        found.add('wizard path ${p.id} uses a missing article');
      }
    }
    if (!_nodes.containsKey(troubleshooterStart)) {
      found.add('troubleshooter start node is missing');
    }
    for (final TroubleshootNode n in _nodes.values) {
      if (n.isOutcome == n.edges.isNotEmpty) {
        found.add('node ${n.id} must be a question or an outcome');
      }
      for (final TroubleshootEdge e in n.edges) {
        if (!_nodes.containsKey(e.to)) {
          found.add('edge ${n.id}/${e.answerId} leads to a missing node');
        }
      }
      for (final String a in n.outcome?.articleIds ?? const <String>[]) {
        if (!ids.contains(a)) {
          found.add('outcome ${n.id} points at a missing article');
        }
      }
    }
    return found;
  }

  // Keys of the language files. One place, so every locale uses the same.
  static String titleKey(String article) => 'article.$article.title';
  static String summaryKey(String article) => 'article.$article.summary';
  static String stepKey(String article, String step) =>
      'article.$article.step.$step.text';
  static String calloutKey(String article, String step) =>
      'article.$article.step.$step.callout';
  static String copyKey(String article, String step, String copy) =>
      'article.$article.step.$step.copy.$copy';
  static String questionKey(String node) => 'trouble.$node.question';
  static String answerKey(String node, String answer) =>
      'trouble.$node.answer.$answer';
  static String outcomeKey(String node) => 'trouble.$node.outcome';

  /// Every key a complete language file must have.
  Set<String> get requiredKeys {
    final Set<String> keys = <String>{};
    for (final HelpArticle a in articles) {
      keys
        ..add(titleKey(a.id))
        ..add(summaryKey(a.id));
      for (final HelpStep s in a.steps) {
        keys.add(stepKey(a.id, s.id));
        if (s.hasCallout) {
          keys.add(calloutKey(a.id, s.id));
        }
        for (final HelpCopyValue c in s.copyValues) {
          keys.add(copyKey(a.id, s.id, c.id));
        }
      }
    }
    for (final TroubleshootNode n in _nodes.values) {
      if (n.isOutcome) {
        keys.add(outcomeKey(n.id));
      } else {
        keys.add(questionKey(n.id));
        for (final TroubleshootEdge e in n.edges) {
          keys.add(answerKey(n.id, e.answerId));
        }
      }
    }
    return keys;
  }
}

/// The text of one language, with English behind it: a key missing from the
/// language file is read from English, never shown as a key.
class HelpStrings {
  const HelpStrings({required this._primary, required this._fallback});

  /// Reads a language file: a flat JSON object of key to text.
  static Map<String, String> parseFile(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final MapEntry<String, Object?> e in decoded.entries)
        if (e.value is String) e.key: e.value! as String,
    };
  }

  final Map<String, String> _primary;
  final Map<String, String> _fallback;

  /// The text for [key], or an empty string when no language has it.
  String text(String key) => _primary[key] ?? _fallback[key] ?? '';

  /// Whether [key] is missing from the chosen language.
  bool isFallback(String key) => !_primary.containsKey(key);
}
