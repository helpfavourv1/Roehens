import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

class AppBottomBarItem {
  const AppBottomBarItem({required this.icon, required this.label, this.badge});

  final AppIconName icon;
  final String label;

  /// A short count or mark shown on the icon.
  final String? badge;
}

/// The main navigation: three or four destinations. The selected one is
/// filled and in the accent color, with its label. The bar is 64 high plus the
/// bottom safe area, which it paints itself so the fill reaches the screen edge.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        border: Border(
          top: BorderSide(color: context.colors.borderSubtle, width: AppSizes.hairline),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: SizedBox(
          height: AppSizes.bottomBarHeight,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _Destination(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({required this.item, required this.selected, required this.onTap});

  final AppBottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? context.colors.accent : context.colors.textTertiary;
    return AppPressable(
      onTap: onTap,
      semanticLabel: item.label,
      selected: selected,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                AppIcon(
                  item.icon,
                  size: AppSizes.iconBottomBar,
                  color: color,
                  weight: selected ? AppIconWeight.fill : AppIconWeight.bold,
                ),
                if (item.badge != null)
                  PositionedDirectional(
                    end: -AppSpacing.md,
                    top: -AppSpacing.xs,
                    child: AppBadge(item.badge!, tone: AppBadgeTone.accent),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: context.clampedTextScaler(max: 1.3),
              style: context.type.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
