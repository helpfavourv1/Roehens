import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_support.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/help/help_callout.dart';
import 'package:roehens/widgets/help/help_code_block.dart';
import 'package:roehens/widgets/help/help_deep_link_button.dart';
import 'package:roehens/widgets/help/help_step_card.dart';

Future<void> openHelpArticle(
  BuildContext context,
  String articleId,
  HelpActions actions,
) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) =>
          HelpArticleScreen(articleId: articleId, actions: actions),
    ),
  );
}

/// One article: a title, a line saying what it is for, and numbered steps.
/// A step may carry a callout, values to copy and buttons to places inside
/// Roehens. A language without the text shows English.
class HelpArticleScreen extends StatelessWidget {
  const HelpArticleScreen({
    super.key,
    required this.articleId,
    required this.actions,
  });

  final String articleId;
  final HelpActions actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return HelpContent(
      builder:
          (BuildContext context, HelpCatalog catalog, HelpStrings strings) {
            final HelpArticle? article = catalog.article(articleId);
            return AppScaffold(
              navBar: AppNavBar(
                title: article == null
                    ? l10n.helpTitle
                    : strings.text(HelpCatalog.titleKey(article.id)),
                onBack: () => Navigator.of(context).maybePop(),
                backLabel: l10n.actionBack,
              ),
              body: article == null
                  ? AppEmptyState(
                      icon: AppIconName.book,
                      title: l10n.helpUnavailable,
                    )
                  : _steps(context, l10n, strings, article),
            );
          },
    );
  }

  Widget _steps(
    BuildContext context,
    AppLocalizations l10n,
    HelpStrings strings,
    HelpArticle article,
  ) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        Text(
          strings.text(HelpCatalog.summaryKey(article.id)),
          style: context.type.callout.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < article.steps.length; i++) ...<Widget>[
          HelpStepCard(
            number: i + 1,
            numberLabel: l10n.helpStepNumber(i + 1),
            text: strings.text(
              HelpCatalog.stepKey(article.id, article.steps[i].id),
            ),
            children: stepParts(
              context,
              l10n,
              strings,
              article,
              article.steps[i],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  /// The callout, copy blocks and target button of one step.
  List<Widget> stepParts(
    BuildContext context,
    AppLocalizations l10n,
    HelpStrings strings,
    HelpArticle article,
    HelpStep step,
  ) {
    return <Widget>[
      if (step.hasCallout)
        HelpCallout(strings.text(HelpCatalog.calloutKey(article.id, step.id))),
      for (final HelpCopyValue copy in step.copyValues)
        HelpCodeBlock(
          value: copy.value,
          caption: strings.text(
            HelpCatalog.copyKey(article.id, step.id, copy.id),
          ),
          copyLabel: l10n.helpCopy,
          onCopied: () => AppToast.show(context, message: l10n.helpCopied),
        ),
      if (step.target != null)
        HelpDeepLinkButton(
          label: helpTargetLabel(l10n, strings, step.target!),
          icon: helpTargetIcon(step.target!),
          onPressed: () => openHelpTarget(context, step.target!, actions),
        ),
    ];
  }
}
