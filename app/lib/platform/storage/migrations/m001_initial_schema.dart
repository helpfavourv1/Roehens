import 'package:roehens/platform/storage/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Creates the cameras, stream profiles and layouts tables.
class M001InitialSchema extends Migration {
  const M001InitialSchema();

  @override
  int get version => 1;

  @override
  String get name => 'm001_initial_schema';

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE cameras (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  protocol TEXT NOT NULL,
  host TEXT NOT NULL,
  port INTEGER NOT NULL,
  main_path TEXT NOT NULL,
  sub_path TEXT,
  transport TEXT NOT NULL,
  brand_id TEXT,
  model_hint TEXT,
  onvif_enabled INTEGER NOT NULL DEFAULT 0,
  onvif_port INTEGER,
  sort_index INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
    await db.execute(
      'CREATE INDEX idx_cameras_sort_index ON cameras (sort_index)',
    );
    await db.execute('''
CREATE TABLE stream_profiles (
  camera_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  path TEXT NOT NULL,
  codec_hint TEXT,
  resolution_hint TEXT,
  PRIMARY KEY (camera_id, kind),
  FOREIGN KEY (camera_id) REFERENCES cameras (id) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE grid_layouts (
  id TEXT PRIMARY KEY NOT NULL,
  grid_columns INTEGER NOT NULL,
  grid_rows INTEGER NOT NULL,
  camera_ids TEXT NOT NULL,
  auto_cycle_seconds INTEGER
)''');
  }
}
