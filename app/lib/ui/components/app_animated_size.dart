import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Animates its own height or width when its child changes size (the ad slot,
/// the bottom stack, a warning banner).
///
/// With animations switched off in the phone's accessibility settings the
/// framework's [AnimatedSize] must not be used at all: with a zero duration it
/// notifies in the middle of its own layout, which is an error in debug builds
/// and a layout glitch in release builds. The child is shown as it is instead.
class AppAnimatedSize extends StatelessWidget {
  const AppAnimatedSize({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final Duration duration = context.motion(AppMotion.adSlot);
    if (duration == Duration.zero) {
      return child;
    }
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.settle,
      alignment: alignment,
      child: child,
    );
  }
}
