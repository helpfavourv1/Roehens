import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/theme_preview_card.dart';

Future<void> openAppearance(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const AppearanceScreen(),
    ),
  );
}

/// Choose System, Light or Dark with a small picture of each.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.appearanceTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ValueListenableBuilder<AppThemeMode>(
        valueListenable: app.theme,
        builder: (BuildContext context, AppThemeMode mode, Widget? _) {
          Widget card(AppThemeMode value, String label, bool light, bool dark) {
            return Expanded(
              child: ThemePreviewCard(
                label: label,
                selected: mode == value,
                light: light,
                dark: dark,
                onTap: () {
                  unawaited(app.haptics.selection());
                  unawaited(app.theme.setMode(value));
                },
              ),
            );
          }

          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  card(AppThemeMode.system, l10n.appearanceSystem, true, true),
                  const SizedBox(width: AppSpacing.sm),
                  card(AppThemeMode.light, l10n.appearanceLight, true, false),
                  const SizedBox(width: AppSpacing.sm),
                  card(AppThemeMode.dark, l10n.appearanceDark, false, true),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.appearanceHelp,
                style: context.type.footnote.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
