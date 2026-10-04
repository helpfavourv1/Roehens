import 'package:roehens/platform/storage/migrations/m001_initial_schema.dart';
import 'package:roehens/platform/storage/migrations/migration.dart';

/// The ordered list of migrations. Later releases append to [standard].
class MigrationRegistry {
  /// Throws [ArgumentError] unless versions run 1, 2, 3 without gaps.
  MigrationRegistry(List<Migration> migrations)
      : _migrations = List<Migration>.unmodifiable(migrations) {
    for (int i = 0; i < _migrations.length; i++) {
      if (_migrations[i].version != i + 1) {
        throw ArgumentError(
          'Migration ${_migrations[i].name} has version '
          '${_migrations[i].version}, expected ${i + 1}',
        );
      }
    }
  }

  /// Every migration of the shipped schema.
  factory MigrationRegistry.standard() {
    return MigrationRegistry(const <Migration>[M001InitialSchema()]);
  }

  final List<Migration> _migrations;

  List<Migration> get all => _migrations;

  /// The schema version a fully migrated database has.
  int get latestVersion => _migrations.isEmpty ? 0 : _migrations.last.version;

  /// Migrations still to run for a database at [fromVersion].
  List<Migration> pending(int fromVersion) {
    return _migrations
        .where((Migration m) => m.version > fromVersion)
        .toList();
  }
}
