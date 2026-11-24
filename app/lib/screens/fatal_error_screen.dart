import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/feedback.dart';
import 'package:roehens/ui/components/app_error_state.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/icons/app_icons.dart';

/// The last resort when something unrecoverable happened: a calm full screen
/// with Try again, and Report (a mail to support, with diagnostics only if the
/// person agrees). Saved cameras and settings are not touched.
class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    return AppScaffold(
      body: AppErrorState(
        icon: AppIconName.warning,
        title: l10n.fatalTitle,
        message: l10n.fatalBody,
        primaryLabel: l10n.fatalRetry,
        onPrimary: onRetry,
        secondaryLabel: l10n.fatalReport,
        onSecondary: () => unawaited(
          sendFeedbackMail(context, app, subject: l10n.fatalReportSubject),
        ),
      ),
    );
  }
}
