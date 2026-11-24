import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_dialog.dart';
import 'package:roehens/ui/components/app_toast.dart';

/// Opens a mail to support. Diagnostics are never added unless the person
/// says yes in a dialog that explains what they hold. Returns false when the
/// person backed out of the dialog.
Future<bool> sendFeedbackMail(
  BuildContext context,
  AppProviders app, {
  required String subject,
}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? attach = await showAppDialog<bool>(
    context,
    dismissLabel: l10n.actionClose,
    builder: (BuildContext dialog) {
      return AppDialog(
        title: l10n.feedbackAttachTitle,
        message: l10n.feedbackAttachBody,
        actions: <AppDialogAction>[
          AppDialogAction(
            label: l10n.feedbackAttach,
            kind: AppButtonKind.primary,
            onPressed: () => Navigator.of(dialog).pop(true),
          ),
          AppDialogAction(
            label: l10n.feedbackWithout,
            onPressed: () => Navigator.of(dialog).pop(false),
          ),
        ],
      );
    },
  );
  if (attach == null || !context.mounted) {
    return false;
  }
  final bool opened = await app.links.composeMail(
    to: AppConstants.supportEmail,
    subject: subject,
    body: attach ? app.diagnosticsText() : '',
  );
  if (!opened && context.mounted) {
    AppToast.show(context, message: l10n.aboutNoMail);
  }
  return true;
}
