import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

enum AppBadgeTone { neutral, accent, success, warning, error }

/// A small non-interactive label such as a count or "PRO". Not a status: the
/// status pill (icon, text and color together) is its own widget.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.tone = AppBadgeTone.neutral});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color foreground = switch (tone) {
      AppBadgeTone.neutral => colors.textSecondary,
      AppBadgeTone.accent => colors.textOnAccent,
      AppBadgeTone.success => colors.success,
      AppBadgeTone.warning => colors.warning,
      AppBadgeTone.error => colors.error,
    };
    final Color background = switch (tone) {
      AppBadgeTone.neutral => colors.bgTertiary,
      AppBadgeTone.accent => colors.accent,
      AppBadgeTone.success => colors.bgTertiary,
      AppBadgeTone.warning => colors.bgTertiary,
      AppBadgeTone.error => colors.bgTertiary,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allPill,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.badgeHeight,
          minWidth: AppSizes.badgeHeight,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.data.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
