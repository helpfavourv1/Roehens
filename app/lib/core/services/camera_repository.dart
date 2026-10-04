import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/secure_vault_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';

/// A removed camera with its credentials, held in memory for the undo window.
class DeletedCamera {
  const DeletedCamera({required this.camera, required this.credentials});

  final Camera camera;
  final CameraCredentials credentials;
}

/// Cameras and their credentials as one unit: the database holds the camera, the
/// vault holds the credentials, and this class keeps the two in step.
class CameraRepository {
  CameraRepository({
    required this._storage,
    required this._vault,
    this._clock = const SystemClock(),
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? generateCameraId;

  final StorageContract _storage;
  final SecureVaultContract _vault;
  final ClockContract _clock;
  final String Function() _idGenerator;

  /// All cameras in display order.
  Future<Result<List<Camera>>> loadCameras() async {
    final Result<List<Camera>> loaded = await _storage.loadCameras();
    final List<Camera>? cameras = loaded.valueOrNull;
    if (cameras == null) {
      return loaded;
    }
    final List<Camera> sorted = List<Camera>.of(cameras)
      ..sort((Camera a, Camera b) => a.sortIndex.compareTo(b.sortIndex));
    return Ok<List<Camera>>(sorted);
  }

  /// Adds [draft] at the end of the list with a fresh id and timestamps.
  /// Credentials are written first; if the camera cannot be saved they are
  /// removed again.
  Future<Result<Camera>> addCamera(
    Camera draft,
    CameraCredentials credentials,
  ) async {
    final Result<List<Camera>> existing = await _storage.loadCameras();
    final List<Camera>? cameras = existing.valueOrNull;
    if (cameras == null) {
      return Err<Camera>(existing.errorOrNull!);
    }
    int nextIndex = 0;
    for (final Camera camera in cameras) {
      if (camera.sortIndex >= nextIndex) {
        nextIndex = camera.sortIndex + 1;
      }
    }
    final DateTime now = _clock.now().toUtc();
    final Camera camera = draft.copyWith(
      id: _idGenerator(),
      sortIndex: nextIndex,
      createdAt: now,
      updatedAt: now,
    );

    if (!credentials.isEmpty) {
      final Result<void> written =
          await _vault.writeCredentials(camera.id, credentials);
      if (written.isErr) {
        return Err<Camera>(written.errorOrNull!);
      }
    }
    final Result<void> saved = await _storage.saveCamera(camera);
    if (saved.isErr) {
      await _vault.deleteCredentials(camera.id);
      return Err<Camera>(saved.errorOrNull!);
    }
    return Ok<Camera>(camera);
  }

  /// Saves changes to [camera]. Pass [credentials] to replace the stored ones;
  /// empty credentials remove them; null leaves them untouched.
  Future<Result<Camera>> updateCamera(
    Camera camera, {
    CameraCredentials? credentials,
  }) async {
    final Camera updated = camera.copyWith(updatedAt: _clock.now().toUtc());
    if (credentials != null) {
      final Result<void> vaultResult = credentials.isEmpty
          ? await _vault.deleteCredentials(updated.id)
          : await _vault.writeCredentials(updated.id, credentials);
      if (vaultResult.isErr) {
        return Err<Camera>(vaultResult.errorOrNull!);
      }
    }
    final Result<void> saved = await _storage.saveCamera(updated);
    if (saved.isErr) {
      return Err<Camera>(saved.errorOrNull!);
    }
    return Ok<Camera>(updated);
  }

  /// Removes the camera and its credentials and returns both for undo.
  Future<Result<DeletedCamera>> deleteCamera(String id) async {
    final Result<List<Camera>> loaded = await _storage.loadCameras();
    final List<Camera>? cameras = loaded.valueOrNull;
    if (cameras == null) {
      return Err<DeletedCamera>(loaded.errorOrNull!);
    }
    Camera? target;
    for (final Camera camera in cameras) {
      if (camera.id == id) {
        target = camera;
      }
    }
    if (target == null) {
      return const Err<DeletedCamera>(
        AppError(ErrorClass.storageFailure, detail: 'camera not found'),
      );
    }
    final Result<CameraCredentials?> stored = await _vault.readCredentials(id);
    final CameraCredentials credentials =
        stored.valueOrNull ?? CameraCredentials.none;

    final Result<void> removed = await _storage.deleteCamera(id);
    if (removed.isErr) {
      return Err<DeletedCamera>(removed.errorOrNull!);
    }
    await _vault.deleteCredentials(id);
    return Ok<DeletedCamera>(
      DeletedCamera(camera: target, credentials: credentials),
    );
  }

  /// Puts back a camera removed by [deleteCamera], at its old position.
  Future<Result<Camera>> restoreCamera(DeletedCamera deleted) async {
    if (!deleted.credentials.isEmpty) {
      final Result<void> written = await _vault.writeCredentials(
        deleted.camera.id,
        deleted.credentials,
      );
      if (written.isErr) {
        return Err<Camera>(written.errorOrNull!);
      }
    }
    final Result<void> saved = await _storage.saveCamera(deleted.camera);
    if (saved.isErr) {
      return Err<Camera>(saved.errorOrNull!);
    }
    return Ok<Camera>(deleted.camera);
  }

  Future<Result<void>> reorder(List<String> orderedIds) {
    return _storage.saveCameraOrder(orderedIds);
  }

  /// Stored credentials, or [CameraCredentials.none] when there are none.
  Future<Result<CameraCredentials>> credentialsFor(String cameraId) async {
    final Result<CameraCredentials?> stored =
        await _vault.readCredentials(cameraId);
    final AppError? error = stored.errorOrNull;
    if (error != null) {
      return Err<CameraCredentials>(error);
    }
    return Ok<CameraCredentials>(stored.valueOrNull ?? CameraCredentials.none);
  }

  /// "Delete all local data": cameras, profiles, layouts and credentials.
  Future<Result<void>> deleteAll() async {
    final Result<void> storageResult = await _storage.deleteAll();
    final Result<void> vaultResult = await _vault.deleteAll();
    if (storageResult.isErr) {
      return storageResult;
    }
    return vaultResult;
  }
}
