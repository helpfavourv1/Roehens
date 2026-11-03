import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/platform/storage/secure_vault_service.dart';

import '../../support/fakes.dart';

/// Stands in for the Keychain / Keystore.
class _FakeSecure implements FlutterSecureStorage {
  final Map<String, String> data = <String, String>{};
  bool failing = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final Symbol name = invocation.memberName;
    final Map<Symbol, dynamic> args = invocation.namedArguments;
    if (name == #read) {
      if (failing) {
        return Future<String?>.error(StateError('keystore locked'));
      }
      return Future<String?>.value(data[args[#key]]);
    }
    if (name == #write) {
      if (failing) {
        return Future<void>.error(StateError('keystore locked'));
      }
      data[args[#key] as String] = args[#value] as String;
      return Future<void>.value();
    }
    if (name == #delete) {
      if (failing) {
        return Future<void>.error(StateError('keystore locked'));
      }
      data.remove(args[#key]);
      return Future<void>.value();
    }
    if (name == #deleteAll) {
      if (failing) {
        return Future<void>.error(StateError('keystore locked'));
      }
      data.clear();
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _FakeSecure secure;
  late FakeLogger logger;
  late SecureVaultService vault;

  const CameraCredentials login = CameraCredentials(username: 'admin', password: 's3cret pass/word@');

  setUp(() {
    secure = _FakeSecure();
    logger = FakeLogger();
    vault = SecureVaultService(storage: secure, logger: logger);
  });

  test('stores credentials under the camera key and reads them back', () async {
    await vault.writeCredentials('cam1', login);
    expect((await vault.readCredentials('cam1')).valueOrNull, login);
    expect(secure.data.keys.single, StorageKeys.vaultKeyForCamera('cam1'));
  });

  test('a camera with no credentials reads as null', () async {
    final Result<CameraCredentials?> result = await vault.readCredentials('nobody');
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('credentials of two cameras stay separate', () async {
    await vault.writeCredentials('a', login);
    await vault.writeCredentials('b', const CameraCredentials(username: 'u2', password: 'p2'));
    expect((await vault.readCredentials('a')).valueOrNull?.username, 'admin');
    expect((await vault.readCredentials('b')).valueOrNull?.username, 'u2');
  });

  test('delete removes one camera and deleteAll removes everything', () async {
    await vault.writeCredentials('a', login);
    await vault.writeCredentials('b', login);
    await vault.deleteCredentials('a');
    expect((await vault.readCredentials('a')).valueOrNull, isNull);
    expect((await vault.readCredentials('b')).valueOrNull, login);
    await vault.deleteAll();
    expect(secure.data, isEmpty);
  });

  test('the logger never sees a password or a user name', () async {
    secure.failing = true;
    await vault.writeCredentials('a', login);
    await vault.readCredentials('a');
    await vault.deleteCredentials('a');
    await vault.deleteAll();
    final String logged = logger.entries.map((LogEntry e) => e.toString()).join(' ');
    expect(logged, isNot(contains('s3cret')));
    expect(logged, isNot(contains('admin')));
  });

  test('a locked keystore on write is an error, but the session still has the credentials', () async {
    secure.failing = true;
    final Result<void> written = await vault.writeCredentials('a', login);
    expect(written.errorOrNull?.errorClass, ErrorClass.storageFailure);
    expect((await vault.readCredentials('a')).valueOrNull, login);
  });

  test('a locked keystore on read with nothing cached is a storage failure', () async {
    secure.failing = true;
    final Result<CameraCredentials?> read = await vault.readCredentials('a');
    expect(read.errorOrNull?.errorClass, ErrorClass.storageFailure);
  });

  test('delete and delete all report a failing keystore', () async {
    secure.failing = true;
    expect((await vault.deleteCredentials('a')).errorOrNull?.errorClass, ErrorClass.storageFailure);
    expect((await vault.deleteAll()).errorOrNull?.errorClass, ErrorClass.storageFailure);
  });

  test('a damaged stored value is treated as a failed read', () async {
    secure.data[StorageKeys.vaultKeyForCamera('a')] = 'not json';
    expect((await vault.readCredentials('a')).isErr, isTrue);
    secure.data[StorageKeys.vaultKeyForCamera('b')] = jsonEncode(<String, Object?>{'username': 'u'});
    expect((await vault.readCredentials('b')).isErr, isTrue);
  });

  test('credentials print as redacted', () {
    expect(login.toString(), isNot(contains('s3cret')));
  });
}
