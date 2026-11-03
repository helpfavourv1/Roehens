import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A brief white flash over [child] each time [trigger] changes, to confirm a
/// snapshot. With reduced motion there is no flash. It never takes touches.
class SnapshotFlash extends StatefulWidget {
  const SnapshotFlash({super.key, required this.trigger, required this.child});

  /// Increase the value to flash.
  final ValueListenable<int> trigger;
  final Widget child;

  @override
  State<SnapshotFlash> createState() => _SnapshotFlashState();
}

class _SnapshotFlashState extends State<SnapshotFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.tileConnect,
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_flash);
  }

  @override
  void didUpdateWidget(SnapshotFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_flash);
      widget.trigger.addListener(_flash);
    }
  }

  void _flash() {
    if (context.reduceMotion) {
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_flash);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color white = context.colors.onVideoText;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double opacity =
                    (1 - _controller.value) * AppMotion.flashPeakOpacity;
                return ColoredBox(
                  color: white.withValues(
                    alpha: _controller.isAnimating ? opacity : 0,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
