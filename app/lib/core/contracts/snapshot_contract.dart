import 'dart:typed_data';

import 'package:roehens/core/errors/result.dart';

/// One captured still image.
class SnapshotImage {
  const SnapshotImage({
    required this.bytes,
    required this.mimeType,
    required this.capturedAt,
    this.width,
    this.height,
  });

  /// Encoded image data, for example JPEG.
  final Uint8List bytes;
  final String mimeType;
  final DateTime capturedAt;
  final int? width;
  final int? height;
}

/// Captures a still from a camera: the decoded frame when a session is playing,
/// otherwise a fetch of the camera's HTTP snapshot address.
abstract interface class SnapshotContract {
  Future<Result<SnapshotImage>> capture(String cameraId);
}
