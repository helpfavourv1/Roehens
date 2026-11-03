import 'dart:convert';
import 'dart:typed_data';

import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/core/services/url_builder.dart';

/// What to do with an imported camera that matches one already saved.
enum ImportConflictMode { skip, replace, duplicate }

/// One camera from the file, checked against the saved list.
class ImportItem {
  const ImportItem({required this.camera, this.existing});

  final Camera camera;

  /// The saved camera it matches (same id, or same host, port and path).
  final Camera? existing;

  bool get isConflict => existing != null;
}

/// The file as parsed, before anything is saved.
class ImportPreview {
  const ImportPreview({required this.items, required this.invalidCount});

  final List<ImportItem> items;

  /// Entries in the file that could not be read as a camera.
  final int invalidCount;

  int get newCount => items.where((ImportItem i) => !i.isConflict).length;

  int get conflictCount => items.where((ImportItem i) => i.isConflict).length;
}

class ImportOutcome {
  const ImportOutcome({
    required this.added,
    required this.replaced,
    required this.skipped,
    required this.failed,
  });

  final int added;
  final int replaced;
  final int skipped;
  final int failed;

  /// Some cameras were saved and some were not.
  bool get isPartial => failed > 0 && (added + replaced) > 0;
}

/// Reads a camera export file and saves its cameras. Imported cameras have no
/// credentials; the person adds them on the camera's edit screen.
class CameraImportService {
  CameraImportService({required this._repository});

  final CameraRepository _repository;

  /// Never throws. An unreadable file gives [ErrorClass.invalidFile].
  Result<ImportPreview> parse(Uint8List bytes, List<Camera> existing) {
    if (bytes.isEmpty || bytes.length > Limits.maxImportBytes) {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'file empty or too large'),
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'not JSON'),
      );
    }
    if (decoded is! Map<String, Object?> ||
        decoded['format'] != AppConstants.exportFormatId) {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'not a camera list'),
      );
    }
    final Object? schema = decoded['schemaVersion'];
    if (schema is! int ||
        schema < 1 ||
        schema > AppConstants.exportSchemaVersion) {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'unsupported schema'),
      );
    }
    final Object? rawCameras = decoded['cameras'];
    if (rawCameras is! List<Object?>) {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'no camera list'),
      );
    }

    final List<ImportItem> items = <ImportItem>[];
    int invalid = 0;
    final Set<String> seen = <String>{};
    for (final Object? entry in rawCameras.take(Limits.maxImportCameras)) {
      final Camera? camera = _readCamera(entry);
      if (camera == null || !seen.add(_addressKey(camera))) {
        invalid++;
        continue;
      }
      items.add(ImportItem(camera: camera, existing: _match(camera, existing)));
    }
    invalid += rawCameras.length > Limits.maxImportCameras
        ? rawCameras.length - Limits.maxImportCameras
        : 0;
    if (items.isEmpty) {
      return const Err<ImportPreview>(
        AppError(ErrorClass.invalidFile, detail: 'no usable cameras'),
      );
    }
    return Ok<ImportPreview>(
      ImportPreview(items: items, invalidCount: invalid),
    );
  }

  /// Saves the cameras. A failure on one camera does not stop the rest.
  Future<ImportOutcome> apply(
    ImportPreview preview,
    ImportConflictMode mode,
  ) async {
    int added = 0;
    int replaced = 0;
    int skipped = 0;
    int failed = 0;
    for (final ImportItem item in preview.items) {
      final Camera? existing = item.existing;
      if (existing == null || mode == ImportConflictMode.duplicate) {
        final Result<Camera> result = await _repository.addCamera(
          item.camera,
          CameraCredentials.none,
        );
        result.isOk ? added++ : failed++;
      } else if (mode == ImportConflictMode.skip) {
        skipped++;
      } else {
        final Camera merged = item.camera.copyWith(
          id: existing.id,
          sortIndex: existing.sortIndex,
          createdAt: existing.createdAt,
        );
        // Credentials stay as they are: the file has none to replace them.
        final Result<Camera> result = await _repository.updateCamera(merged);
        result.isOk ? replaced++ : failed++;
      }
    }
    return ImportOutcome(
      added: added,
      replaced: replaced,
      skipped: skipped,
      failed: failed,
    );
  }

  Camera? _readCamera(Object? entry) {
    if (entry is! Map<String, Object?>) {
      return null;
    }
    try {
      final Camera camera = Camera.fromJson(entry);
      final String name = camera.name.trim();
      if (name.isEmpty ||
          name.length > Limits.maxCameraNameLength ||
          !UrlBuilder.isValidHost(camera.host.trim()) ||
          camera.port < Limits.minPort ||
          camera.port > Limits.maxPort) {
        return null;
      }
      return camera.copyWith(
        name: name,
        host: camera.host.trim(),
        mainPath: UrlBuilder.normalizePath(camera.mainPath),
      );
    } on Object {
      // Missing fields, wrong types or an unknown protocol name.
      return null;
    }
  }

  static String _addressKey(Camera camera) {
    return '${camera.protocol.name}|${camera.host.toLowerCase()}|${camera.port}|'
        '${camera.mainPath}';
  }

  static Camera? _match(Camera camera, List<Camera> existing) {
    final String key = _addressKey(camera);
    for (final Camera saved in existing) {
      if (saved.id == camera.id || _addressKey(saved) == key) {
        return saved;
      }
    }
    return null;
  }
}
