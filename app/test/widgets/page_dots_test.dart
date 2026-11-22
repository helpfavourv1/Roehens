import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/widgets/page_dots.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('one page draws nothing', (WidgetTester tester) async {
    await pumpApp(
      tester,
      PageDots(
        count: 1,
        current: 0,
        pageLabel: (int i) => 'Page ${i + 1} of 1',
      ),
    );
    expect(tester.getSize(find.byType(PageDots)), Size.zero);
  });

  testWidgets('announces the page and offers next and previous', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int next = 0;
    int previous = 0;
    await pumpApp(
      tester,
      PageDots(
        count: 3,
        current: 1,
        pageLabel: (int i) => 'Page ${i + 1} of 3',
        onNext: () => next++,
        onPrevious: () => previous++,
      ),
    );

    expect(find.semantics.byValue('Page 2 of 3'), findsOneWidget);
    tester.semantics.performAction(
      find.semantics.byValue('Page 2 of 3'),
      SemanticsAction.increase,
    );
    tester.semantics.performAction(
      find.semantics.byValue('Page 2 of 3'),
      SemanticsAction.decrease,
    );
    expect(next, 1);
    expect(previous, 1);
    semantics.dispose();
  });
}
