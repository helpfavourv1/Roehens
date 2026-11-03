import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The one row: a primary line and an optional secondary line, an optional
/// leading icon, and an optional trailing widget. A tappable row without its
/// own [trailing] shows a chevron. Pressing tints the row.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.destructive = false,
    this.showChevron = true,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final AppIconName? leading;

  /// Replaces the chevron.
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  /// Titles in the error color, for delete actions.
  final bool destructive;
  final bool showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color titleColor = destructive ? colors.error : colors.textPrimary;
    final Color leadingColor = destructive
        ? colors.error
        : selected
        ? colors.accent
        : colors.textSecondary;
    final bool tappable = onTap != null || onLongPress != null;

    Widget? end = trailing;
    if (end == null && tappable && showChevron) {
      end = AppIcon(
        AppIconName.chevronRight,
        size: AppSizes.iconRowTrailing,
        color: colors.textTertiary,
      );
    }

    final Widget row = ColoredBox(
      color: selected
          ? colors.accentWash
          : colors.bgSecondary.withValues(alpha: 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                AppIcon(
                  leading!,
                  size: AppSizes.iconRowLeading,
                  color: leadingColor,
                  weight: selected ? AppIconWeight.fill : AppIconWeight.bold,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: context.type.callout.copyWith(color: titleColor),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.type.footnote.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (end != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                end,
              ],
            ],
          ),
        ),
      ),
    );

    if (!tappable) {
      return row;
    }
    return AppPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      style: AppPressStyle.tint,
      semanticLabel: semanticLabel,
      selected: selected,
      child: row,
    );
  }
}
