import 'dart:typed_data';

import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/contracts/snapshot_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/platform/player/player_pool.dart';

/// Takes a still image from a camera that is playing right now, by asking its
/// session for the current frame.
class FrameCaptureService implements SnapshotContract {
  FrameCaptureService({
    required this.pool,
    this.clock = const SystemClock(),
  });

  final PlayerPool pool;
  final ClockContract clock;

  @override
  Future<Result<SnapshotImage>> capture(String cameraId) async {
    final PlayerSessionContract? session = pool.sessionFor(cameraId)?.session;
    if (session is! FrameCapturable) {
      return const Err<SnapshotImage>(
        AppError(ErrorClass.unsupportedMedia, detail: 'camera is not playing'),
      );
    }
    try {
      final Uint8List? bytes = await session.captureFrame();
      if (bytes == null || bytes.isEmpty) {
        return const Err<SnapshotImage>(
          AppError(ErrorClass.unsupportedMedia, detail: 'no frame available'),
        );
      }
      final VideoSize? size = session.videoSize.value;
      return Ok<SnapshotImage>(
        SnapshotImage(
          bytes: bytes,
          mimeType: 'image/jpeg',
          capturedAt: clock.now(),
          width: size?.width,
          height: size?.height,
        ),
      );
    } catch (error) {
      return Err<SnapshotImage>(
        AppError(ErrorClass.unsupportedMedia, detail: error.runtimeType.toString()),
      );
    }
  }
}
