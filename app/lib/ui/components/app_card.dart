import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The one card: secondary surface, hairline border, large radius, no shadow in
/// either theme. With [onTap] it fades when pressed.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = AppSpacing.allMd,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// Selected cards take the accent wash and the focus border.
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? context.colors.accentWash : context.colors.bgSecondary,
        borderRadius: AppRadius.allLg,
        border: Border.all(
          color: selected ? context.colors.borderFocus : context.colors.borderSubtle,
          width: AppSizes.hairline,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null && onLongPress == null) {
      return card;
    }
    return AppPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppRadius.allLg,
      semanticLabel: semanticLabel,
      selected: selected,
      child: card,
    );
  }
}
