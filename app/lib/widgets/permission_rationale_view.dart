import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Explains why the app asks for something before the system asks, or, when the
/// person has refused for good, how to turn it on again. The main action asks
/// (or opens the phone's Settings); the second one lets the person skip.
class PermissionRationaleView extends StatelessWidget {
  const PermissionRationaleView({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon = AppIconName.wifi,
    this.reasons = const <String>[],
  });

  final String title;
  final String message;

  /// Short bullet points that say what the access is used for.
  final List<String> reasons;
  final AppIconName icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.allLg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: AppIcon(
                  icon,
                  size: AppSizes.iconHero,
                  color: colors.textSecondary,
                  weight: AppIconWeight.duotone,
                  secondaryColor: colors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.type.title1.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.type.body.copyWith(color: colors.textSecondary),
              ),
              if (reasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                for (final String reason in reasons)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppIcon(
                          AppIconName.check,
                          size: AppSizes.iconRowTrailing,
                          color: colors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            reason,
                            style: context.type.body.copyWith(color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: primaryLabel, onPressed: onPrimary, expand: true),
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
    );
  }
}
