import 'package:flutter/foundation.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/models/stream_profile.dart';

/// Persistent storage for cameras, their stream profiles and layouts.
///
/// Failures are returned as errors, never thrown. When the database cannot be
/// opened the implementation keeps data in memory and sets [isDegraded], which
/// the app shows as a persistent warning.
abstract interface class StorageContract {
  /// True while data is held in memory only because the database is unusable.
  ValueListenable<bool> get isDegraded;

  Future<Result<List<Camera>>> loadCameras();

  /// Inserts or replaces by id.
  Future<Result<void>> saveCamera(Camera camera);

  Future<Result<void>> deleteCamera(String id);

  /// Writes `sortIndex` for each id in the given order.
  Future<Result<void>> saveCameraOrder(List<String> orderedIds);

  Future<Result<List<StreamProfile>>> loadStreamProfiles(String cameraId);

  Future<Result<void>> saveStreamProfiles(
    String cameraId,
    List<StreamProfile> profiles,
  );

  Future<Result<List<GridLayout>>> loadLayouts();

  Future<Result<void>> saveLayout(GridLayout layout);

  Future<Result<void>> deleteLayout(String id);

  /// Removes every camera, profile and layout.
  Future<Result<void>> deleteAll();
}

/// Small key-value storage for settings and caches.
abstract interface class KeyValueStore {
  Future<Result<String?>> getString(String key);

  Future<Result<void>> setString(String key, String value);

  Future<Result<void>> remove(String key);

  /// Removes everything this app stored.
  Future<Result<void>> clear();
}
