import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/core/services/camera_repository.dart';

import '../../support/fakes.dart';

void main() {
  late FakeStorage storage;
  late FakeVault vault;
  late CamerasProvider provider;
  int ids = 0;

  const CameraCredentials login =
      CameraCredentials(username: 'admin', password: 'pw12345');

  setUp(() {
    storage = FakeStorage();
    vault = FakeVault();
    ids = 0;
    provider = CamerasProvider(
      repository: CameraRepository(
        storage: storage,
        vault: vault,
        clock: FakeClock(),
        idGenerator: () => 'id${++ids}',
      ),
    );
  });

  tearDown(() => provider.dispose());

  test('is not loaded until the first load finishes', () async {
    expect(provider.value.isLoaded, isFalse);
    await provider.load();
    expect(provider.value.isLoaded, isTrue);
    expect(provider.value.isEmpty, isTrue);
  });

  test('a failed load keeps what is shown and reports the error', () async {
    await provider.add(testCamera(), login);
    storage.failLoad = true;
    await provider.load();

    expect(provider.value.isLoaded, isTrue);
    expect(provider.value.error?.errorClass, ErrorClass.storageFailure);
    expect(provider.value.cameras, hasLength(1));
  });

  test('adding shows the camera at the end', () async {
    await provider.add(testCamera(name: 'A'), login);
    await provider.add(testCamera(name: 'B'), CameraCredentials.none);

    expect(provider.value.cameras.map((Camera c) => c.name), <String>['A', 'B']);
    expect(provider.value.byId('id1')?.name, 'A');
    expect(provider.value.byId('missing'), isNull);
  });

  test('a failed add shows nothing new', () async {
    storage.failSaveCamera = true;
    final Result<Camera> result = await provider.add(testCamera(), login);

    expect(result.isErr, isTrue);
    expect(provider.value.cameras, isEmpty);
  });

  test('editing updates the list and can replace credentials', () async {
    final Camera saved = (await provider.add(testCamera(name: 'Old'), login)).valueOrNull!;
    await provider.update(
      saved.copyWith(name: 'New'),
      credentials: const CameraCredentials(username: 'u', password: 'p'),
    );

    expect(provider.value.byId(saved.id)?.name, 'New');
    expect(vault.entries[saved.id]?.password, 'p');
  });

  test('delete then restore brings back the camera and its credentials', () async {
    final Camera saved = (await provider.add(testCamera(), login)).valueOrNull!;
    final DeletedCamera deleted = (await provider.delete(saved.id)).valueOrNull!;

    expect(provider.value.cameras, isEmpty);
    expect(vault.entries, isEmpty);

    await provider.restore(deleted);
    expect(provider.value.cameras, hasLength(1));
    expect(vault.entries[saved.id], login);
  });

  test('reorder shows the new order and saves it', () async {
    await provider.add(testCamera(name: 'A'), login);
    await provider.add(testCamera(name: 'B'), login);
    await provider.add(testCamera(name: 'C'), login);

    await provider.reorder(<String>['id3', 'id1', 'id2']);

    expect(
      provider.value.cameras.map((Camera c) => c.name),
      <String>['C', 'A', 'B'],
    );
    await provider.load();
    expect(
      provider.value.cameras.map((Camera c) => c.name),
      <String>['C', 'A', 'B'],
    );
  });

  test('reorder keeps cameras that were left out of the list', () async {
    await provider.add(testCamera(name: 'A'), login);
    await provider.add(testCamera(name: 'B'), login);
    await provider.reorder(<String>['id2']);

    expect(provider.value.cameras.map((Camera c) => c.name), <String>['B', 'A']);
  });

  test('delete all empties the list', () async {
    await provider.add(testCamera(), login);
    await provider.deleteAll();
    expect(provider.value.cameras, isEmpty);
    expect(vault.entries, isEmpty);
  });

  group('filter', () {
    final List<Camera> cameras = <Camera>[
      testCamera(id: 'a', name: 'Front Door', host: '192.168.1.10'),
      testCamera(id: 'b', name: 'Garage', host: '10.0.0.7'),
      testCamera(id: 'c', name: 'Yard', host: 'cam.example.org')
          .copyWith(modelHint: 'DS-2CD'),
    ];

    test('empty text shows everything', () {
      expect(CamerasProvider.filter(cameras, '  '), cameras);
    });

    test('matches name, host and model without regard to case', () {
      expect(CamerasProvider.filter(cameras, 'door').single.id, 'a');
      expect(CamerasProvider.filter(cameras, '10.0.0').single.id, 'b');
      expect(CamerasProvider.filter(cameras, 'ds-2cd').single.id, 'c');
    });

    test('no match gives an empty list', () {
      expect(CamerasProvider.filter(cameras, 'zzz'), isEmpty);
    });
  });
}
