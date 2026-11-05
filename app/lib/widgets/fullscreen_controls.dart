import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// One round button on the fullscreen controls.
class FullscreenAction {
  const FullscreenAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final AppIconName icon;

  /// What the button does, for screen readers.
  final String label;
  final VoidCallback? onPressed;

  /// For toggles such as mute and PTZ.
  final bool selected;
}

/// Controls laid over fullscreen video: a top row with close, the camera name
/// and actions, and a bottom row of actions, plus an optional [panel] such as
/// the PTZ pad. They fade out after three seconds without a touch and come back
/// on a tap. They stay visible while a screen reader is on. Escape closes.
class FullscreenControls extends StatefulWidget {
  const FullscreenControls({
    super.key,
    required this.child,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    this.statusPill,
    this.topActions = const <FullscreenAction>[],
    this.bottomActions = const <FullscreenAction>[],
    this.panel,
    this.onActivity,
  });

  /// The video.
  final Widget child;
  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  final Widget? statusPill;
  final List<FullscreenAction> topActions;
  final List<FullscreenAction> bottomActions;

  /// Shown above the bottom row while the controls are visible.
  final Widget? panel;

  /// Called for every touch, so auto-cycle can wait.
  final VoidCallback? onActivity;

  @override
  State<FullscreenControls> createState() => _FullscreenControlsState();
}

class _FullscreenControlsState extends State<FullscreenControls> {
  final ValueNotifier<bool> _shown = ValueNotifier<bool>(true);
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _restartIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _shown.dispose();
    super.dispose();
  }

  void _restartIdle() {
    _idle?.cancel();
    _idle = Timer(AppMotion.controlsIdle, () {
      if (mounted && !MediaQuery.accessibleNavigationOf(context)) {
        _shown.value = false;
      }
    });
  }

  void _activity() {
    widget.onActivity?.call();
    if (_shown.value) {
      _restartIdle();
    }
  }

  void _toggle() {
    _shown.value = !_shown.value;
    if (_shown.value) {
      _restartIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Duration fade = context.motion(AppMotion.controlsFade);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent _) {
              widget.onClose();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _activity(),
            onPointerMove: (_) => _activity(),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: widget.child,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _shown,
                  builder: (BuildContext context, bool shown, Widget? child) {
                    return IgnorePointer(
                      ignoring: !shown,
                      child: AnimatedOpacity(
                        opacity: shown ? 1 : 0,
                        duration: fade,
                        curve: AppMotion.settle,
                        child: child,
                      ),
                    );
                  },
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: <Widget>[
                          _topRow(context),
                          const Spacer(),
                          if (widget.panel != null)
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: widget.panel,
                            ),
                          if (widget.panel != null)
                            const SizedBox(height: AppSpacing.sm),
                          _bottomRow(),
                        ],
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
  }

  Widget _topRow(BuildContext context) {
    return Row(
      children: <Widget>[
        AppIconButton(
          icon: AppIconName.close,
          semanticLabel: widget.closeLabel,
          tone: AppIconButtonTone.overVideo,
          onPressed: widget.onClose,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.title2.copyWith(
                color: context.colors.onVideoText,
              ),
            ),
          ),
        ),
        if (widget.statusPill != null) ...<Widget>[
          widget.statusPill!,
          const SizedBox(width: AppSpacing.sm),
        ],
        for (final FullscreenAction action in widget.topActions)
          _button(action),
      ],
    );
  }

  Widget _bottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final FullscreenAction action in widget.bottomActions) ...<Widget>[
          _button(action),
          const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _button(FullscreenAction action) {
    return AppIconButton(
      icon: action.icon,
      semanticLabel: action.label,
      tone: action.selected
          ? AppIconButtonTone.overVideoSelected
          : AppIconButtonTone.overVideo,
      onPressed: action.onPressed,
    );
  }
}
