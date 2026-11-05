import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The Cut, Copy, Paste and Select all bar that appears on a long press in a
/// text field, drawn in the app's own style.
///
/// Flutter's system menu works only on iOS 16 and later, and the stock Android
/// toolbar belongs to Material, which this app does not use, so the app draws
/// its own. The words come from Flutter's translated widget strings, which
/// cover every launch language.
class AppTextSelectionToolbar extends StatelessWidget {
  const AppTextSelectionToolbar({
    super.key,
    required this.anchors,
    required this.items,
  });

  /// Builder for [EditableText.contextMenuBuilder].
  static Widget builder(BuildContext context, EditableTextState state) {
    return AppTextSelectionToolbar(
      anchors: state.contextMenuAnchors,
      items: state.contextMenuButtonItems,
    );
  }

  /// Where the selection is: the toolbar sits above [primaryAnchor], or below
  /// [secondaryAnchor] when there is no room above.
  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;

  static String? _label(
    WidgetsLocalizations words,
    ContextMenuButtonItem item,
  ) {
    return switch (item.type) {
      ContextMenuButtonType.cut => words.cutButtonLabel,
      ContextMenuButtonType.copy => words.copyButtonLabel,
      ContextMenuButtonType.paste => words.pasteButtonLabel,
      ContextMenuButtonType.selectAll => words.selectAllButtonLabel,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final WidgetsLocalizations words = WidgetsLocalizations.of(context);
    final AppTokensData tokens = context.tokens;
    final List<(String, VoidCallback)> buttons = <(String, VoidCallback)>[
      for (final ContextMenuButtonItem item in items)
        if (_label(words, item) != null && item.onPressed != null)
          (_label(words, item)!, item.onPressed!),
    ];
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return TextFieldTapRegion(
      child: CustomSingleChildLayout(
        delegate: _ToolbarLayout(
          primary: anchors.primaryAnchor,
          secondary: anchors.secondaryAnchor ?? anchors.primaryAnchor,
          safe: safe,
        ),
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
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < buttons.length; i++) ...<Widget>[
                  if (i > 0)
                    SizedBox(
                      width: AppSizes.hairline,
                      child: ColoredBox(color: tokens.colors.borderSubtle),
                    ),
                  AppPressable(
                    onTap: buttons[i].$2,
                    style: AppPressStyle.tint,
                    semanticLabel: buttons[i].$1,
                    minHitSize: const Size(
                      AppSizes.touchTarget,
                      AppSizes.touchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          buttons[i].$1,
                          maxLines: 1,
                          style: context.type.callout.copyWith(
                            color: tokens.colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarLayout extends SingleChildLayoutDelegate {
  _ToolbarLayout({
    required this.primary,
    required this.secondary,
    required this.safe,
  });

  final Offset primary;
  final Offset secondary;
  final EdgeInsets safe;

  static const double _gap = AppSpacing.sm;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(
      EdgeInsets.symmetric(horizontal: safe.horizontal / 2 + _gap),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double minX = safe.left + _gap;
    final double maxX = size.width - childSize.width - safe.right - _gap;
    final double x = (primary.dx - childSize.width / 2).clamp(
      minX,
      maxX < minX ? minX : maxX,
    );
    double y = primary.dy - childSize.height - _gap;
    if (y < safe.top + _gap) {
      y = secondary.dy + _gap;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ToolbarLayout oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.safe != safe;
  }
}
