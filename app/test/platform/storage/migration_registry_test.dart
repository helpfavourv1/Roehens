import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/storage/migrations/migration.dart';
import 'package:roehens/platform/storage/migrations/migration_registry.dart';
import 'package:sqflite/sqflite.dart';

class _Step extends Migration {
  const _Step(this.version);

  @override
  final int version;

  @override
  String get name => 'step$version';

  @override
  Future<void> up(DatabaseExecutor db) async {}
}

void main() {
  test('the shipped registry starts at version 1 and is contiguous', () {
    final MigrationRegistry registry = MigrationRegistry.standard();
    expect(registry.all.first.name, 'm001_initial_schema');
    expect(registry.latestVersion, registry.all.length);
    for (int i = 0; i < registry.all.length; i++) {
      expect(registry.all[i].version, i + 1);
    }
  });

  test('pending lists only the migrations after a version', () {
    final MigrationRegistry registry =
        MigrationRegistry(const <Migration>[_Step(1), _Step(2), _Step(3)]);
    expect(registry.latestVersion, 3);
    expect(registry.pending(0).map((Migration m) => m.version), <int>[1, 2, 3]);
    expect(registry.pending(1).map((Migration m) => m.version), <int>[2, 3]);
    expect(registry.pending(3), isEmpty);
    expect(registry.pending(9), isEmpty);
  });

  test('a gap, a duplicate or a wrong start is rejected', () {
    expect(
      () => MigrationRegistry(const <Migration>[_Step(1), _Step(3)]),
      throwsArgumentError,
    );
    expect(
      () => MigrationRegistry(const <Migration>[_Step(1), _Step(1)]),
      throwsArgumentError,
    );
    expect(
      () => MigrationRegistry(const <Migration>[_Step(2)]),
      throwsArgumentError,
    );
  });

  test('an empty registry has version 0', () {
    expect(MigrationRegistry(const <Migration>[]).latestVersion, 0);
  });
}
