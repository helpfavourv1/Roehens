import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/models/camera.dart';

/// The camera list as written to and read from an export file. Credentials are
/// never part of it: [Camera.toJson] does not contain them.
class CameraExportBundle {
  const CameraExportBundle({
    required this.exportedAt,
    required this.cameras,
    this.appVersion,
    this.schemaVersion = AppConstants.exportSchemaVersion,
  });

  /// Throws [FormatException] when the file is not a Roehens camera export or
  /// comes from a newer schema.
  factory CameraExportBundle.fromJson(Map<String, Object?> json) {
    if (json['format'] != AppConstants.exportFormatId) {
      throw const FormatException('Not a Roehens camera list');
    }
    final int schema = json['schemaVersion'] as int? ?? 0;
    if (schema < 1 || schema > AppConstants.exportSchemaVersion) {
      throw FormatException('Unsupported export schema $schema');
    }
    final List<Object?> rawCameras =
        json['cameras'] as List<Object?>? ?? const <Object?>[];
    return CameraExportBundle(
      schemaVersion: schema,
      appVersion: json['appVersion'] as String?,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(
        json['exportedAtMillis']! as int,
        isUtc: true,
      ),
      cameras: rawCameras
          .map((Object? item) => Camera.fromJson(item! as Map<String, Object?>))
          .toList(),
    );
  }

  final int schemaVersion;
  final String? appVersion;
  final DateTime exportedAt;
  final List<Camera> cameras;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'format': AppConstants.exportFormatId,
      'schemaVersion': schemaVersion,
      'appVersion': appVersion,
      'exportedAtMillis': exportedAt.millisecondsSinceEpoch,
      'cameras': cameras.map((Camera camera) => camera.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is CameraExportBundle &&
        other.schemaVersion == schemaVersion &&
        other.appVersion == appVersion &&
        other.exportedAt == exportedAt &&
        listEquals(other.cameras, cameras);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        appVersion,
        exportedAt,
        Object.hashAll(cameras),
      );
}
