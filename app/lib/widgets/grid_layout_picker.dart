import 'package:flutter/widgets.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';

/// Chooses how many tiles one page of the Live grid shows: 1, 2, 4, 6, 9, 12
/// or 16. Each option is a pill with a layout icon and its count.
class GridLayoutPicker extends StatelessWidget {
  const GridLayoutPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.labelFor,
    this.sizes = Limits.gridSizes,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  /// The text of an option (the count, in the person's numerals) and also its
  /// spoken label.
  final String Function(int size) labelFor;
  final List<int> sizes;

  /// The icon for a grid size.
  static AppIconName iconFor(int size) {
    return switch (size) {
      1 => AppIconName.layoutGrid1,
      2 => AppIconName.layoutGrid2,
      4 => AppIconName.layoutGrid4,
      6 => AppIconName.layoutGrid6,
      9 => AppIconName.layoutGrid9,
      12 => AppIconName.layoutGrid12,
      _ => AppIconName.layoutGrid16,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final int size in sizes)
          AppChip(
            label: labelFor(size),
            icon: iconFor(size),
            selected: size == selected,
            onTap: () => onSelected(size),
          ),
      ],
    );
  }
}
