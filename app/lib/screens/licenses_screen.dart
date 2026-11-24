import 'package:flutter/widgets.dart';
import 'package:roehens/core/services/license_collector.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

Future<void> openLicenses(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const LicensesScreen(),
    ),
  );
}

/// The open-source notices, in the app's own screens. A list of packages,
/// then the full text of one package.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key, this.loader = LicenseCollector.collect});

  /// Reads the licenses; replaced in tests.
  final Future<List<PackageLicense>> Function() loader;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<List<PackageLicense>> _licenses = widget.loader();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.licensesTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: FutureBuilder<List<PackageLicense>>(
        future: _licenses,
        builder:
            (BuildContext context, AsyncSnapshot<List<PackageLicense>> snap) {
              final List<PackageLicense>? list = snap.data;
              if (list == null) {
                // Reading takes a moment; the chrome shows and nothing else.
                return const SizedBox.shrink();
              }
              if (list.isEmpty) {
                return AppEmptyState(
                  icon: AppIconName.book,
                  title: l10n.licensesEmpty,
                );
              }
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: <Widget>[
                  AppSection(
                    children: <Widget>[
                      for (final PackageLicense p in list)
                        AppListRow(
                          title: p.name,
                          subtitle: l10n.licensesCount(p.texts.length),
                          onTap: () => Navigator.of(context).push<void>(
                            AppPageRoute<void>(
                              reduceMotion: context.reduceMotion,
                              builder: (BuildContext _) =>
                                  LicenseDetailScreen(license: p),
                            ),
                          ),
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

/// The full license text of one package.
class LicenseDetailScreen extends StatelessWidget {
  const LicenseDetailScreen({super.key, required this.license});

  final PackageLicense license;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: license.name,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          for (int i = 0; i < license.texts.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            // Notices are mostly English legal text; the mono face keeps their
            // line breaks readable.
            LtrBlock(
              license.texts[i],
              style: context.type.mono.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
