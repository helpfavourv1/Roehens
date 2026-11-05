import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Progress that has not finished. A spinner for waiting of unknown length and
/// a thin bar for known progress. There are no skeleton loaders (C1.12).
class AppProgress extends StatefulWidget {
  /// A spinner. Static while the person asked to reduce motion.
  const AppProgress.spinner({
    super.key,
    this.size = AppSizes.spinner,
    this.color,
    this.semanticLabel,
  }) : value = null;

  /// A bar from 0 to 1.
  const AppProgress.bar({
    super.key,
    required double this.value,
    this.semanticLabel,
  }) : size = AppSizes.progressBarHeight,
       color = null;

  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Null for the spinner.
  final double? value;

  bool get isBar => value != null;

  @override
  State<AppProgress> createState() => _AppProgressState();
}

class _AppProgressState extends State<AppProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isBar || context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.color ?? context.colors.accent;
    final double? value = widget.value;
    if (value != null) {
      final double clamped = value.clamp(0, 1);
      return Semantics(
        label: widget.semanticLabel,
        value: '${(clamped * 100).round()}%',
        child: SizedBox(
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.bgTertiary,
              borderRadius: BorderRadius.circular(widget.size),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(widget.size),
                  ),
                  child: SizedBox(height: widget.size),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _SpinnerPainter(
                color: accent,
                turn: _controller.value,
                track: accent.withValues(alpha: AppSizes.spinnerTrackOpacity),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.color,
    required this.turn,
    required this.track,
  });

  final Color color;
  final Color track;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = AppSizes.spinnerStroke;
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(stroke / 2);
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawArc(arcRect, turn * math.pi * 2, math.pi * 1.2, false, arcPaint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) {
    return old.turn != turn || old.color != color || old.track != track;
  }
}
