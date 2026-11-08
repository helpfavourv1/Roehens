import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final AppIconName? icon;
}

/// Two to four choices side by side, one selected. Segments share the width
/// equally and grow in height when long labels wrap.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Above this text scale, three or more segments are stacked.
  static const double stackAtTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    // Three or more segments side by side cannot hold large text without
    // breaking words, so at large sizes they stack, one per line.
    final bool stacked =
        segments.length > 2 &&
        MediaQuery.textScalerOf(context).scale(1) > stackAtTextScale;
    Widget segment(AppSegment<T> item) {
      return _Segment<T>(
        segment: item,
        isSelected: item.value == selected,
        onTap: () => onChanged(item.value),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: AppRadius.allMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final AppSegment<T> item in segments) segment(item),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final AppSegment<T> item in segments)
                      Expanded(child: segment(item)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final AppSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color foreground = isSelected ? colors.accent : colors.textSecondary;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      semanticLabel: segment.label,
      selected: isSelected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? colors.bgElevated
              : colors.bgTertiary.withValues(alpha: 0),
          borderRadius: AppRadius.allSm,
          border: isSelected
              ? Border.all(color: colors.borderSubtle, width: AppSizes.hairline)
              : null,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.segmentedHeight,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (segment.icon != null) ...<Widget>[
                  AppIcon(
                    segment.icon!,
                    size: AppSizes.iconChipGlyph,
                    color: foreground,
                    weight: isSelected
                        ? AppIconWeight.fill
                        : AppIconWeight.bold,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    segment.label,
                    textAlign: TextAlign.center,
                    style: context.type.callout.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
