import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// What a screen shows when something failed: the problem in plain words, a
/// primary action such as Retry, and an optional second one such as Edit or
/// Report. The icon, the words and the color say the same thing together.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIconName.failure,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;
  final AppIconName icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.allLg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: AppIcon(
                    icon,
                    size: AppSizes.iconHero,
                    color: context.colors.error,
                    weight: AppIconWeight.duotone,
                    secondaryColor: context.colors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.type.title2.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: context.type.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
                if (primaryLabel != null && onPrimary != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: primaryLabel!,
                    onPressed: onPrimary,
                    expand: true,
                  ),
                ],
                if (secondaryLabel != null && onSecondary != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: secondaryLabel!,
                    onPressed: onSecondary,
                    kind: AppButtonKind.secondary,
                    expand: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
