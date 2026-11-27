import 'package:roehens/core/models/help_article.dart';

/// One answer to a question, and the node it leads to.
class TroubleshootEdge {
  const TroubleshootEdge({required this.answerId, required this.to});

  final String answerId;
  final String to;
}

/// What the troubleshooter ends with: articles to read and places to go.
class TroubleshootOutcome {
  const TroubleshootOutcome({
    this.articleIds = const <String>[],
    this.targets = const <HelpTarget>[],
  });

  final List<String> articleIds;
  final List<HelpTarget> targets;
}

/// A question (with [edges]) or an end (with an [outcome]); never both.
class TroubleshootNode {
  const TroubleshootNode({
    required this.id,
    this.edges = const <TroubleshootEdge>[],
    this.outcome,
  });

  final String id;
  final List<TroubleshootEdge> edges;
  final TroubleshootOutcome? outcome;

  bool get isOutcome => outcome != null;
}

/// One path of the remote-access wizard. It walks the steps of [articleId].
class WizardPath {
  const WizardPath({required this.id, required this.articleId});

  final String id;
  final String articleId;
}
