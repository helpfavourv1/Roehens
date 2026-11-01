import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A pill. Used for filters and for small actions such as Retry, Edit and Undo,
/// which are never bare text (C1.11).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.selected = false,
    this.destructive = false,
    this.semanticLabel,
  });

  final String label;

  /// Null makes the chip a plain label.
  final VoidCallback? onTap;
  final AppIconName? icon;
  final bool selected;
  final bool destructive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color fill = selected ? colors.accentWash : colors.bgTertiary;
    final Color foreground = destructive
        ? colors.error
        : selected
            ? colors.accent
            : colors.textPrimary;
    final Color border = selected ? colors.accent : colors.borderStrong;

    final Widget chip = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.allPill,
        border: Border.all(color: border, width: AppSizes.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(
                  icon!,
                  size: AppSizes.iconChipGlyph,
                  color: foreground,
                  weight: selected ? AppIconWeight.fill : AppIconWeight.bold,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.callout.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return chip;
    }
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadius.allPill,
      semanticLabel: semanticLabel ?? label,
      selected: selected,
      minHitSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
      child: chip,
    );
  }
}
