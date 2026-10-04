import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/camera_repository.dart';

import '../../support/fakes.dart';

void main() {
  late FakeStorage storage;
  late FakeVault vault;
  late FakeClock clock;
  late CameraRepository repository;
  int idCounter = 0;

  setUp(() {
    storage = FakeStorage();
    vault = FakeVault();
    clock = FakeClock();
    idCounter = 0;
    repository = CameraRepository(
      storage: storage,
      vault: vault,
      clock: clock,
      idGenerator: () => 'id${++idCounter}',
    );
  });

  const CameraCredentials login =
      CameraCredentials(username: 'admin', password: 'pw12345');

  test('adding assigns id, position and timestamps and stores credentials', () async {
    final Camera first = (await repository.addCamera(testCamera(), login)).valueOrNull!;
    final Camera second = (await repository.addCamera(testCamera(), login)).valueOrNull!;

    expect(first.id, 'id1');
    expect(second.id, 'id2');
    expect(first.sortIndex, 0);
    expect(second.sortIndex, 1);
    expect(first.createdAt, clock.time);
    expect(vault.entries['id1'], login);
    expect(storage.cameras.length, 2);
  });

  test('a camera without credentials writes nothing to the vault', () async {
    await repository.addCamera(testCamera(), CameraCredentials.none);
    expect(vault.entries, isEmpty);
  });

  test('credentials are rolled back when the camera cannot be saved', () async {
    storage.failSaveCamera = true;
    final result = await repository.addCamera(testCamera(), login);
    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.errorClass, ErrorClass.storageFailure);
    expect(vault.entries, isEmpty);
  });

  test('a failed credential write stops the add', () async {
    vault.failWrite = true;
    final result = await repository.addCamera(testCamera(), login);
    expect(result.isErr, isTrue);
    expect(storage.cameras, isEmpty);
  });

  test('loading returns display order', () async {
    storage.cameras['b'] = testCamera(id: 'b', sortIndex: 1);
    storage.cameras['a'] = testCamera(id: 'a', sortIndex: 0);
    final List<Camera> loaded = (await repository.loadCameras()).valueOrNull!;
    expect(loaded.map((Camera c) => c.id), <String>['a', 'b']);
  });

  test('a storage failure while loading is reported', () async {
    storage.failLoad = true;
    expect((await repository.loadCameras()).isErr, isTrue);
  });

  test('updating bumps the timestamp and leaves credentials alone by default', () async {
    final Camera added = (await repository.addCamera(testCamera(), login)).valueOrNull!;
    clock.advance(const Duration(minutes: 5));

    final Camera updated =
        (await repository.updateCamera(added.copyWith(name: 'Porch'))).valueOrNull!;
    expect(updated.name, 'Porch');
    expect(updated.updatedAt, clock.time);
    expect(updated.createdAt, added.createdAt);
    expect(vault.entries[added.id], login);
  });

  test('updating can replace or remove credentials', () async {
    final Camera added = (await repository.addCamera(testCamera(), login)).valueOrNull!;
    const CameraCredentials other =
        CameraCredentials(username: 'user', password: 'other-pw');

    await repository.updateCamera(added, credentials: other);
    expect(vault.entries[added.id], other);

    await repository.updateCamera(added, credentials: CameraCredentials.none);
    expect(vault.entries.containsKey(added.id), isFalse);
  });

  test('delete returns camera and credentials, and restore puts them back', () async {
    final Camera added = (await repository.addCamera(testCamera(), login)).valueOrNull!;

    final DeletedCamera deleted =
        (await repository.deleteCamera(added.id)).valueOrNull!;
    expect(deleted.camera, added);
    expect(deleted.credentials, login);
    expect(storage.cameras, isEmpty);
    expect(vault.entries, isEmpty);

    final Camera restored = (await repository.restoreCamera(deleted)).valueOrNull!;
    expect(restored, added);
    expect(storage.cameras[added.id], added);
    expect(vault.entries[added.id], login);
  });

  test('deleting an unknown camera is an error', () async {
    expect((await repository.deleteCamera('nope')).isErr, isTrue);
  });

  test('reorder writes the new positions', () async {
    final Camera a = (await repository.addCamera(testCamera(), login)).valueOrNull!;
    final Camera b = (await repository.addCamera(testCamera(), login)).valueOrNull!;
    await repository.reorder(<String>[b.id, a.id]);
    final List<Camera> loaded = (await repository.loadCameras()).valueOrNull!;
    expect(loaded.map((Camera c) => c.id), <String>[b.id, a.id]);
  });

  test('credentialsFor returns none when nothing is stored', () async {
    final CameraCredentials found =
        (await repository.credentialsFor('missing')).valueOrNull!;
    expect(found.isEmpty, isTrue);
  });

  test('delete all clears cameras and credentials', () async {
    await repository.addCamera(testCamera(), login);
    expect((await repository.deleteAll()).isOk, isTrue);
    expect(storage.cameras, isEmpty);
    expect(vault.entries, isEmpty);
  });
}
