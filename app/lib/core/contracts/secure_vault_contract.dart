import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';

/// Credentials storage backed by the iOS Keychain or the Android Keystore.
/// Credentials are keyed by camera id and exist nowhere else.
abstract interface class SecureVaultContract {
  /// Null when the camera has no stored credentials.
  Future<Result<CameraCredentials?>> readCredentials(String cameraId);

  Future<Result<void>> writeCredentials(
    String cameraId,
    CameraCredentials credentials,
  );

  Future<Result<void>> deleteCredentials(String cameraId);

  /// Removes every stored credential.
  Future<Result<void>> deleteAll();
}
