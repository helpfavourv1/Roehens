import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/icons/icon_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Phosphor license reaches the licenses screen', () async {
    registerIconLicense();
    final List<LicenseEntry> entries = await LicenseRegistry.licenses.toList();
    final Iterable<LicenseEntry> phosphor =
        entries.where((LicenseEntry e) => e.packages.contains('Phosphor Icons'));
    expect(phosphor, isNotEmpty);
    final String text = phosphor.first.paragraphs.map((LicenseParagraph p) => p.text).join(' ');
    expect(text.toLowerCase(), contains('mit'));
  });
}
