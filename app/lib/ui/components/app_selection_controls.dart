import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Selection handles for text fields in an app that does not use Material or
/// Cupertino. The cut/copy/paste bar is drawn by [AppTextSelectionToolbar].
class AppSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  /// Marks each drawn handle, so tests can count them.
  static const Key handleKey = ValueKey<String>('app-selection-handle');

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: SizedBox.square(
        key: handleKey,
        dimension: AppSizes.selectionHandle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // The handle hangs just under the edge of the selection.
    return const Offset(AppSizes.selectionHandle / 2, 0);
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return const Size.square(AppSizes.selectionHandle);
  }
}
