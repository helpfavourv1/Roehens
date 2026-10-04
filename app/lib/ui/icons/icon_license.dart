import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the Phosphor Icons license to Flutter's license registry so it appears
/// on the licenses screen. Called once at startup.
void registerIconLicense() {
  LicenseRegistry.addLicense(_phosphorLicense);
}

Stream<LicenseEntry> _phosphorLicense() async* {
  final String text =
      await rootBundle.loadString('assets/fonts/LICENSE-phosphor.txt');
  yield LicenseEntryWithLineBreaks(<String>['Phosphor Icons'], text);
}
