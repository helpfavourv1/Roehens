import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A short message that floats above the bottom bar and goes by itself. With an
/// action it carries a pill (for example Undo). One toast at a time: a new one
/// replaces the old.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static ValueNotifier<bool>? _visible;

  /// True while a toast is on screen.
  static bool get isShowing => _entry != null;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    AppIconName? icon,
    double bottomOffset = AppSizes.bottomBarHeight + AppSpacing.md,
  }) {
    dismiss(immediately: true);
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    final ValueNotifier<bool> visible = ValueNotifier<bool>(false);
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) => _ToastView(
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        bottomOffset: bottomOffset,
        visible: visible,
        onAction: onAction == null
            ? null
            : () {
                dismiss();
                onAction();
              },
      ),
    );
    _entry = entry;
    _visible = visible;
    overlay.insert(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) => visible.value = true);
    _timer = Timer(duration, dismiss);
  }

  /// Fades the toast out; with [immediately] removes it at once.
  static void dismiss({bool immediately = false}) {
    _timer?.cancel();
    _timer = null;
    final OverlayEntry? entry = _entry;
    final ValueNotifier<bool>? visible = _visible;
    _entry = null;
    _visible = null;
    if (entry == null) {
      return;
    }
    if (immediately || visible == null) {
      entry.remove();
      visible?.dispose();
      return;
    }
    visible.value = false;
    Timer(AppMotion.controlsFade, () {
      entry.remove();
      visible.dispose();
    });
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.bottomOffset,
    required this.visible,
  });

  final String message;
  final AppIconName? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double bottomOffset;
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    final AppTokensData tokens = context.tokens;
    final MediaQueryData media = MediaQuery.of(context);
    final double bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + AppSpacing.md
        : media.padding.bottom + bottomOffset;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (BuildContext context, bool shown, Widget? child) {
          return AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: context.motion(AppMotion.controlsFade),
            curve: AppMotion.settle,
            child: child,
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Semantics(
                liveRegion: true,
                container: true,
                label: message,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.colors.bgElevated,
                    borderRadius: AppRadius.allMd,
                    boxShadow: tokens.elevation.pop,
                    border: Border.all(
                      color: tokens.colors.borderStrong,
                      width: AppSizes.hairline,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          AppIcon(
                            icon!,
                            size: AppSizes.iconRowTrailing,
                            color: tokens.colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              message,
                              style: context.type.body.copyWith(
                                color: tokens.colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        if (actionLabel != null &&
                            onAction != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          AppChip(
                            label: actionLabel!,
                            onTap: onAction,
                            selected: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
