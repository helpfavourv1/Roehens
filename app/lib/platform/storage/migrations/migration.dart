import 'package:sqflite/sqflite.dart';

/// One step of the database schema. Migrations run in order, each inside the
/// transaction sqflite opens for create and upgrade.
abstract class Migration {
  const Migration();

  /// Schema version this migration produces. Versions are 1, 2, 3 without gaps.
  int get version;

  String get name;

  Future<void> up(DatabaseExecutor db);
}
