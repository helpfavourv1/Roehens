import 'package:flutter/widgets.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_sheet.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Full message and actions for a camera whose tile is too small to hold them
/// (D5): below 120 wide the tile shows an icon only, and a tap opens this.
Future<void> showCameraStatusSheet(
  BuildContext context, {
  required Camera camera,
  required AppError error,
  required VoidCallback onRetry,
  required VoidCallback onEdit,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showAppSheet<void>(
    context,
    title: camera.name,
    dismissLabel: l10n.actionClose,
    builder: (BuildContext sheet) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              errorMessage(l10n, error),
              style: sheet.type.body.copyWith(
                color: sheet.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                if (error.retriable) ...<Widget>[
                  Expanded(
                    child: AppButton(
                      label: l10n.actionRetry,
                      onPressed: () {
                        Navigator.of(sheet).pop();
                        onRetry();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: AppButton(
                    label: l10n.actionEdit,
                    kind: AppButtonKind.secondary,
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      onEdit();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
