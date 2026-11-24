import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/constants/languages.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/about_screen.dart';
import 'package:roehens/screens/appearance_screen.dart';
import 'package:roehens/screens/import_export_screen.dart';
import 'package:roehens/screens/language_screen.dart';
import 'package:roehens/screens/licenses_screen.dart';
import 'package:roehens/screens/support/feedback.dart';
import 'package:roehens/screens/upgrade_screen.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_dialog.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_switch.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';

/// The Settings tab. Help appears only when the app wires the Help section
/// in ([onOpenHelp]); a row that opens nothing is never drawn.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onOpenHelp});

  final VoidCallback? onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppNavBar(title: l10n.settingsTitle),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              app.settings,
              app.subscription,
            ]),
            builder: (BuildContext context, Widget? _) {
              final AppSettings s = app.settings.value;
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: <Widget>[
                  _general(context, l10n, s),
                  _viewing(context, l10n, app, s),
                  _cameras(context, l10n),
                  _app(context, l10n, app),
                  _data(context, l10n, app),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _group(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: child,
    );
  }

  String _themeLabel(AppLocalizations l10n, AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => l10n.appearanceSystem,
      AppThemeMode.light => l10n.appearanceLight,
      AppThemeMode.dark => l10n.appearanceDark,
    };
  }

  Widget _general(BuildContext context, AppLocalizations l10n, AppSettings s) {
    final String language = s.localeCode == null
        ? l10n.settingsLanguageSystem
        : appLanguages
              .firstWhere(
                (AppLanguage l) => l.code == s.localeCode,
                orElse: () => appLanguages.first,
              )
              .nativeName;
    return _group(
      AppSection(
        title: l10n.settingsGroupGeneral,
        children: <Widget>[
          AppListRow(
            title: l10n.settingsAppearance,
            subtitle: _themeLabel(l10n, s.themeMode),
            leading: AppIconName.contrast,
            onTap: () => unawaited(openAppearance(context)),
          ),
          AppListRow(
            title: l10n.settingsLanguage,
            subtitle: language,
            leading: AppIconName.language,
            onTap: () => unawaited(openLanguage(context)),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    AppIconName? icon,
  }) {
    return AppListRow(
      title: title,
      leading: icon,
      showChevron: false,
      trailing: AppSwitch(
        value: value,
        semanticLabel: title,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _viewing(
    BuildContext context,
    AppLocalizations l10n,
    AppProviders app,
    AppSettings s,
  ) {
    return _group(
      AppSection(
        title: l10n.settingsGroupViewing,
        footer: l10n.settingsGridSubstreamHelp,
        children: <Widget>[
          _switchRow(
            title: l10n.settingsAutoCycle,
            icon: AppIconName.autoCycle,
            value: s.autoCycleEnabled,
            onChanged: (bool v) =>
                unawaited(app.settings.setAutoCycle(enabled: v)),
          ),
          if (s.autoCycleEnabled)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final int seconds in Limits.autoCycleSeconds)
                    AppChip(
                      label: l10n.layoutAutoCycleSeconds(seconds),
                      selected: s.autoCycleSeconds == seconds,
                      onTap: () => unawaited(
                        app.settings.setAutoCycle(
                          enabled: true,
                          seconds: seconds,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Semantics(
              label: l10n.settingsTransport,
              child: AppSegmentedControl<StreamTransport>(
                selected: s.defaultTransport == StreamTransport.udp
                    ? StreamTransport.auto
                    : s.defaultTransport,
                onChanged: (StreamTransport t) =>
                    unawaited(app.settings.setDefaultTransport(t)),
                segments: <AppSegment<StreamTransport>>[
                  AppSegment<StreamTransport>(
                    value: StreamTransport.auto,
                    label: l10n.transportAuto,
                  ),
                  AppSegment<StreamTransport>(
                    value: StreamTransport.tcp,
                    label: l10n.transportTcp,
                  ),
                ],
              ),
            ),
          ),
          _switchRow(
            title: l10n.settingsGridSubstream,
            value: s.gridSubstreamDefault,
            onChanged: (bool v) => unawaited(
              app.settings.update(
                (AppSettings c) => c.copyWith(gridSubstreamDefault: v),
              ),
            ),
          ),
          _switchRow(
            title: l10n.settingsOverlayLabels,
            value: s.showOverlayLabels,
            onChanged: (bool v) => unawaited(
              app.settings.update(
                (AppSettings c) => c.copyWith(showOverlayLabels: v),
              ),
            ),
          ),
          _switchRow(
            title: l10n.settingsKeepAwake,
            value: s.keepAwake,
            onChanged: (bool v) =>
                unawaited(app.settings.setKeepAwake(enabled: v)),
          ),
          _switchRow(
            title: l10n.settingsHaptics,
            value: s.hapticsEnabled,
            onChanged: (bool v) =>
                unawaited(app.settings.setHaptics(enabled: v)),
          ),
        ],
      ),
    );
  }

  Widget _cameras(BuildContext context, AppLocalizations l10n) {
    return _group(
      AppSection(
        title: l10n.settingsGroupCameras,
        children: <Widget>[
          AppListRow(
            title: l10n.settingsImportExport,
            leading: AppIconName.exportFile,
            onTap: () => unawaited(openImportExport(context)),
          ),
          if (onOpenHelp != null)
            AppListRow(
              title: l10n.settingsHelp,
              leading: AppIconName.help,
              onTap: onOpenHelp,
            ),
        ],
      ),
    );
  }

  Widget _app(BuildContext context, AppLocalizations l10n, AppProviders app) {
    final bool billing = app.storeConfig.iapSupported;
    return _group(
      AppSection(
        title: l10n.settingsGroupApp,
        children: <Widget>[
          if (billing)
            AppListRow(
              title: l10n.settingsUpgrade,
              subtitle: app.subscription.isAdFree
                  ? l10n.settingsUpgradeOwned
                  : null,
              leading: AppIconName.upgrade,
              onTap: () => unawaited(openUpgrade(context)),
            ),
          if (billing)
            AppListRow(
              title: l10n.settingsRestore,
              leading: AppIconName.refresh,
              showChevron: false,
              onTap: () => unawaited(_restore(context, app, l10n)),
            ),
          AppListRow(
            title: l10n.settingsRate,
            leading: AppIconName.star,
            showChevron: false,
            onTap: () => unawaited(app.review.openStoreListing()),
          ),
          AppListRow(
            title: l10n.settingsFeedback,
            leading: AppIconName.mail,
            showChevron: false,
            onTap: () => unawaited(
              sendFeedbackMail(context, app, subject: l10n.feedbackSubject),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    AppProviders app,
    AppLocalizations l10n,
  ) async {
    await app.subscription.restore();
    if (context.mounted && app.subscription.failure.value == null) {
      AppToast.show(context, message: l10n.settingsRestoreDone);
    }
  }

  Widget _data(BuildContext context, AppLocalizations l10n, AppProviders app) {
    return _group(
      AppSection(
        title: l10n.settingsGroupData,
        footer: l10n.settingsDeleteAllHelp,
        children: <Widget>[
          AppListRow(
            title: l10n.settingsLicenses,
            leading: AppIconName.book,
            onTap: () => unawaited(openLicenses(context)),
          ),
          AppListRow(
            title: l10n.settingsAbout,
            leading: AppIconName.info,
            onTap: () => unawaited(openAbout(context)),
          ),
          AppListRow(
            title: l10n.settingsDeleteAll,
            leading: AppIconName.delete,
            destructive: true,
            showChevron: false,
            onTap: () => unawaited(_confirmDelete(context, app, l10n)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppProviders app,
    AppLocalizations l10n,
  ) async {
    final bool? yes = await showAppDialog<bool>(
      context,
      dismissLabel: l10n.settingsDeleteCancel,
      builder: (BuildContext dialog) {
        return AppDialog(
          title: l10n.settingsDeleteConfirmTitle,
          message: l10n.settingsDeleteConfirmBody,
          actions: <AppDialogAction>[
            AppDialogAction(
              label: l10n.settingsDeleteConfirm,
              kind: AppButtonKind.destructive,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
            AppDialogAction(
              label: l10n.settingsDeleteCancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
          ],
        );
      },
    );
    if (yes != true) {
      return;
    }
    await app.deleteAllLocalData();
    if (context.mounted) {
      AppToast.show(context, message: l10n.settingsDeleted);
    }
  }
}
