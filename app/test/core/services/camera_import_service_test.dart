import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/camera_export_service.dart';
import 'package:roehens/core/services/camera_import_service.dart';
import 'package:roehens/core/services/camera_repository.dart';

import '../../support/fakes.dart';

void main() {
  late FakeStorage storage;
  late FakeVault vault;
  late CameraRepository repository;
  late CameraImportService service;
  int ids = 0;

  Uint8List fileOf(List<Camera> cameras) {
    return CameraExportService(clock: FakeClock()).build(cameras).bytes;
  }

  Uint8List jsonBytes(Object value) => Uint8List.fromList(utf8.encode(jsonEncode(value)));

  Map<String, Object?> envelope(List<Object?> cameras) {
    return <String, Object?>{
      'format': 'roehens-camera-list',
      'schemaVersion': 1,
      'exportedAtMillis': 1,
      'cameras': cameras,
    };
  }

  setUp(() {
    storage = FakeStorage();
    vault = FakeVault();
    ids = 0;
    repository = CameraRepository(
      storage: storage,
      vault: vault,
      clock: FakeClock(),
      idGenerator: () => 'new${++ids}',
    );
    service = CameraImportService(repository: repository);
  });

  group('parse', () {
    test('rejects files that are not a camera list', () {
      for (final Uint8List bytes in <Uint8List>[
        Uint8List(0),
        Uint8List.fromList(utf8.encode('hello')),
        jsonBytes(<String, Object?>{'format': 'other', 'schemaVersion': 1}),
        jsonBytes(<Object?>[1, 2]),
      ]) {
        final Result<ImportPreview> result = service.parse(bytes, <Camera>[]);
        expect(result.errorOrNull?.errorClass, ErrorClass.invalidFile);
      }
    });

    test('rejects a newer schema and an oversized file', () {
      final Map<String, Object?> newer = envelope(<Object?>[])..['schemaVersion'] = 99;
      expect(
        service.parse(jsonBytes(newer), <Camera>[]).errorOrNull?.errorClass,
        ErrorClass.invalidFile,
      );
      expect(
        service
            .parse(Uint8List(Limits.maxImportBytes + 1), <Camera>[])
            .errorOrNull
            ?.errorClass,
        ErrorClass.invalidFile,
      );
    });

    test('a file with no usable camera is invalid', () {
      final Result<ImportPreview> result =
          service.parse(jsonBytes(envelope(<Object?>[])), <Camera>[]);
      expect(result.errorOrNull?.errorClass, ErrorClass.invalidFile);
    });

    test('reads good cameras and counts the bad ones', () {
      final Map<String, Object?> good = testCamera(id: 'g').toJson();
      final Map<String, Object?> badPort = testCamera(id: 'p').toJson()..['port'] = 0;
      final Map<String, Object?> badHost = testCamera(id: 'h').toJson()
        ..['host'] = 'not a host/';
      final Map<String, Object?> badEnum = testCamera(id: 'e').toJson()
        ..['protocol'] = 'carrierpigeon';
      final Result<ImportPreview> result = service.parse(
        jsonBytes(
          envelope(<Object?>[good, badPort, badHost, badEnum, 'junk', null]),
        ),
        <Camera>[],
      );
      final ImportPreview preview = result.valueOrNull!;

      expect(preview.items, hasLength(1));
      expect(preview.invalidCount, 5);
    });

    test('flags a camera that matches a saved one by address', () {
      final Camera saved = testCamera(id: 'saved', host: '192.168.1.50');
      final Camera incoming = testCamera(id: 'other-id', host: '192.168.1.50');
      final ImportPreview preview =
          service.parse(fileOf(<Camera>[incoming]), <Camera>[saved]).valueOrNull!;

      expect(preview.conflictCount, 1);
      expect(preview.items.single.existing, saved);
    });

    test('flags a camera that matches a saved one by id', () {
      final Camera saved = testCamera(id: 'same', host: '192.168.1.50');
      final Camera incoming = testCamera(id: 'same', host: '192.168.1.99');
      final ImportPreview preview =
          service.parse(fileOf(<Camera>[incoming]), <Camera>[saved]).valueOrNull!;

      expect(preview.conflictCount, 1);
    });

    test('drops a duplicate entry inside the file', () {
      final ImportPreview preview = service
          .parse(
            fileOf(<Camera>[testCamera(id: 'a'), testCamera(id: 'b')]),
            <Camera>[],
          )
          .valueOrNull!;

      expect(preview.items, hasLength(1));
      expect(preview.invalidCount, 1);
    });
  });

  group('apply', () {
    Future<ImportPreview> previewWithConflict() async {
      final Camera saved = (await repository.addCamera(
        testCamera(name: 'Old name', host: '10.0.0.5'),
        const CameraCredentials(username: 'admin', password: 'keep-me'),
      ))
          .valueOrNull!;
      final List<Camera> incoming = <Camera>[
        testCamera(id: 'x1', name: 'New name', host: '10.0.0.5'),
        testCamera(id: 'x2', name: 'Fresh', host: '10.0.0.6'),
      ];
      return service
          .parse(fileOf(incoming), <Camera>[saved])
          .valueOrNull!;
    }

    test('skip adds new cameras and leaves matches alone', () async {
      final ImportPreview preview = await previewWithConflict();
      final ImportOutcome outcome =
          await service.apply(preview, ImportConflictMode.skip);

      expect(outcome.added, 1);
      expect(outcome.skipped, 1);
      expect(outcome.replaced, 0);
      final List<Camera> all = (await repository.loadCameras()).valueOrNull!;
      expect(all, hasLength(2));
      expect(all.first.name, 'Old name');
    });

    test('replace updates the match and keeps its credentials', () async {
      final ImportPreview preview = await previewWithConflict();
      final ImportOutcome outcome =
          await service.apply(preview, ImportConflictMode.replace);

      expect(outcome.replaced, 1);
      expect(outcome.added, 1);
      final List<Camera> all = (await repository.loadCameras()).valueOrNull!;
      expect(all.first.name, 'New name');
      expect(all.first.id, 'new1');
      expect(vault.entries['new1']?.password, 'keep-me');
    });

    test('duplicate adds the match as a second camera', () async {
      final ImportPreview preview = await previewWithConflict();
      final ImportOutcome outcome =
          await service.apply(preview, ImportConflictMode.duplicate);

      expect(outcome.added, 2);
      expect((await repository.loadCameras()).valueOrNull, hasLength(3));
    });

    test('imported cameras get no credentials', () async {
      final ImportPreview preview = service
          .parse(fileOf(<Camera>[testCamera(id: 'n')]), <Camera>[])
          .valueOrNull!;
      await service.apply(preview, ImportConflictMode.skip);

      expect(vault.entries, isEmpty);
    });
  });
}
