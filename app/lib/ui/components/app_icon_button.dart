import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Where the button sits decides its colors.
enum AppIconButtonTone {
  /// On a normal surface.
  neutral,

  /// Chosen or active.
  selected,

  /// Over video: dark plate, white glyph.
  overVideo,
}

/// A 40x40 chip inside a 48x48 hit area. A bare icon is never a control.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = AppIconButtonTone.neutral,
    this.size = AppSizes.iconNavBar,
    this.weight = AppIconWeight.bold,
  });

  final AppIconName icon;

  /// What the button does, for screen readers. Required.
  final String semanticLabel;
  final VoidCallback? onPressed;
  final AppIconButtonTone tone;
  final double size;
  final AppIconWeight weight;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool enabled = onPressed != null;
    final Color plate = switch (tone) {
      AppIconButtonTone.neutral => colors.bgTertiary,
      AppIconButtonTone.selected => colors.accentWash,
      AppIconButtonTone.overVideo => colors.overlayOnVideo,
    };
    Color glyph = switch (tone) {
      AppIconButtonTone.neutral => colors.textPrimary,
      AppIconButtonTone.selected => colors.accent,
      AppIconButtonTone.overVideo => colors.onVideoText,
    };
    if (!enabled) {
      glyph = colors.textTertiary;
    }
    return AppPressable(
      onTap: onPressed,
      borderRadius: AppRadius.allMd,
      semanticLabel: semanticLabel,
      minHitSize: const Size.square(AppSizes.touchTarget),
      child: SizedBox.square(
        dimension: AppSizes.iconChip,
        child: DecoratedBox(
          decoration: BoxDecoration(color: plate, borderRadius: AppRadius.allMd),
          child: Center(
            child: AppIcon(
              icon,
              size: size,
              color: glyph,
              weight: tone == AppIconButtonTone.selected ? AppIconWeight.fill : weight,
            ),
          ),
        ),
      ),
    );
  }
}
