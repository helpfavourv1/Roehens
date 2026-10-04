import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';

/// Pan, tilt and zoom through the camera's ONVIF PTZ service.
abstract interface class PtzContract {
  /// Whether the camera reports a usable PTZ service.
  Future<Result<bool>> supportsPtz({
    required Camera camera,
    required CameraCredentials credentials,
  });

  Future<Result<void>> execute({
    required Camera camera,
    required CameraCredentials credentials,
    required PtzCommand command,
  });
}
