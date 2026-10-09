import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/services/profile_catalog.dart';

ProfileCatalog loadBundled() {
  return ProfileCatalog.parse(
    File('assets/profiles/camera_profiles.json').readAsStringSync(),
  );
}

void main() {
  group('the bundled database', () {
    final ProfileCatalog catalog = loadBundled();

    test('is valid and not empty', () {
      expect(catalog.schemaVersion, 1);
      expect(catalog.brands.length, greaterThanOrEqualTo(10));
    });

    test('is sorted by name, ignoring case', () {
      final List<String> names =
          catalog.brands.map((CameraBrandProfile b) => b.displayName.toLowerCase()).toList();
      expect(names, <String>[...names]..sort());
    });

    test('every brand has an id, a name, ports and at least one path', () {
      for (final CameraBrandProfile brand in catalog.brands) {
        expect(brand.id, isNotEmpty);
        expect(brand.displayName, isNotEmpty);
        expect(brand.defaultPorts, isNotEmpty, reason: brand.id);
        for (final int port in brand.defaultPorts) {
          expect(port, inInclusiveRange(1, 65535), reason: brand.id);
        }
        final int paths = brand.mainPathTemplates.length +
            brand.mjpegTemplates.length +
            brand.snapshotTemplates.length;
        expect(paths, greaterThan(0), reason: brand.id);
      }
    });

    test('every path starts with a slash and carries no credentials', () {
      for (final CameraBrandProfile brand in catalog.brands) {
        for (final String path in <String>[
          ...brand.mainPathTemplates,
          ...brand.subPathTemplates,
          ...brand.mjpegTemplates,
          ...brand.snapshotTemplates,
        ]) {
          expect(path, startsWith('/'), reason: '${brand.id} $path');
          expect(path.contains('@'), isFalse, reason: '${brand.id} $path');
          expect(path.toLowerCase().contains('password'), isFalse, reason: '${brand.id} $path');
          expect(path.contains(' '), isFalse, reason: '${brand.id} $path');
        }
      }
    });

    test('only placeholders the builder knows are used', () {
      final RegExp placeholder = RegExp(r'\{([^}]*)\}');
      for (final CameraBrandProfile brand in catalog.brands) {
        for (final String path in <String>[
          ...brand.mainPathTemplates,
          ...brand.subPathTemplates,
          ...brand.mjpegTemplates,
          ...brand.snapshotTemplates,
        ]) {
          for (final RegExpMatch m in placeholder.allMatches(path)) {
            expect(
              <String>{'channel', 'channel0', 'channel2'}.contains(m.group(1)),
              isTrue,
              reason: '${brand.id} $path',
            );
          }
        }
      }
    });

    test('only the confirmed generic entry is marked verified', () {
      final List<String> verified = catalog.brands
          .where((CameraBrandProfile b) => b.verified)
          .map((CameraBrandProfile b) => b.id)
          .toList();
      expect(verified, <String>['generic_stream0']);
    });

    test('the famous brands are present', () {
      for (final String id in <String>[
        'hikvision',
        'dahua',
        'reolink',
        'tapo',
        'axis',
        'generic_rtsp',
        'generic_mjpeg',
      ]) {
        expect(catalog.byId(id), isNotNull, reason: id);
      }
    });
  });

  group('lookups', () {
    final ProfileCatalog catalog = loadBundled();

    test('byId finds a brand and returns null for an unknown one', () {
      expect(catalog.byId('hikvision')!.displayName, 'Hikvision');
      expect(catalog.byId('nope'), isNull);
    });

    test('search ignores case and matches inside the name', () {
      expect(catalog.search('HIK').map((CameraBrandProfile b) => b.id), contains('hikvision'));
      expect(catalog.search('  tapo ').single.id, 'tapo');
      expect(catalog.search('zzz'), isEmpty);
      expect(catalog.search('').length, catalog.brands.length);
    });

    test('grouping uses the first letter', () {
      final Map<String, List<CameraBrandProfile>> groups = catalog.groupedByInitial();
      expect(groups['H']!.map((CameraBrandProfile b) => b.id), contains('hikvision'));
      expect(groups['G']!.length, greaterThanOrEqualTo(3));
      expect(
        groups.values.fold<int>(0, (int sum, List<CameraBrandProfile> l) => sum + l.length),
        catalog.brands.length,
      );
    });

    test('grouping respects the search text', () {
      final Map<String, List<CameraBrandProfile>> groups = catalog.groupedByInitial('ax');
      expect(groups.keys, <String>['A']);
    });
  });

  group('parsing', () {
    String file(Object? brands, {Object? version = 1}) =>
        jsonEncode(<String, Object?>{'schemaVersion': version, 'brands': brands});

    Map<String, Object?> brand(String id) => <String, Object?>{
          'id': id,
          'displayName': id,
          'defaultPorts': <int>[554],
          'mainPathTemplates': <String>['/a'],
        };

    test('a newer file format is refused', () {
      expect(
        () => ProfileCatalog.parse(file(<Object?>[brand('a')], version: 2)),
        throwsFormatException,
      );
      expect(
        () => ProfileCatalog.parse(file(<Object?>[brand('a')], version: 0)),
        throwsFormatException,
      );
    });

    test('duplicate ids are refused', () {
      expect(
        () => ProfileCatalog.parse(file(<Object?>[brand('a'), brand('a')])),
        throwsFormatException,
      );
    });

    test('something that is not an object is refused', () {
      expect(() => ProfileCatalog.parse('[]'), throwsFormatException);
    });

    test('optional lists may be missing', () {
      final ProfileCatalog catalog = ProfileCatalog.parse(file(<Object?>[brand('a')]));
      expect(catalog.brands.single.subPathTemplates, isEmpty);
      expect(catalog.brands.single.verified, isFalse);
    });
  });
}
