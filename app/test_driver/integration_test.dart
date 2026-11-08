// Host side of `flutter drive`: receives the screenshots the integration test
// takes on the emulator and saves them to app/screenshots/.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final File file = File('screenshots/$name.png')
            ..createSync(recursive: true);
          file.writeAsBytesSync(bytes);
          return true;
        },
  );
}
