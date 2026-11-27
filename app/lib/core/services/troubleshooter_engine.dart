import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';

/// Where the person is in the troubleshooter: the nodes they have passed and
/// the one they are on.
class TroubleshootSession {
  const TroubleshootSession(this.path);

  /// Node ids from the first question to the current one.
  final List<String> path;

  String get currentId => path.last;
  bool get canGoBack => path.length > 1;
}

/// Walks the decision tree of `help_structure.json`. It holds no state of its
/// own: every step returns a new [TroubleshootSession].
class TroubleshooterEngine {
  const TroubleshooterEngine(this.catalog);

  final HelpCatalog catalog;

  TroubleshootSession start() {
    return TroubleshootSession(<String>[catalog.troubleshooterStart]);
  }

  TroubleshootNode current(TroubleshootSession session) {
    return catalog.node(session.currentId)!;
  }

  /// The session after choosing [answerId]. An answer the node does not offer
  /// leaves the session as it is.
  TroubleshootSession answer(TroubleshootSession session, String answerId) {
    final TroubleshootNode node = current(session);
    for (final TroubleshootEdge e in node.edges) {
      if (e.answerId == answerId) {
        return TroubleshootSession(<String>[...session.path, e.to]);
      }
    }
    return session;
  }

  TroubleshootSession back(TroubleshootSession session) {
    if (!session.canGoBack) {
      return session;
    }
    return TroubleshootSession(
      session.path.sublist(0, session.path.length - 1),
    );
  }

  TroubleshootSession restart(TroubleshootSession session) => start();
}
