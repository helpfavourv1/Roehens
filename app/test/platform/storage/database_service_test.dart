import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/platform/storage/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fakes.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<DatabaseService> openMemory() async {
    final DatabaseService service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await service.open();
    return service;
  }

  group('real SQLite, in memory', () {
    test('opens cleanly and is not degraded', () async {
      final DatabaseService service = await openMemory();
      expect(service.outcome, StorageOpenOutcome.ok);
      expect(service.isDegraded.value, isFalse);
      await service.close();
    });

    test('saves, updates, orders and deletes cameras', () async {
      final DatabaseService service = await openMemory();
      expect((await service.saveCamera(testCamera(id: 'a', sortIndex: 1))).isOk, isTrue);
      expect((await service.saveCamera(testCamera(id: 'b', sortIndex: 0))).isOk, isTrue);

      List<Camera> loaded = (await service.loadCameras()).valueOrNull!;
      expect(loaded.map((Camera c) => c.id), <String>['b', 'a']);

      await service.saveCamera(testCamera(id: 'a', name: 'Renamed', sortIndex: 1));
      loaded = (await service.loadCameras()).valueOrNull!;
      expect(loaded.length, 2);
      expect(loaded.last.name, 'Renamed');

      await service.saveCameraOrder(<String>['a', 'b']);
      loaded = (await service.loadCameras()).valueOrNull!;
      expect(loaded.map((Camera c) => c.id), <String>['a', 'b']);

      await service.deleteCamera('a');
      loaded = (await service.loadCameras()).valueOrNull!;
      expect(loaded.map((Camera c) => c.id), <String>['b']);
      await service.close();
    });

    test('a camera round trips through the database unchanged', () async {
      final DatabaseService service = await openMemory();
      final Camera camera = testCamera(id: 'x').copyWith(
        subPath: '/sub',
        brandId: 'generic',
        modelHint: 'M1',
        onvifEnabled: true,
        onvifPort: 8080,
      );
      await service.saveCamera(camera);
      final Camera back = (await service.loadCameras()).valueOrNull!.single;
      expect(back, camera);
      await service.close();
    });

    test('updating a camera keeps its stream profiles, deleting removes them', () async {
      final DatabaseService service = await openMemory();
      await service.saveCamera(testCamera(id: 'a'));
      await service.saveStreamProfiles('a', const <StreamProfile>[
        StreamProfile(kind: StreamKind.main, path: '/m', codecHint: 'h265'),
        StreamProfile(kind: StreamKind.sub, path: '/s'),
      ]);

      await service.saveCamera(testCamera(id: 'a', name: 'Changed'));
      expect(
        (await service.loadStreamProfiles('a')).valueOrNull!.length,
        2,
      );

      await service.deleteCamera('a');
      expect((await service.loadStreamProfiles('a')).valueOrNull, isEmpty);
      await service.close();
    });

    test('layouts round trip and delete', () async {
      final DatabaseService service = await openMemory();
      final GridLayout layout = GridLayout.forPageSize(
        id: 'main',
        pageSize: 6,
        cameraIds: <String>['a', 'b'],
        autoCycleSeconds: 15,
      );
      await service.saveLayout(layout);
      await service.saveLayout(layout.copyWith(cameraIds: <String>['b']));
      final List<GridLayout> loaded = (await service.loadLayouts()).valueOrNull!;
      expect(loaded.single.cameraIds, <String>['b']);
      expect(loaded.single.autoCycleSeconds, 15);

      await service.deleteLayout('main');
      expect((await service.loadLayouts()).valueOrNull, isEmpty);
      await service.close();
    });

    test('delete all empties every table', () async {
      final DatabaseService service = await openMemory();
      await service.saveCamera(testCamera(id: 'a'));
      await service.saveLayout(GridLayout.forPageSize(id: 'l', pageSize: 4));
      await service.deleteAll();
      expect((await service.loadCameras()).valueOrNull, isEmpty);
      expect((await service.loadLayouts()).valueOrNull, isEmpty);
      await service.close();
    });
  });

  group('real SQLite, on disk', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('roehens_db_test');
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('data survives closing and reopening', () async {
      final String path = '${dir.path}/app.db';
      final DatabaseService first =
          DatabaseService(factory: databaseFactoryFfi, path: path);
      await first.open();
      await first.saveCamera(testCamera(id: 'keep'));
      await first.close();

      final DatabaseService second =
          DatabaseService(factory: databaseFactoryFfi, path: path);
      await second.open();
      expect(second.outcome, StorageOpenOutcome.ok);
      expect((await second.loadCameras()).valueOrNull!.single.id, 'keep');
      await second.close();
    });

    test('a database from a newer app is refused and left untouched', () async {
      final String path = '${dir.path}/future.db';
      final Database future = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 99),
      );
      await future.close();
      final int sizeBefore = File(path).lengthSync();

      final FakeLogger logger = FakeLogger();
      final DatabaseService service = DatabaseService(
        factory: databaseFactoryFfi,
        path: path,
        logger: logger,
      );
      await service.open();

      expect(service.outcome, StorageOpenOutcome.downgradeRefused);
      expect(service.isDegraded.value, isTrue);
      expect(
        dir.listSync().where((FileSystemEntity e) => e.path.contains('corrupt')),
        isEmpty,
      );
      expect(File(path).lengthSync(), sizeBefore);

      // The app still works for the session, in memory.
      expect((await service.saveCamera(testCamera(id: 'mem'))).isOk, isTrue);
      expect((await service.loadCameras()).valueOrNull!.single.id, 'mem');

      final Database check = await databaseFactoryFfi.openDatabase(path);
      expect(await check.getVersion(), 99);
      await check.close();
    });

    test('a damaged file is moved aside and a clean database is started', () async {
      final String path = '${dir.path}/broken.db';
      File(path).writeAsBytesSync(List<int>.filled(4096, 7));

      final DatabaseService service = DatabaseService(
        factory: databaseFactoryFfi,
        path: path,
        clock: FakeClock(DateTime.utc(2026, 10, 4)),
      );
      await service.open();

      expect(service.outcome, StorageOpenOutcome.quarantined);
      expect(service.isDegraded.value, isTrue);
      expect(
        dir.listSync().where((FileSystemEntity e) => e.path.contains('.corrupt-')),
        isNotEmpty,
      );
      expect((await service.saveCamera(testCamera(id: 'fresh'))).isOk, isTrue);
      expect((await service.loadCameras()).valueOrNull!.single.id, 'fresh');
      await service.close();
    });
  });
}
