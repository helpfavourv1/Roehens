import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/wordmark.dart';

Future<void> openAbout(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const AboutScreen(),
    ),
  );
}

/// Version, build, the store, support, and the plain statement that Roehens
/// works while it is open.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.aboutTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Wordmark(l10n.appName),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.onboardingTagline,
            style: context.type.callout.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            children: <Widget>[
              AppListRow(
                title: l10n.aboutVersion,
                showChevron: false,
                trailing: LtrText(app.appVersion.isEmpty ? '-' : app.appVersion),
              ),
              AppListRow(
                title: l10n.aboutBuild,
                showChevron: false,
                trailing: LtrText(
                  app.buildNumber.isEmpty ? '-' : app.buildNumber,
                ),
              ),
              AppListRow(
                title: l10n.aboutSupport,
                subtitle: AppConstants.supportEmail,
                leading: AppIconName.mail,
                onTap: () => unawaited(_mail(context, app, l10n)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.aboutWhileOpen,
            style: context.type.footnote.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mail(
    BuildContext context,
    AppProviders app,
    AppLocalizations l10n,
  ) async {
    final bool opened = await app.links.composeMail(
      to: AppConstants.supportEmail,
      subject: l10n.feedbackSubject,
    );
    if (!opened && context.mounted) {
      AppToast.show(context, message: l10n.aboutNoMail);
    }
  }
}
