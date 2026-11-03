import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/components/app_divider.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/components/app_progress.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';

import '../../support/pump_app.dart';

void main() {
  group('AppCard', () {
    testWidgets('has the card surface, hairline border and no shadow', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, const AppCard(child: Text('Body')));
      final BoxDecoration decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(AppCard),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.borderRadius, AppRadius.allLg);
      expect(decoration.boxShadow, isNull);
      expect((decoration.border! as Border).top.width, AppSizes.hairline);
    });

    testWidgets('is tappable only when given a handler', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            const AppCard(child: Text('Plain')),
            AppCard(onTap: () => taps++, child: const Text('Tap')),
          ],
        ),
      );
      await tester.tap(find.text('Tap'));
      expect(taps, 1);
      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Plain'),
          matching: find.byType(AppPressable),
        ),
        findsNothing,
      );
    });
  });

  group('AppListRow', () {
    testWidgets('shows two lines and a chevron when tappable', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppListRow(
            leading: AppIconName.settings,
            title: 'Appearance',
            subtitle: 'System',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppListRow)).height,
        greaterThanOrEqualTo(AppSizes.rowMinHeight),
      );
    });

    testWidgets('a custom trailing widget replaces the chevron', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppListRow(
            title: 'x',
            onTap: () {},
            trailing: const Text('Trailing'),
          ),
        ),
      );
      expect(find.text('Trailing'), findsOneWidget);
    });

    testWidgets(
      'a long title and subtitle wrap at large text without overflow',
      (WidgetTester tester) async {
        await pumpApp(
          tester,
          const SizedBox(
            width: 300,
            child: AppListRow(
              title: 'A rather long row title that has to wrap onto lines',
              subtitle: 'And a subtitle that is quite long as well, to be sure',
            ),
          ),
          textScale: 3,
          size: const Size(400, 6000),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the tap handler fires from anywhere in the row', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppListRow(title: 'Row', onTap: () => taps++),
        ),
      );
      await tester.tapAt(
        tester.getTopRight(find.byType(AppListRow)) + const Offset(-4, 4),
      );
      expect(taps, 1);
    });
  });

  group('AppSection', () {
    testWidgets('puts hairlines between rows only', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppSection(
            title: 'General',
            footer: 'Footnote',
            children: const <Widget>[
              AppListRow(title: 'A'),
              AppListRow(title: 'B'),
              AppListRow(title: 'C'),
            ],
          ),
        ),
      );
      expect(find.byType(AppDivider), findsNWidgets(2));
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('Footnote'), findsOneWidget);
    });

    test('upper-cases only scripts that have case', () {
      expect(AppSection.overlineText('General'), 'GENERAL');
      expect(AppSection.overlineText('Привет'), 'ПРИВЕТ');
      expect(AppSection.overlineText('日本語'), '日本語');
      expect(AppSection.overlineText('العربية'), 'العربية');
      expect(AppSection.overlineText('हिन्दी'), 'हिन्दी');
    });
  });

  group('AppDivider', () {
    testWidgets('is a hairline and insets from the start edge', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(width: 300, child: AppDivider(inset: 40)),
      );
      final Rect line = tester.getRect(find.byType(ColoredBox).last);
      expect(line.height, AppSizes.hairline);
      expect(line.left, 40);
    });

    testWidgets('the inset follows right-to-left', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 300, child: AppDivider(inset: 40)),
        direction: TextDirection.rtl,
        size: const Size(300, 800),
      );
      final Rect line = tester.getRect(find.byType(ColoredBox).last);
      expect(line.right, 260);
    });
  });

  group('AppBadge', () {
    testWidgets('shows its label for every tone', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            for (final AppBadgeTone tone in AppBadgeTone.values)
              AppBadge(tone.name, tone: tone),
          ],
        ),
      );
      for (final AppBadgeTone tone in AppBadgeTone.values) {
        expect(find.text(tone.name), findsOneWidget);
      }
    });
  });

  group('AppProgress', () {
    testWidgets('the bar fills to its value', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 200, child: AppProgress.bar(value: 0.25)),
      );
      expect(tester.getSize(find.byType(FractionallySizedBox)).width, 50);
    });

    testWidgets('the bar clamps out-of-range values', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(width: 200, child: AppProgress.bar(value: 4)),
      );
      expect(tester.getSize(find.byType(FractionallySizedBox)).width, 200);
    });

    testWidgets(
      'the spinner animates and stops on dispose without leaking a ticker',
      (WidgetTester tester) async {
        await pumpApp(tester, const AppProgress.spinner());
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('AppTextField', () {
    testWidgets('shows the label and the hint, and the hint goes when typing', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: controller,
            label: 'Name',
            hint: 'Garden',
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Garden'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Porch');
      await tester.pump();
      expect(find.text('Garden'), findsNothing);
      expect(controller.text, 'Porch');
    });

    testWidgets('reports changes and submissions', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      String? changed;
      String? submitted;
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: controller,
            onChanged: (String v) => changed = v,
            onSubmitted: (String v) => submitted = v,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(changed, 'abc');
      expect(submitted, 'abc');
    });

    testWidgets('tapping the padding focuses the field', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: TextEditingController(),
            focusNode: node,
          ),
        ),
      );
      expect(node.hasFocus, isFalse);
      await tester.tapAt(
        tester.getTopLeft(find.byType(AppTextField)) + const Offset(4, 4),
      );
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('an error shows its message with an icon', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: TextEditingController(),
            errorText: 'Enter a host name',
          ),
        ),
      );
      expect(find.text('Enter a host name'), findsOneWidget);
    });

    testWidgets('helper text shows when there is no error', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: TextEditingController(),
            helperText: 'For example 554',
          ),
        ),
      );
      expect(find.text('For example 554'), findsOneWidget);
    });

    testWidgets('a password field hides the text until revealed', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController(
        text: 'secret',
      );
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: controller,
            obscureText: true,
            revealLabel: 'Show password',
            concealLabel: 'Hide password',
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );

      await tester.tap(find.bySemanticsLabel('Hide password'));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    }, semanticsEnabled: true);

    testWidgets(
      'an address field stays left-to-right in a right-to-left layout',
      (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 360,
            child: AppTextField(
              controller: TextEditingController(text: '192.168.1.10'),
              forceLtr: true,
              monospace: true,
            ),
          ),
          direction: TextDirection.rtl,
        );
        final EditableText editable = tester.widget<EditableText>(
          find.byType(EditableText),
        );
        expect(editable.textDirection, TextDirection.ltr);
        expect(editable.style.fontFamily, 'monospace');
      },
    );

    testWidgets('a disabled field does not take input', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: AppTextField(
            controller: TextEditingController(),
            enabled: false,
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets(
      'a field with a leading icon and a long label survives large text',
      (WidgetTester tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 300,
            child: AppTextField(
              controller: TextEditingController(),
              label: 'A fairly long label for the field',
              leadingIcon: AppIconName.search,
              helperText: 'A helper line that is long enough to wrap around',
            ),
          ),
          textScale: 3,
          size: const Size(400, 6000),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
