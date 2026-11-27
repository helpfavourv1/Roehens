import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/core/services/troubleshooter_engine.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_article_screen.dart';
import 'package:roehens/screens/help/help_support.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/help/help_choice_card.dart';
import 'package:roehens/widgets/help/help_deep_link_button.dart';

Future<void> openTroubleshooter(BuildContext context, HelpActions actions) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => TroubleshooterScreen(actions: actions),
    ),
  );
}

/// A few questions, one at a time, that end in what to try. Back and start
/// again are always there. The tree itself is data, walked by a pure engine.
class TroubleshooterScreen extends StatefulWidget {
  const TroubleshooterScreen({super.key, required this.actions});

  final HelpActions actions;

  @override
  State<TroubleshooterScreen> createState() => _TroubleshooterScreenState();
}

class _TroubleshooterScreenState extends State<TroubleshooterScreen> {
  final ValueNotifier<TroubleshootSession?> _session =
      ValueNotifier<TroubleshootSession?>(null);

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return HelpContent(
      builder:
          (BuildContext context, HelpCatalog catalog, HelpStrings strings) {
            final TroubleshooterEngine engine = TroubleshooterEngine(catalog);
            return ValueListenableBuilder<TroubleshootSession?>(
              valueListenable: _session,
              builder:
                  (
                    BuildContext context,
                    TroubleshootSession? stored,
                    Widget? _,
                  ) {
                    final TroubleshootSession session =
                        stored ?? engine.start();
                    final TroubleshootNode node = engine.current(session);
                    return AppScaffold(
                      navBar: AppNavBar(
                        title: l10n.troubleTitle,
                        onBack: () => Navigator.of(context).maybePop(),
                        backLabel: l10n.actionBack,
                      ),
                      body: ListView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: <Widget>[
                          if (node.isOutcome)
                            ..._outcome(context, l10n, strings, node)
                          else
                            ..._question(
                              context,
                              strings,
                              engine,
                              session,
                              node,
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: <Widget>[
                              if (session.canGoBack)
                                Expanded(
                                  child: AppButton(
                                    label: l10n.troubleBack,
                                    kind: AppButtonKind.secondary,
                                    onPressed: () =>
                                        _session.value = engine.back(session),
                                  ),
                                ),
                              if (session.canGoBack)
                                const SizedBox(width: AppSpacing.sm),
                              if (session.canGoBack)
                                Expanded(
                                  child: AppButton(
                                    label: l10n.troubleRestart,
                                    kind: AppButtonKind.secondary,
                                    onPressed: () => _session.value = engine
                                        .restart(session),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
            );
          },
    );
  }

  List<Widget> _question(
    BuildContext context,
    HelpStrings strings,
    TroubleshooterEngine engine,
    TroubleshootSession session,
    TroubleshootNode node,
  ) {
    return <Widget>[
      Text(
        strings.text(HelpCatalog.questionKey(node.id)),
        style: context.type.title1.copyWith(color: context.colors.textPrimary),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final TroubleshootEdge e in node.edges) ...<Widget>[
        HelpChoiceCard(
          title: strings.text(HelpCatalog.answerKey(node.id, e.answerId)),
          onTap: () => _session.value = engine.answer(session, e.answerId),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

  List<Widget> _outcome(
    BuildContext context,
    AppLocalizations l10n,
    HelpStrings strings,
    TroubleshootNode node,
  ) {
    final TroubleshootOutcome outcome = node.outcome!;
    return <Widget>[
      AppSectionTitle(l10n.troubleWhatToTry),
      Text(
        strings.text(HelpCatalog.outcomeKey(node.id)),
        style: context.type.body.copyWith(color: context.colors.textPrimary),
      ),
      for (final HelpTarget t in outcome.targets) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        HelpDeepLinkButton(
          label: helpTargetLabel(l10n, strings, t),
          icon: helpTargetIcon(t),
          onPressed: () => openHelpTarget(context, t, widget.actions),
        ),
      ],
      if (outcome.articleIds.isNotEmpty) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        AppSection(
          title: l10n.troubleReadMore,
          children: <Widget>[
            for (final String id in outcome.articleIds)
              AppListRow(
                title: strings.text(HelpCatalog.titleKey(id)),
                subtitle: strings.text(HelpCatalog.summaryKey(id)),
                leading: AppIconName.book,
                onTap: () =>
                    unawaited(openHelpArticle(context, id, widget.actions)),
              ),
          ],
        ),
      ],
    ];
  }
}
