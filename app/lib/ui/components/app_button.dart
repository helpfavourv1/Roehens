import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/components/app_progress.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Primary and destructive buttons are filled; secondary is bordered; tinted
/// sits between. There is no text-only variant: a control is always visibly a
/// control (C1.11).
enum AppButtonKind { primary, secondary, tinted, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
  });

  final String label;

  /// Null disables the button. While [isLoading] the button ignores taps.
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final AppIconName? icon;
  final bool isLoading;

  /// Fill the available width.
  final bool expand;
  final String? semanticLabel;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool enabled = _enabled;

    final Color fill;
    final Color foreground;
    final Color? border;
    if (!enabled && !isLoading) {
      fill = colors.bgTertiary;
      foreground = colors.textTertiary;
      border = null;
    } else {
      switch (kind) {
        case AppButtonKind.primary:
          fill = colors.accent;
          foreground = colors.textOnAccent;
          border = null;
        case AppButtonKind.secondary:
          fill = colors.bgSecondary;
          foreground = colors.textPrimary;
          border = colors.borderStrong;
        case AppButtonKind.tinted:
          fill = colors.accentWash;
          foreground = colors.accent;
          border = null;
        case AppButtonKind.destructive:
          fill = colors.error;
          foreground = colors.textOnAccent;
          border = null;
      }
    }

    final List<Widget> content = <Widget>[
      if (isLoading)
        AppProgress.spinner(size: AppSizes.iconChipGlyph, color: foreground)
      else if (icon != null)
        AppIcon(icon!, size: AppSizes.iconChipGlyph, color: foreground),
      if (isLoading || icon != null) const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.type.callout.copyWith(color: foreground),
        ),
      ),
    ];

    final Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.allMd,
        border: border == null
            ? null
            : Border.all(color: border, width: AppSizes.hairline * 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.buttonMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: content,
          ),
        ),
      ),
    );

    return AppPressable(
      onTap: enabled ? onPressed : null,
      borderRadius: AppRadius.allMd,
      semanticLabel: semanticLabel ?? label,
      child: body,
    );
  }
}
