import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/secure_vault_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// A camera with sensible defaults for tests.
Camera testCamera({
  String id = 'c1',
  String name = 'Camera',
  int sortIndex = 0,
  String host = '192.168.1.10',
}) {
  return Camera(
    id: id,
    name: name,
    protocol: StreamProtocol.rtsp,
    host: host,
    port: 554,
    mainPath: '/stream0',
    sortIndex: sortIndex,
    createdAt: DateTime.utc(2026, 10, 4),
    updatedAt: DateTime.utc(2026, 10, 4),
  );
}

class FakeClock implements ClockContract {
  FakeClock([DateTime? start]) : time = start ?? DateTime.utc(2026, 10, 4, 12);

  DateTime time;

  @override
  DateTime now() => time;

  void advance(Duration by) => time = time.add(by);
}

class FakeLogger implements LoggerContract {
  final List<LogEntry> _entries = <LogEntry>[];

  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _entries.add(
      LogEntry(
        time: DateTime.utc(2026),
        level: level,
        tag: tag,
        message: message,
      ),
    );
  }

  @override
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  @override
  String dump() => _entries.join('\n');

  @override
  void clear() => _entries.clear();
}

class FakeStorage implements StorageContract {
  final Map<String, Camera> cameras = <String, Camera>{};
  final Map<String, List<StreamProfile>> profiles =
      <String, List<StreamProfile>>{};
  final Map<String, GridLayout> layouts = <String, GridLayout>{};
  final ValueNotifier<bool> degraded = ValueNotifier<bool>(false);

  bool failSaveCamera = false;
  bool failLoad = false;

  static const AppError _failure = AppError(ErrorClass.storageFailure);

  @override
  ValueListenable<bool> get isDegraded => degraded;

  @override
  Future<Result<List<Camera>>> loadCameras() async {
    if (failLoad) {
      return const Err<List<Camera>>(_failure);
    }
    return Ok<List<Camera>>(cameras.values.toList());
  }

  @override
  Future<Result<void>> saveCamera(Camera camera) async {
    if (failSaveCamera) {
      return const Err<void>(_failure);
    }
    cameras[camera.id] = camera;
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> deleteCamera(String id) async {
    cameras.remove(id);
    profiles.remove(id);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> saveCameraOrder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final Camera? camera = cameras[orderedIds[i]];
      if (camera != null) {
        cameras[camera.id] = camera.copyWith(sortIndex: i);
      }
    }
    return const Ok<void>(null);
  }

  @override
  Future<Result<List<StreamProfile>>> loadStreamProfiles(String cameraId) async {
    return Ok<List<StreamProfile>>(profiles[cameraId] ?? <StreamProfile>[]);
  }

  @override
  Future<Result<void>> saveStreamProfiles(
    String cameraId,
    List<StreamProfile> value,
  ) async {
    profiles[cameraId] = value;
    return const Ok<void>(null);
  }

  @override
  Future<Result<List<GridLayout>>> loadLayouts() async {
    return Ok<List<GridLayout>>(layouts.values.toList());
  }

  @override
  Future<Result<void>> saveLayout(GridLayout layout) async {
    layouts[layout.id] = layout;
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> deleteLayout(String id) async {
    layouts.remove(id);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> deleteAll() async {
    cameras.clear();
    profiles.clear();
    layouts.clear();
    return const Ok<void>(null);
  }
}

class FakeVault implements SecureVaultContract {
  final Map<String, CameraCredentials> entries = <String, CameraCredentials>{};
  bool failWrite = false;

  @override
  Future<Result<CameraCredentials?>> readCredentials(String cameraId) async {
    return Ok<CameraCredentials?>(entries[cameraId]);
  }

  @override
  Future<Result<void>> writeCredentials(
    String cameraId,
    CameraCredentials credentials,
  ) async {
    if (failWrite) {
      return const Err<void>(AppError(ErrorClass.storageFailure));
    }
    entries[cameraId] = credentials;
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> deleteCredentials(String cameraId) async {
    entries.remove(cameraId);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> deleteAll() async {
    entries.clear();
    return const Ok<void>(null);
  }
}
