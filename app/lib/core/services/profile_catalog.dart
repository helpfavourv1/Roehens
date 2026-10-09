import 'dart:convert';

import 'package:roehens/core/models/camera_brand_profile.dart';

/// The bundled brand database (`assets/profiles/camera_profiles.json`).
class ProfileCatalog {
  ProfileCatalog._(this.schemaVersion, this.brands);

  /// The newest file format this app understands.
  static const int supportedSchemaVersion = 1;

  /// Reads the database. Throws [FormatException] when the file is not valid, so
  /// a broken asset is caught by the tests rather than by a person.
  factory ProfileCatalog.parse(String text) {
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Profile database is not an object');
    }
    final int version = decoded['schemaVersion'] as int? ?? 0;
    if (version < 1 || version > supportedSchemaVersion) {
      throw FormatException('Unsupported profile schema $version');
    }
    final List<Object?> raw = decoded['brands'] as List<Object?>? ?? const <Object?>[];
    final Set<String> seen = <String>{};
    final List<CameraBrandProfile> brands = <CameraBrandProfile>[];
    for (final Object? item in raw) {
      final CameraBrandProfile brand =
          CameraBrandProfile.fromJson(item! as Map<String, Object?>);
      if (brand.id.isEmpty || !seen.add(brand.id)) {
        throw FormatException('Duplicate or empty brand id "${brand.id}"');
      }
      brands.add(brand);
    }
    brands.sort(
      (CameraBrandProfile a, CameraBrandProfile b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return ProfileCatalog._(version, List<CameraBrandProfile>.unmodifiable(brands));
  }

  final int schemaVersion;

  /// Every brand, alphabetical by display name.
  final List<CameraBrandProfile> brands;

  CameraBrandProfile? byId(String id) {
    for (final CameraBrandProfile brand in brands) {
      if (brand.id == id) {
        return brand;
      }
    }
    return null;
  }

  /// Brands whose name contains [query], ignoring case. An empty query lists all.
  List<CameraBrandProfile> search(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return brands;
    }
    return brands
        .where((CameraBrandProfile b) => b.displayName.toLowerCase().contains(needle))
        .toList();
  }

  /// [brands] under their first letter, for a list with sticky letter headers.
  /// Names that do not start with a letter go under `#`.
  Map<String, List<CameraBrandProfile>> groupedByInitial([String query = '']) {
    final Map<String, List<CameraBrandProfile>> groups =
        <String, List<CameraBrandProfile>>{};
    for (final CameraBrandProfile brand in search(query)) {
      final String first = brand.displayName.isEmpty
          ? '#'
          : brand.displayName.substring(0, 1).toUpperCase();
      final bool isLetter = RegExp(r'^[A-Z]$').hasMatch(first);
      groups.putIfAbsent(isLetter ? first : '#', () => <CameraBrandProfile>[]).add(brand);
    }
    return groups;
  }
}
