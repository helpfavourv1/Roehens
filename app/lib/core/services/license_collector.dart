import 'package:flutter/foundation.dart';

/// All license texts of one package, without repeats.
class PackageLicense {
  const PackageLicense({required this.name, required this.texts});

  final String name;
  final List<String> texts;
}

/// Reads Flutter's `LicenseRegistry`, which holds the notices of every
/// package in the app, the bundled icon fonts and the engine libraries.
class LicenseCollector {
  LicenseCollector._();

  /// Packages sorted by name (case-insensitive), each with its distinct texts.
  static Future<List<PackageLicense>> collect() async {
    final Map<String, List<String>> byPackage = <String, List<String>>{};
    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      final String text = entry.paragraphs
          .map((LicenseParagraph p) => p.text)
          .join('\n\n')
          .trim();
      if (text.isEmpty) {
        continue;
      }
      for (final String package in entry.packages) {
        final List<String> texts = byPackage.putIfAbsent(
          package,
          () => <String>[],
        );
        if (!texts.contains(text)) {
          texts.add(text);
        }
      }
    }
    final List<PackageLicense> result = <PackageLicense>[
      for (final MapEntry<String, List<String>> e in byPackage.entries)
        PackageLicense(name: e.key, texts: e.value),
    ]..sort(
        (PackageLicense a, PackageLicense b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return result;
  }
}
