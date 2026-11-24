import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/constants/languages.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/selected_mark.dart';

Future<void> openLanguage(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const LanguageScreen(),
    ),
  );
}

/// The 24 languages by their own names, searchable. Following the phone is
/// the default and the first choice.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(AppProviders app, String? code) {
    unawaited(app.haptics.selection());
    unawaited(app.locale.setLanguage(code));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.languageTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_search, app.settings]),
        builder: (BuildContext context, Widget? _) {
          final String? current = app.settings.value.localeCode;
          final String query = _search.text;
          final List<AppLanguage> shown = LanguageScreenSearch.matching(query);
          final bool showSystem =
              query.trim().isEmpty ||
              l10n.settingsLanguageSystem.toLowerCase().contains(
                query.trim().toLowerCase(),
              );
          final Widget search = AppTextField(
            controller: _search,
            hint: l10n.languageSearch,
            semanticLabel: l10n.languageSearch,
            leadingIcon: AppIconName.search,
            textInputAction: TextInputAction.search,
          );
          if (shown.isEmpty && !showSystem) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: search,
                ),
                Expanded(
                  child: AppEmptyState(
                    icon: AppIconName.language,
                    title: l10n.languageNoMatch,
                  ),
                ),
              ],
            );
          }
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              search,
              const SizedBox(height: AppSpacing.md),
              AppSection(
                children: <Widget>[
                  if (showSystem)
                    AppListRow(
                      title: l10n.settingsLanguageSystem,
                      showChevron: false,
                      selected: current == null,
                      trailing: current == null ? const SelectedMark() : null,
                      onTap: () => _choose(app, null),
                    ),
                  for (final AppLanguage language in shown)
                    AppListRow(
                      title: language.nativeName,
                      subtitle: language.code,
                      showChevron: false,
                      selected: current == language.code,
                      trailing: current == language.code
                          ? const SelectedMark()
                          : null,
                      onTap: () => _choose(app, language.code),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The rule of the language search, apart from the screen.
class LanguageScreenSearch {
  LanguageScreenSearch._();

  /// Languages whose own name or code contains the search text.
  static List<AppLanguage> matching(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return appLanguages;
    }
    return <AppLanguage>[
      for (final AppLanguage l in appLanguages)
        if (l.nativeName.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
          l,
    ];
  }
}
