import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/icons/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the font manifest contains every icon weight in use', () async {
    final String manifest = await rootBundle.loadString('FontManifest.json');
    for (final String family in AppIcons.fontFamilies) {
      expect(
        manifest,
        contains(family),
        reason: '$family is missing; icons would render as empty boxes',
      );
    }
  });
}
