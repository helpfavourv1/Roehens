import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A horizontal slider for a value between [min] and [max]. It moves in the
/// reading direction, takes arrow keys, and reports through the screen reader
/// as an adjustable value.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
    this.labelBuilder,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String semanticLabel;

  /// Spoken value for a position, for example "4 hours". Defaults to the
  /// percentage of the range.
  final String Function(double value)? labelBuilder;
  final double min;
  final double max;

  /// Steps between [min] and [max]; null is continuous.
  final int? divisions;

  static const double thumbSize = AppSizes.iconNavBar + 4;

  double get _fraction => ((value - min) / (max - min)).clamp(0, 1);

  double _snap(double fraction) {
    final double clamped = fraction.clamp(0, 1);
    final int? steps = divisions;
    final double snapped = steps == null
        ? clamped
        : (clamped * steps).round() / steps;
    return min + snapped * (max - min);
  }

  double get _step => (max - min) / (divisions ?? 20);

  String _label(double at) {
    final String Function(double)? builder = labelBuilder;
    if (builder != null) {
      return builder(at);
    }
    return '${(((at - min) / (max - min)).clamp(0, 1) * 100).round()}%';
  }

  void _move(double next) {
    final double clamped = next.clamp(min, max);
    if (clamped != value) {
      onChanged?.call(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool enabled = onChanged != null;
    final bool rtl = context.isRtl;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double width = box.maxWidth;
        final double travel = width - thumbSize;

        double fractionAt(double dx) {
          final double x = (dx - thumbSize / 2) / travel;
          return rtl ? 1 - x : x;
        }

        final double thumbLeft = (rtl ? 1 - _fraction : _fraction) * travel;
        return Semantics(
          slider: true,
          enabled: enabled,
          label: semanticLabel,
          value: _label(value),
          increasedValue: _label((value + _step).clamp(min, max)),
          decreasedValue: _label((value - _step).clamp(min, max)),
          onIncrease: enabled ? () => _move(value + _step) : null,
          onDecrease: enabled ? () => _move(value - _step) : null,
          child: Focus(
            canRequestFocus: enabled,
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (!enabled || event is KeyUpEvent) {
                return KeyEventResult.ignored;
              }
              final double direction = rtl ? -1 : 1;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _move(value + _step * direction);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _move(value - _step * direction);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: enabled
                  ? (TapDownDetails d) =>
                        onChanged!(_snap(fractionAt(d.localPosition.dx)))
                  : null,
              onHorizontalDragUpdate: enabled
                  ? (DragUpdateDetails d) =>
                        onChanged!(_snap(fractionAt(d.localPosition.dx)))
                  : null,
              onHorizontalDragEnd: enabled
                  ? (_) => onChangeEnd?.call(value)
                  : null,
              onTapUp: enabled ? (_) => onChangeEnd?.call(value) : null,
              child: SizedBox(
                height: AppSizes.touchTarget,
                width: double.infinity,
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: <Widget>[
                    Positioned(
                      left: thumbSize / 2,
                      right: thumbSize / 2,
                      child: SizedBox(
                        height: AppSizes.progressBarHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.bgTertiary,
                            borderRadius: AppRadius.allPill,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: rtl ? thumbLeft + thumbSize / 2 : thumbSize / 2,
                      right: rtl
                          ? thumbSize / 2
                          : travel - thumbLeft + thumbSize / 2,
                      child: SizedBox(
                        height: AppSizes.progressBarHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: enabled
                                ? colors.accent
                                : colors.textTertiary,
                            borderRadius: AppRadius.allPill,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbLeft,
                      child: SizedBox.square(
                        dimension: thumbSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: enabled ? colors.accent : colors.bgTertiary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.bgPrimary,
                              width: AppSizes.focusRing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
