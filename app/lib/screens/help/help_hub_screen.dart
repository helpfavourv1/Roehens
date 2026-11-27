import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_article_screen.dart';
import 'package:roehens/screens/help/help_support.dart';
import 'package:roehens/screens/help/network_diagnostics_screen.dart';
import 'package:roehens/screens/help/remote_access_wizard_screen.dart';
import 'package:roehens/screens/help/troubleshooter_screen.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/help/help_choice_card.dart';

Future<void> openHelp(BuildContext context, HelpActions actions) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => HelpHubScreen(actions: actions),
    ),
  );
}

/// Four cards (Same Wi-Fi, Away from home, Troubleshoot, Diagnostics) and the
/// full list of articles. The kill switch `helpContent` hides the wizard and
/// the diagnostics.
class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key, required this.actions});

  final HelpActions actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return HelpContent(
      builder:
          (BuildContext context, HelpCatalog catalog, HelpStrings strings) {
            return ListenableBuilder(
              listenable: app.flags,
              builder: (BuildContext context, Widget? _) {
                final bool full = app.flags.isEnabled('helpContent');
                return AppScaffold(
                  navBar: AppNavBar(
                    title: l10n.helpTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                    backLabel: l10n.actionBack,
                  ),
                  body: ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      if (!full) ...<Widget>[
                        AppBanner(message: l10n.helpDisabled),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      HelpChoiceCard(
                        icon: AppIconName.wifi,
                        title: l10n.helpHubSameWifiTitle,
                        body: l10n.helpHubSameWifiBody,
                        onTap: () => unawaited(
                          openHelpArticle(context, 'lan_setup', actions),
                        ),
                      ),
                      if (full) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        HelpChoiceCard(
                          icon: AppIconName.globeNetwork,
                          title: l10n.helpHubAwayTitle,
                          body: l10n.helpHubAwayBody,
                          onTap: () => unawaited(
                            openRemoteAccessWizard(context, actions),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      HelpChoiceCard(
                        icon: AppIconName.route,
                        title: l10n.helpHubTroubleTitle,
                        body: l10n.helpHubTroubleBody,
                        onTap: () =>
                            unawaited(openTroubleshooter(context, actions)),
                      ),
                      if (full) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        HelpChoiceCard(
                          icon: AppIconName.network,
                          title: l10n.helpHubDiagnosticsTitle,
                          body: l10n.helpHubDiagnosticsBody,
                          onTap: () => unawaited(
                            openNetworkDiagnostics(context, actions),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _articles(
                        context,
                        l10n.helpArticlesSameWifi,
                        catalog.inGroup(HelpGroup.sameWifi),
                        strings,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _articles(
                        context,
                        l10n.helpArticlesAway,
                        catalog.inGroup(HelpGroup.away),
                        strings,
                      ),
                    ],
                  ),
                );
              },
            );
          },
    );
  }

  Widget _articles(
    BuildContext context,
    String title,
    List<HelpArticle> articles,
    HelpStrings strings,
  ) {
    return AppSection(
      title: title,
      children: <Widget>[
        for (final HelpArticle a in articles)
          AppListRow(
            title: strings.text(HelpCatalog.titleKey(a.id)),
            subtitle: strings.text(HelpCatalog.summaryKey(a.id)),
            leading: AppIconName.book,
            onTap: () => unawaited(openHelpArticle(context, a.id, actions)),
          ),
      ],
    );
  }
}
