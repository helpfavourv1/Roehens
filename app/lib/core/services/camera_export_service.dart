import 'dart:convert';
import 'dart:typed_data';

import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_export_bundle.dart';

/// An export ready to hand to the share sheet.
class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.cameraCount,
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final int cameraCount;
}

/// Writes the camera list as JSON. Credentials are never included: the camera
/// record does not carry them, and the vault is not read here.
class CameraExportService {
  CameraExportService({this._clock = const SystemClock(), this.appVersion});

  static const String mimeType = 'application/json';

  final ClockContract _clock;
  final String? appVersion;

  ExportFile build(List<Camera> cameras) {
    final DateTime now = _clock.now().toUtc();
    final CameraExportBundle bundle = CameraExportBundle(
      exportedAt: now,
      appVersion: appVersion,
      cameras: List<Camera>.unmodifiable(cameras),
    );
    final String text = const JsonEncoder.withIndent('  ')
        .convert(bundle.toJson());
    return ExportFile(
      fileName: fileNameFor(now),
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: mimeType,
      cameraCount: cameras.length,
    );
  }

  /// `roehens-cameras-20261031.json`
  static String fileNameFor(DateTime when) {
    String two(int value) => value.toString().padLeft(2, '0');
    final DateTime utc = when.toUtc();
    final String stamp =
        '${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}${two(utc.day)}';
    return 'roehens-cameras-$stamp.${AppConstants.exportFileExtension}';
  }
}
