import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// One button at the bottom of a dialog.
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.secondary,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonKind kind;
}

/// A confirmation or notice. Buttons are stacked at full width, so long
/// translations and large text never clip them.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.message,
    this.content,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;

  static const double maxWidth = 400;

  @override
  Widget build(BuildContext context) {
    final AppTokensData tokens = context.tokens;
    return Center(
      child: Padding(
        padding: AppSpacing.allMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colors.bgElevated,
              borderRadius: AppRadius.allLg,
              boxShadow: tokens.elevation.sheet,
              border: Border.all(
                color: tokens.colors.borderSubtle,
                width: AppSizes.hairline,
              ),
            ),
            child: Padding(
              padding: AppSpacing.allMd,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: context.type.title2.copyWith(
                          color: tokens.colors.textPrimary,
                        ),
                      ),
                    ),
                    if (message != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message!,
                        style: context.type.body.copyWith(
                          color: tokens.colors.textSecondary,
                        ),
                      ),
                    ],
                    if (content != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      content!,
                    ],
                    const SizedBox(height: AppSpacing.md),
                    for (int i = 0; i < actions.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: actions[i].label,
                        kind: actions[i].kind,
                        expand: true,
                        onPressed: actions[i].onPressed,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents [builder] (normally an [AppDialog]) over a scrim. Closes on a tap
/// outside when [dismissible], and on Escape.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required String dismissLabel,
  bool dismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppModalRoute<T>(
      scrim: context.colors.scrim,
      motion: AppModalMotion.fade,
      dismissLabel: dismissLabel,
      reduceMotion: context.reduceMotion,
      dismissible: dismissible,
      builder: builder,
    ),
  );
}
