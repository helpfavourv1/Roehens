import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/platform/storage/migrations/migration.dart';
import 'package:roehens/platform/storage/migrations/migration_registry.dart';
import 'package:sqflite/sqflite.dart';

/// How [DatabaseService.open] ended.
enum StorageOpenOutcome {
  notOpened,

  /// Opened normally.
  ok,

  /// The file was damaged. It was renamed and a clean database was started.
  quarantined,

  /// The file belongs to a newer app version. It was left untouched.
  downgradeRefused,

  /// The database could not be used; data lives in memory until the app closes.
  inMemory,
}

/// Raised by the open callback when the file's schema is newer than this app.
class DowngradeRefusedException implements Exception {
  const DowngradeRefusedException(this.fromVersion, this.toVersion);

  final int fromVersion;
  final int toVersion;

  @override
  String toString() => 'DowngradeRefusedException($fromVersion -> $toVersion)';
}

/// SQLite storage for cameras, stream profiles and layouts.
///
/// Rules (specification D2): migrations run on open inside a transaction; a
/// newer file is never modified; a damaged file is renamed and a clean database
/// started; and if nothing works, data is kept in memory with [isDegraded] set
/// so the app shows a warning. No call throws.
class DatabaseService implements StorageContract {
  DatabaseService({
    DatabaseFactory? factory,
    String? path,
    MigrationRegistry? registry,
    LoggerContract? logger,
    ClockContract clock = const SystemClock(),
  })  : _factory = factory,
        _path = path,
        _registry = registry ?? MigrationRegistry.standard(),
        _logger = logger,
        _clock = clock;

  static const String _fileName = 'roehens.db';

  final DatabaseFactory? _factory;
  final String? _path;
  final MigrationRegistry _registry;
  final LoggerContract? _logger;
  final ClockContract _clock;

  final ValueNotifier<bool> _degraded = ValueNotifier<bool>(false);
  StorageOpenOutcome _outcome = StorageOpenOutcome.notOpened;
  Database? _db;

  // Used only when no database could be opened.
  final Map<String, Camera> _memCameras = <String, Camera>{};
  final Map<String, List<StreamProfile>> _memProfiles =
      <String, List<StreamProfile>>{};
  final Map<String, GridLayout> _memLayouts = <String, GridLayout>{};

  @override
  ValueListenable<bool> get isDegraded => _degraded;

  StorageOpenOutcome get outcome => _outcome;

  /// Opens the database. Safe to call once at startup; never throws.
  Future<void> open() async {
    final DatabaseFactory factory = _factory ?? databaseFactory;
    final String dbPath =
        _path ?? p.join(await factory.getDatabasesPath(), _fileName);
    try {
      _db = await _openAt(factory, dbPath);
      _outcome = StorageOpenOutcome.ok;
      return;
    } catch (error) {
      if (_isDowngrade(error)) {
        _logger?.warning('storage', 'database is newer than this app');
        _enterFallback(StorageOpenOutcome.downgradeRefused);
        return;
      }
      _logger?.warning('storage', 'database failed to open', error: error);
    }

    if (dbPath != inMemoryDatabasePath) {
      try {
        await _quarantine(dbPath);
        _db = await _openAt(factory, dbPath);
        _outcome = StorageOpenOutcome.quarantined;
        _degraded.value = true;
        _logger?.warning('storage', 'damaged database moved aside');
        return;
      } catch (error) {
        _logger?.error('storage', 'clean database failed to open', error: error);
      }
    }
    _enterFallback(StorageOpenOutcome.inMemory);
  }

  Future<void> close() async {
    final Database? db = _db;
    _db = null;
    await db?.close();
  }

  void dispose() {
    _degraded.dispose();
  }

  void _enterFallback(StorageOpenOutcome outcome) {
    _db = null;
    _outcome = outcome;
    _degraded.value = true;
  }

  bool _isDowngrade(Object error) {
    return error is DowngradeRefusedException ||
        error.toString().contains('DowngradeRefusedException');
  }

  Future<Database> _openAt(DatabaseFactory factory, String path) async {
    final Database db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _registry.latestVersion,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) => _migrate(db, 0),
        onUpgrade: (Database db, int oldVersion, int newVersion) {
          return _migrate(db, oldVersion);
        },
        onDowngrade: (Database db, int oldVersion, int newVersion) async {
          throw DowngradeRefusedException(oldVersion, newVersion);
        },
      ),
    );
    try {
      final List<Map<String, Object?>> check =
          await db.rawQuery('PRAGMA quick_check');
      final Object? verdict = check.isEmpty ? null : check.first.values.first;
      if (verdict != 'ok') {
        throw StateError('quick_check failed: $verdict');
      }
    } catch (_) {
      await db.close();
      rethrow;
    }
    return db;
  }

  Future<void> _migrate(Database db, int fromVersion) async {
    for (final Migration migration in _registry.pending(fromVersion)) {
      await migration.up(db);
    }
  }

  Future<void> _quarantine(String dbPath) async {
    final String stamp = '${_clock.now().millisecondsSinceEpoch}';
    for (final String suffix in <String>['', '-wal', '-shm', '-journal']) {
      final File file = File('$dbPath$suffix');
      if (await file.exists()) {
        await file.rename('$dbPath$suffix.corrupt-$stamp');
      }
    }
  }

  // ---------------------------------------------------------------- cameras

  @override
  Future<Result<List<Camera>>> loadCameras() {
    return _guard<List<Camera>>(() async {
      final Database? db = _db;
      if (db == null) {
        final List<Camera> list = _memCameras.values.toList()
          ..sort((Camera a, Camera b) => a.sortIndex.compareTo(b.sortIndex));
        return list;
      }
      final List<Map<String, Object?>> rows = await db.query(
        'cameras',
        orderBy: 'sort_index ASC, created_at ASC',
      );
      return rows.map(_cameraFromRow).toList();
    });
  }

  @override
  Future<Result<void>> saveCamera(Camera camera) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        _memCameras[camera.id] = camera;
        return;
      }
      // Update-then-insert, never REPLACE: replacing a row would cascade-delete
      // its stream profiles.
      await db.transaction((Transaction txn) async {
        final Map<String, Object?> row = _cameraToRow(camera);
        final int updated = await txn.update(
          'cameras',
          row,
          where: 'id = ?',
          whereArgs: <Object?>[camera.id],
        );
        if (updated == 0) {
          await txn.insert('cameras', row);
        }
      });
    });
  }

  @override
  Future<Result<void>> deleteCamera(String id) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        _memCameras.remove(id);
        _memProfiles.remove(id);
        return;
      }
      await db.delete('cameras', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  @override
  Future<Result<void>> saveCameraOrder(List<String> orderedIds) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        for (int i = 0; i < orderedIds.length; i++) {
          final Camera? camera = _memCameras[orderedIds[i]];
          if (camera != null) {
            _memCameras[camera.id] = camera.copyWith(sortIndex: i);
          }
        }
        return;
      }
      await db.transaction((Transaction txn) async {
        for (int i = 0; i < orderedIds.length; i++) {
          await txn.update(
            'cameras',
            <String, Object?>{'sort_index': i},
            where: 'id = ?',
            whereArgs: <Object?>[orderedIds[i]],
          );
        }
      });
    });
  }

  // --------------------------------------------------------------- profiles

  @override
  Future<Result<List<StreamProfile>>> loadStreamProfiles(String cameraId) {
    return _guard<List<StreamProfile>>(() async {
      final Database? db = _db;
      if (db == null) {
        return List<StreamProfile>.of(
          _memProfiles[cameraId] ?? const <StreamProfile>[],
        );
      }
      final List<Map<String, Object?>> rows = await db.query(
        'stream_profiles',
        where: 'camera_id = ?',
        whereArgs: <Object?>[cameraId],
        orderBy: 'kind ASC',
      );
      return rows
          .map(
            (Map<String, Object?> row) => StreamProfile(
              kind: StreamKind.values.byName(row['kind']! as String),
              path: row['path']! as String,
              codecHint: row['codec_hint'] as String?,
              resolutionHint: row['resolution_hint'] as String?,
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<void>> saveStreamProfiles(
    String cameraId,
    List<StreamProfile> profiles,
  ) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        _memProfiles[cameraId] = List<StreamProfile>.of(profiles);
        return;
      }
      await db.transaction((Transaction txn) async {
        await txn.delete(
          'stream_profiles',
          where: 'camera_id = ?',
          whereArgs: <Object?>[cameraId],
        );
        for (final StreamProfile profile in profiles) {
          await txn.insert('stream_profiles', <String, Object?>{
            'camera_id': cameraId,
            'kind': profile.kind.name,
            'path': profile.path,
            'codec_hint': profile.codecHint,
            'resolution_hint': profile.resolutionHint,
          });
        }
      });
    });
  }

  // ---------------------------------------------------------------- layouts

  @override
  Future<Result<List<GridLayout>>> loadLayouts() {
    return _guard<List<GridLayout>>(() async {
      final Database? db = _db;
      if (db == null) {
        return _memLayouts.values.toList();
      }
      final List<Map<String, Object?>> rows =
          await db.query('grid_layouts', orderBy: 'id ASC');
      return rows.map((Map<String, Object?> row) {
        final List<Object?> ids =
            jsonDecode(row['camera_ids']! as String) as List<Object?>;
        return GridLayout(
          id: row['id']! as String,
          columns: row['grid_columns']! as int,
          rows: row['grid_rows']! as int,
          cameraIds: ids.map((Object? id) => id! as String).toList(),
          autoCycleSeconds: row['auto_cycle_seconds'] as int?,
        );
      }).toList();
    });
  }

  @override
  Future<Result<void>> saveLayout(GridLayout layout) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        _memLayouts[layout.id] = layout;
        return;
      }
      await db.insert(
        'grid_layouts',
        <String, Object?>{
          'id': layout.id,
          'grid_columns': layout.columns,
          'grid_rows': layout.rows,
          'camera_ids': jsonEncode(layout.cameraIds),
          'auto_cycle_seconds': layout.autoCycleSeconds,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<Result<void>> deleteLayout(String id) {
    return _guardVoid(() async {
      final Database? db = _db;
      if (db == null) {
        _memLayouts.remove(id);
        return;
      }
      await db.delete('grid_layouts', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  @override
  Future<Result<void>> deleteAll() {
    return _guardVoid(() async {
      _memCameras.clear();
      _memProfiles.clear();
      _memLayouts.clear();
      final Database? db = _db;
      if (db == null) {
        return;
      }
      await db.transaction((Transaction txn) async {
        await txn.delete('stream_profiles');
        await txn.delete('grid_layouts');
        await txn.delete('cameras');
      });
    });
  }

  // ---------------------------------------------------------------- helpers

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok<T>(await body());
    } catch (error, stack) {
      return Err<T>(_failure(error, stack));
    }
  }

  Future<Result<void>> _guardVoid(Future<void> Function() body) async {
    try {
      await body();
      return const Ok<void>(null);
    } catch (error, stack) {
      return Err<void>(_failure(error, stack));
    }
  }

  AppError _failure(Object error, StackTrace stack) {
    _logger?.error('storage', 'operation failed', error: error, stackTrace: stack);
    return AppError(ErrorClass.storageFailure, detail: error.runtimeType.toString());
  }

  Map<String, Object?> _cameraToRow(Camera c) {
    return <String, Object?>{
      'id': c.id,
      'name': c.name,
      'protocol': c.protocol.name,
      'host': c.host,
      'port': c.port,
      'main_path': c.mainPath,
      'sub_path': c.subPath,
      'transport': c.transport.name,
      'brand_id': c.brandId,
      'model_hint': c.modelHint,
      'onvif_enabled': c.onvifEnabled ? 1 : 0,
      'onvif_port': c.onvifPort,
      'sort_index': c.sortIndex,
      'created_at': c.createdAt.millisecondsSinceEpoch,
      'updated_at': c.updatedAt.millisecondsSinceEpoch,
    };
  }

  Camera _cameraFromRow(Map<String, Object?> row) {
    return Camera(
      id: row['id']! as String,
      name: row['name']! as String,
      protocol: StreamProtocol.values.byName(row['protocol']! as String),
      host: row['host']! as String,
      port: row['port']! as int,
      mainPath: row['main_path']! as String,
      subPath: row['sub_path'] as String?,
      transport: StreamTransport.values.byName(row['transport']! as String),
      brandId: row['brand_id'] as String?,
      modelHint: row['model_hint'] as String?,
      onvifEnabled: (row['onvif_enabled']! as int) == 1,
      onvifPort: row['onvif_port'] as int?,
      sortIndex: row['sort_index']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
        isUtc: true,
      ),
    );
  }
}
