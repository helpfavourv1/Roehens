import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Lays out one page of tiles in [columns] by [rows]. Tiles are 16:9 and share
/// the width equally; the block is centered in the height that is left, so a
/// two-by-two grid on a tall phone sits in the middle, not stuck to the top.
/// A page with fewer tiles than slots leaves the empty slots out entirely.
/// When the rows do not fit in the height, the grid scrolls.
class CameraGrid extends StatelessWidget {
  const CameraGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.tiles,
    this.gutter,
  });

  final int columns;
  final int rows;
  final List<Widget> tiles;

  /// Defaults to 4 on phones and 8 on tablets.
  final double? gutter;

  @override
  Widget build(BuildContext context) {
    final double gap = gutter ?? context.gridGutter;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double tileWidth = (box.maxWidth - gap * (columns - 1)) / columns;
        final double tileHeight = tileWidth / AppSizes.tileAspectRatio;
        final int usedRows = (tiles.length / columns).ceil().clamp(1, rows);
        final double blockHeight = usedRows * tileHeight + (usedRows - 1) * gap;

        final List<Widget> rowWidgets = <Widget>[];
        for (int row = 0; row < usedRows; row++) {
          final List<Widget> cells = <Widget>[];
          for (int col = 0; col < columns; col++) {
            final int index = row * columns + col;
            if (index >= tiles.length) {
              break;
            }
            if (col > 0) {
              cells.add(SizedBox(width: gap));
            }
            cells.add(SizedBox(width: tileWidth, height: tileHeight, child: tiles[index]));
          }
          if (row > 0) {
            rowWidgets.add(SizedBox(height: gap));
          }
          rowWidgets.add(Row(children: cells));
        }
        final Widget block = Column(mainAxisSize: MainAxisSize.min, children: rowWidgets);

        final bool fits = !box.hasBoundedHeight || blockHeight <= box.maxHeight;
        if (fits && box.hasBoundedHeight) {
          return SizedBox(height: box.maxHeight, child: Center(child: block));
        }
        return SingleChildScrollView(child: block);
      },
    );
  }
}
