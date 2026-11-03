import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// How a pressed element shows it (C6): cards, tiles, buttons and chips fade;
/// rows take a tint. Nothing ripples and nothing scales.
enum AppPressStyle { opacity, tint }

/// The one tap target. Gives press feedback, keyboard activation (Enter and
/// Space), a visible focus ring, and button semantics. Every tappable component
/// is built on this.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.style = AppPressStyle.opacity,
    this.borderRadius = BorderRadius.zero,
    this.minHitSize,
    this.selected,
    this.toggled,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Replaces the spoken label. When set, the child's own semantics are hidden
  /// so the label is not read twice.
  final String? semanticLabel;
  final AppPressStyle style;

  /// Shape of the tint and of the focus ring.
  final BorderRadius borderRadius;

  /// Grows the tappable area around [child] to at least this size.
  final Size? minHitSize;
  final bool? selected;
  final bool? toggled;

  bool get isEnabled => onTap != null || onLongPress != null;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _focused = ValueNotifier<bool>(false);

  static const Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      };

  @override
  void dispose() {
    _pressed.dispose();
    _focused.dispose();
    super.dispose();
  }

  void _setPressed({required bool pressed}) {
    if (widget.isEnabled) {
      _pressed.value = pressed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Duration duration = context.motion(AppMotion.press);

    Widget visual = ValueListenableBuilder<bool>(
      valueListenable: _pressed,
      child: widget.child,
      builder: (BuildContext context, bool pressed, Widget? child) {
        if (widget.style == AppPressStyle.opacity) {
          return AnimatedOpacity(
            opacity: pressed ? AppMotion.pressedOpacity : 1,
            duration: duration,
            curve: AppMotion.settle,
            child: child,
          );
        }
        return AnimatedContainer(
          duration: duration,
          curve: AppMotion.settle,
          decoration: BoxDecoration(
            color: colors.bgTertiary.withValues(alpha: pressed ? 1 : 0),
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
    );

    visual = ValueListenableBuilder<bool>(
      valueListenable: _focused,
      child: visual,
      builder: (BuildContext context, bool focused, Widget? child) {
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: focused
                ? Border.all(
                    color: colors.borderFocus,
                    width: AppSizes.focusRing,
                  )
                : null,
          ),
          child: child,
        );
      },
    );

    final Size? hit = widget.minHitSize;
    if (hit != null) {
      visual = ConstrainedBox(
        constraints: BoxConstraints(minWidth: hit.width, minHeight: hit.height),
        child: Center(widthFactor: 1, heightFactor: 1, child: visual),
      );
    }

    final bool enabled = widget.isEnabled;
    final String? label = widget.semanticLabel;
    return FocusableActionDetector(
      enabled: enabled,
      shortcuts: _shortcuts,
      onShowFocusHighlight: (bool value) => _focused.value = value,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails _) => _setPressed(pressed: true),
        onTapUp: (TapUpDetails _) => _setPressed(pressed: false),
        onTapCancel: () => _setPressed(pressed: false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Semantics(
          container: true,
          button: true,
          enabled: enabled,
          selected: widget.selected,
          toggled: widget.toggled,
          label: label,
          excludeSemantics: label != null,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: visual,
        ),
      ),
    );
  }
}
