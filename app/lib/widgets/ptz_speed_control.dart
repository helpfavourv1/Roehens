import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_slider.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The PTZ speed: a label and a slider from slow to fast, in ten steps.
class PtzSpeedControl extends StatelessWidget {
  const PtzSpeedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.valueLabelFor,
  });

  static const double minSpeed = 0.1;
  static const double maxSpeed = 1;
  static const int steps = 9;

  final double value;
  final ValueChanged<double> onChanged;

  /// For example "Speed".
  final String label;

  /// Spoken and shown value for a speed; defaults to a percentage.
  final String Function(double speed)? valueLabelFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: context.type.callout.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppSlider(
          value: value,
          min: minSpeed,
          max: maxSpeed,
          divisions: steps,
          onChanged: onChanged,
          semanticLabel: label,
          labelBuilder: valueLabelFor,
        ),
      ],
    );
  }
}
