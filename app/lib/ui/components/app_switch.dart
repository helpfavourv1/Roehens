import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// An on/off switch. The thumb slides in the reading direction, so it mirrors
/// in right-to-left languages.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// What the switch controls, for screen readers. Required.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool enabled = onChanged != null;
    final Color track = value
        ? (enabled ? colors.accent : colors.accentWash)
        : colors.bgTertiary;
    final Duration duration = context.motion(AppMotion.press);

    return AppPressable(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: AppRadius.allPill,
      semanticLabel: semanticLabel,
      toggled: value,
      minHitSize: const Size.square(AppSizes.touchTarget),
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.settle,
        width: AppSizes.switchTrackWidth,
        height: AppSizes.switchTrackHeight,
        padding: const EdgeInsets.all(AppSizes.switchThumbInset),
        decoration: BoxDecoration(
          color: track,
          borderRadius: AppRadius.allPill,
          border: Border.all(
            color: value ? track : colors.borderStrong,
            width: AppSizes.hairline * 2,
          ),
        ),
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: SizedBox.square(
          dimension: AppSizes.switchThumb - AppSizes.hairline * 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: value ? colors.onVideoText : colors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
