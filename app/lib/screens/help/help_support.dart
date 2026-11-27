import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/providers/help_provider.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_article_screen.dart';
import 'package:roehens/screens/help/network_diagnostics_screen.dart';
import 'package:roehens/screens/help/troubleshooter_screen.dart';
import 'package:roehens/ui/components/app_error_state.dart';
import 'package:roehens/ui/icons/app_icons.dart';

/// What Help may ask the app to open. The app shell supplies both; Help
/// itself never knows how routes are built.
class HelpActions {
  const HelpActions({required this.onAddCamera, required this.onFindCameras});

  final VoidCallback onAddCamera;
  final VoidCallback onFindCameras;
}

/// Opens a Help step's target: a place inside Roehens, or the phone's own
/// Settings. There is no target that leaves the app for the web.
void openHelpTarget(
  BuildContext context,
  HelpTarget target,
  HelpActions actions,
) {
  switch (target.kind) {
    case HelpTargetKind.addCamera:
      actions.onAddCamera();
    case HelpTargetKind.findCameras:
      actions.onFindCameras();
    case HelpTargetKind.diagnostics:
      unawaited(openNetworkDiagnostics(context, actions));
    case HelpTargetKind.troubleshooter:
      unawaited(openTroubleshooter(context, actions));
    case HelpTargetKind.phoneSettings:
      unawaited(AppScope.of(context).permission.openAppSettings());
    case HelpTargetKind.article:
      unawaited(openHelpArticle(context, target.articleId!, actions));
  }
}

/// The button label for [target], in the person's language.
String helpTargetLabel(
  AppLocalizations l10n,
  HelpStrings strings,
  HelpTarget target,
) {
  return switch (target.kind) {
    HelpTargetKind.addCamera => l10n.helpTargetAddCamera,
    HelpTargetKind.findCameras => l10n.helpTargetFindCameras,
    HelpTargetKind.diagnostics => l10n.helpTargetDiagnostics,
    HelpTargetKind.troubleshooter => l10n.helpTargetTroubleshooter,
    HelpTargetKind.phoneSettings => l10n.helpTargetPhoneSettings,
    HelpTargetKind.article => l10n.helpTargetArticle(
      strings.text(HelpCatalog.titleKey(target.articleId!)),
    ),
  };
}

AppIconName helpTargetIcon(HelpTarget target) {
  return switch (target.kind) {
    HelpTargetKind.addCamera => AppIconName.cameraAdd,
    HelpTargetKind.findCameras => AppIconName.scanNetwork,
    HelpTargetKind.diagnostics => AppIconName.network,
    HelpTargetKind.troubleshooter => AppIconName.route,
    HelpTargetKind.phoneSettings => AppIconName.settings,
    HelpTargetKind.article => AppIconName.book,
  };
}

/// Reads the Help content when the screen first opens and builds [builder]
/// once it is ready. While it loads only the chrome shows; if the content
/// could not be read it says so and offers to try again.
class HelpContent extends StatefulWidget {
  const HelpContent({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    HelpCatalog catalog,
    HelpStrings strings,
  )
  builder;

  @override
  State<HelpContent> createState() => _HelpContentState();
}

class _HelpContentState extends State<HelpContent> {
  late AppProviders _app;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _app = AppScope.of(context);
      unawaited(_app.ensureHelp());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<HelpState>(
      valueListenable: _app.help,
      builder: (BuildContext context, HelpState state, Widget? _) {
        if (state.isReady) {
          return widget.builder(context, state.catalog!, state.strings!);
        }
        if (state.error != null) {
          return AppErrorState(
            icon: AppIconName.warning,
            title: l10n.helpUnavailable,
            primaryLabel: l10n.actionRetry,
            onPrimary: () => unawaited(_app.ensureHelp()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
