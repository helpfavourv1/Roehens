import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_bottom_bar.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/widgets/camera_grid.dart';
import 'package:roehens/widgets/camera_list_row.dart';
import 'package:roehens/widgets/discovery_result_row.dart';

import '../support/pump_app.dart';

/// One test run per right-to-left language (Arabic, Persian, Urdu, Hebrew).
/// The layout follows the locale's reading direction, so the checks are made
/// with that direction, and the technical values must still read left-to-right.
void main() {
  const List<String> languages = <String>['ar', 'fa', 'ur', 'he'];

  for (final String language in languages) {
    group('right-to-left layout ($language)', () {
      testWidgets('the nav bar puts back at the right and actions at the left', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 400,
            child: AppNavBar(
              title: 'x',
              onBack: () {},
              backLabel: 'Back',
              actions: <Widget>[const SizedBox(key: Key('action'), width: 40, height: 40)],
            ),
          ),
          direction: TextDirection.rtl,
        );
        final Rect back = tester.getRect(find.byType(AppNavBar).first);
        expect(tester.getCenter(find.byKey(const Key('action'))).dx, lessThan(back.center.dx));
      });

      testWidgets('direction-aware icons mirror and physical ones do not', (WidgetTester tester) async {
        await pumpApp(
          tester,
          const Row(children: <Widget>[
            AppIcon(AppIconName.chevronRight, size: 24, color: Color(0xFFFFFFFF)),
            AppIcon(AppIconName.ptzArrowRight, size: 24, color: Color(0xFFFFFFFF)),
          ]),
          direction: TextDirection.rtl,
        );
        final List<Icon> icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
        expect(AppIconName.chevronRight.mirrorsInRtl, isTrue);
        expect(AppIconName.ptzArrowRight.mirrorsInRtl, isFalse);
        // A mirrored icon follows the layout; a physical one is pinned.
        expect(icons.first.textDirection, isNull);
        expect(icons.last.textDirection, TextDirection.ltr);
      });

      testWidgets('an address field stays left-to-right', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 360,
            child: AppTextField(
              controller: TextEditingController(text: 'rtsp://192.168.1.10:554/stream'),
              forceLtr: true,
              monospace: true,
            ),
          ),
          direction: TextDirection.rtl,
        );
        expect(tester.widget<EditableText>(find.byType(EditableText)).textDirection, TextDirection.ltr);
      });

      testWidgets('rows keep addresses left-to-right and put the chevron at the left', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 400,
            child: DiscoveryResultRow(
              title: 'x',
              address: '192.168.1.20:554',
              sourceLabel: 'ONVIF',
              onTap: () {},
            ),
          ),
          direction: TextDirection.rtl,
        );
        final Text address = tester.widget<Text>(find.text('192.168.1.20:554'));
        expect(address.textDirection, TextDirection.ltr);
        expect(tester.getCenter(find.byType(AppIcon).last).dx, lessThan(200));
      });

      testWidgets('the camera list row is mirrored and its address is not', (WidgetTester tester) async {
        await pumpApp(
          tester,
          const SizedBox(
            width: 400,
            child: CameraListRow(
              dismissKey: ValueKey<String>('a'),
              name: 'x',
              address: '10.0.0.7:554',
              protocolLabel: 'RTSP',
            ),
          ),
          direction: TextDirection.rtl,
        );
        expect(tester.widget<Text>(find.text('10.0.0.7:554')).textDirection, TextDirection.ltr);
        expect(tester.widget<Text>(find.text('RTSP')).textDirection, TextDirection.ltr);
        expect(tester.getCenter(find.byType(AppIcon).first).dx, greaterThan(300));
      });

      testWidgets('the bottom bar lists destinations from the right', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 400,
            child: AppBottomBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const <AppBottomBarItem>[
                AppBottomBarItem(icon: AppIconName.cameraDome, label: 'First'),
                AppBottomBarItem(icon: AppIconName.settings, label: 'Second'),
              ],
            ),
          ),
          direction: TextDirection.rtl,
        );
        expect(tester.getCenter(find.text('First')).dx, greaterThan(tester.getCenter(find.text('Second')).dx));
      });

      testWidgets('segments run from the right', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 360,
            child: AppSegmentedControl<int>(
              selected: 1,
              onChanged: (_) {},
              segments: const <AppSegment<int>>[
                AppSegment<int>(value: 1, label: 'One'),
                AppSegment<int>(value: 2, label: 'Two'),
              ],
            ),
          ),
          direction: TextDirection.rtl,
        );
        expect(tester.getCenter(find.text('One')).dx, greaterThan(tester.getCenter(find.text('Two')).dx));
      });

      testWidgets('list rows put the chevron at the end of the reading direction', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(width: 400, child: AppListRow(title: 'Row', onTap: () {})),
          direction: TextDirection.rtl,
        );
        expect(tester.getCenter(find.byType(AppIcon)).dx, lessThan(100));
      });

      testWidgets('the camera grid fills the page from the right', (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 400,
            height: 800,
            child: CameraGrid(
              columns: 2,
              rows: 2,
              tiles: const <Widget>[
                SizedBox.expand(key: Key('first')),
                SizedBox.expand(key: Key('second')),
              ],
            ),
          ),
          direction: TextDirection.rtl,
        );
        expect(
          tester.getCenter(find.byKey(const Key('first'))).dx,
          greaterThan(tester.getCenter(find.byKey(const Key('second'))).dx),
        );
      });
    });
  }
}
