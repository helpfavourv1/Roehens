import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/secure_vault_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';

/// Camera credentials in the iOS Keychain or the Android Keystore.
///
/// A failed write is reported as an error so the person is told right away, and
/// the value is kept in memory so the current session still works. Nothing is
/// ever logged except the operation name.
class SecureVaultService implements SecureVaultContract {
  SecureVaultService({FlutterSecureStorage? storage, this._logger})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;
  final LoggerContract? _logger;
  final Map<String, CameraCredentials> _session = <String, CameraCredentials>{};

  @override
  Future<Result<CameraCredentials?>> readCredentials(String cameraId) async {
    try {
      final String? raw =
          await _storage.read(key: StorageKeys.vaultKeyForCamera(cameraId));
      if (raw == null) {
        return Ok<CameraCredentials?>(_session[cameraId]);
      }
      final Object? decoded = jsonDecode(raw);
      return Ok<CameraCredentials?>(
        CameraCredentials.fromJson(decoded! as Map<String, Object?>),
      );
    } catch (_) {
      _logger?.warning('vault', 'read failed');
      final CameraCredentials? cached = _session[cameraId];
      if (cached != null) {
        return Ok<CameraCredentials?>(cached);
      }
      return const Err<CameraCredentials?>(AppError(ErrorClass.storageFailure));
    }
  }

  @override
  Future<Result<void>> writeCredentials(
    String cameraId,
    CameraCredentials credentials,
  ) async {
    _session[cameraId] = credentials;
    try {
      await _storage.write(
        key: StorageKeys.vaultKeyForCamera(cameraId),
        value: jsonEncode(credentials.toJson()),
      );
      return const Ok<void>(null);
    } catch (_) {
      _logger?.warning('vault', 'write failed');
      return const Err<void>(AppError(ErrorClass.storageFailure));
    }
  }

  @override
  Future<Result<void>> deleteCredentials(String cameraId) async {
    _session.remove(cameraId);
    try {
      await _storage.delete(key: StorageKeys.vaultKeyForCamera(cameraId));
      return const Ok<void>(null);
    } catch (_) {
      _logger?.warning('vault', 'delete failed');
      return const Err<void>(AppError(ErrorClass.storageFailure));
    }
  }

  @override
  Future<Result<void>> deleteAll() async {
    _session.clear();
    try {
      await _storage.deleteAll();
      return const Ok<void>(null);
    } catch (_) {
      _logger?.warning('vault', 'delete all failed');
      return const Err<void>(AppError(ErrorClass.storageFailure));
    }
  }
}
