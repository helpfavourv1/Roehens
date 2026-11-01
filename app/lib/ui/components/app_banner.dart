import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

enum AppBannerTone { info, warning, error, success }

/// A message that stays on the screen until the problem goes (storage warning,
/// offline, a switched-off feature). The tone shows as icon, text and color
/// together, never color alone.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.tone = AppBannerTone.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (Color accent, AppIconName icon) = switch (tone) {
      AppBannerTone.info => (colors.accent, AppIconName.info),
      AppBannerTone.warning => (colors.warning, AppIconName.warning),
      AppBannerTone.error => (colors.error, AppIconName.failure),
      AppBannerTone.success => (colors.success, AppIconName.success),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: AppRadius.allMd,
          border: Border.all(color: accent.withValues(alpha: 0.5), width: AppSizes.hairline),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIcon(icon, size: AppSizes.iconRowLeading, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    message,
                    style: context.type.body.copyWith(color: colors.textPrimary),
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                AppChip(label: actionLabel!, onTap: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
