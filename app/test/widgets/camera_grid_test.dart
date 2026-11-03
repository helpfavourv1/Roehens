import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/widgets/camera_grid.dart';
import 'package:roehens/widgets/grid_layout_picker.dart';

import '../support/pump_app.dart';

void main() {
  List<Widget> tiles(int count) => <Widget>[
    for (int i = 0; i < count; i++) SizedBox.expand(key: Key('t$i')),
  ];

  group('CameraGrid', () {
    testWidgets('two by two: equal 16:9 tiles separated by the gutter', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CameraGrid(columns: 2, rows: 2, tiles: tiles(4)),
        ),
      );
      final Rect first = tester.getRect(find.byKey(const Key('t0')));
      final Rect second = tester.getRect(find.byKey(const Key('t1')));
      final Rect third = tester.getRect(find.byKey(const Key('t2')));

      expect(first.width, 198);
      expect(
        first.width / first.height,
        closeTo(AppSizes.tileAspectRatio, 0.01),
      );
      expect(second.left - first.right, 4);
      expect(third.top - first.bottom, 4);
    });

    testWidgets('the block is centered in the height that is left', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CameraGrid(columns: 2, rows: 2, tiles: tiles(4)),
        ),
      );
      final Rect top = tester.getRect(find.byKey(const Key('t0')));
      final Rect bottom = tester.getRect(find.byKey(const Key('t3')));
      expect(top.top, closeTo(800 - bottom.bottom, 1));
    });

    testWidgets('empty slots are left out, not drawn', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CameraGrid(columns: 2, rows: 2, tiles: tiles(3)),
        ),
      );
      expect(
        find
            .byType(SizedBox)
            .evaluate()
            .where((e) => (e.widget as SizedBox).key != null)
            .length,
        3,
      );
      expect(find.byKey(const Key('t3')), findsNothing);
    });

    testWidgets('a single tile takes the full width', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CameraGrid(columns: 1, rows: 1, tiles: tiles(1)),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('t0'))).width, 400);
    });

    testWidgets('a grid taller than the space scrolls', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 150,
          child: CameraGrid(columns: 2, rows: 4, tiles: tiles(8)),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablets use the wider gutter', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 800,
          height: 1000,
          child: CameraGrid(columns: 2, rows: 2, tiles: tiles(4)),
        ),
        size: const Size(800, 1000),
      );
      final Rect first = tester.getRect(find.byKey(const Key('t0')));
      final Rect second = tester.getRect(find.byKey(const Key('t1')));
      expect(second.left - first.right, 8);
    });

    testWidgets('sixteen tiles in four by four fit in a phone page', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: CameraGrid(columns: 4, rows: 4, tiles: tiles(16)),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.getSize(find.byKey(const Key('t0'))).width, closeTo(97, 1));
    });
  });

  group('GridLayoutPicker', () {
    testWidgets('offers every grid size and marks the selected one', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: GridLayoutPicker(
            selected: 4,
            onSelected: (_) {},
            labelFor: (int n) => '$n',
          ),
        ),
      );
      for (final String n in <String>['1', '2', '4', '6', '9', '12', '16']) {
        expect(find.text(n), findsOneWidget);
      }
      final Iterable<AppChip> chips = tester.widgetList<AppChip>(
        find.byType(AppChip),
      );
      expect(chips.where((AppChip c) => c.selected).single.label, '4');
    });

    testWidgets('tapping an option reports its size', (
      WidgetTester tester,
    ) async {
      int? picked;
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          child: GridLayoutPicker(
            selected: 4,
            onSelected: (int n) => picked = n,
            labelFor: (int n) => '$n',
          ),
        ),
      );
      await tester.tap(find.text('9'));
      expect(picked, 9);
    });

    test('every size has its own icon', () {
      final Set<AppIconName> icons = <AppIconName>{
        for (final int n in <int>[1, 2, 4, 6, 9, 12, 16])
          GridLayoutPicker.iconFor(n),
      };
      expect(icons, hasLength(7));
    });
  });
}
