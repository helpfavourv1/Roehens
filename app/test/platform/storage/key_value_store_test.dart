import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/platform/storage/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';

/// Stands in for the phone's preference store.
class _FakePrefs implements SharedPreferencesAsync {
  final Map<String, String> data = <String, String>{};
  bool failing = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final Symbol name = invocation.memberName;
    if (name == #getString) {
      if (failing) {
        return Future<String?>.error(StateError('platform store down'));
      }
      return Future<String?>.value(data[invocation.positionalArguments.first]);
    }
    if (name == #setString) {
      if (failing) {
        return Future<void>.error(StateError('platform store down'));
      }
      data[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as String;
      return Future<void>.value();
    }
    if (name == #remove) {
      if (failing) {
        return Future<void>.error(StateError('platform store down'));
      }
      data.remove(invocation.positionalArguments.first);
      return Future<void>.value();
    }
    if (name == #clear) {
      if (failing) {
        return Future<void>.error(StateError('platform store down'));
      }
      data.clear();
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _FakePrefs prefs;
  late FakeLogger logger;
  late SharedPrefsKeyValueStore store;

  setUp(() {
    prefs = _FakePrefs();
    logger = FakeLogger();
    store = SharedPrefsKeyValueStore(prefs: prefs, logger: logger);
  });

  tearDown(() => store.dispose());

  test('stores, reads and removes a value', () async {
    await store.setString('k', 'v');
    expect((await store.getString('k')).valueOrNull, 'v');
    expect(prefs.data['k'], 'v');
    await store.remove('k');
    expect((await store.getString('k')).valueOrNull, isNull);
  });

  test('a missing key is null, not an error', () async {
    final Result<String?> result = await store.getString('nothing');
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('clear removes everything', () async {
    await store.setString('a', '1');
    await store.setString('b', '2');
    await store.clear();
    expect(prefs.data, isEmpty);
  });

  test('is healthy while the platform store works', () async {
    await store.setString('k', 'v');
    expect(store.isDegraded.value, isFalse);
  });

  test('when writing fails the value is kept in memory and the store is marked degraded', () async {
    prefs.failing = true;
    final Result<void> saved = await store.setString('k', 'v');
    expect(saved.isOk, isTrue);
    expect(store.isDegraded.value, isTrue);
    expect((await store.getString('k')).valueOrNull, 'v');
    expect(logger.entries, isNotEmpty);
  });

  test(
    'when reading fails a value written earlier in memory is still found',
    () async {
      prefs.failing = true;
      await store.setString('k', 'v');
      final Result<String?> read = await store.getString('k');
      expect(read.valueOrNull, 'v');
      expect(read.isOk, isTrue);
    },
  );

  test(
    'remove and clear never throw when the platform store is down',
    () async {
      prefs.failing = true;
      expect((await store.remove('k')).isOk, isTrue);
      expect((await store.clear()).isOk, isTrue);
      expect(store.isDegraded.value, isTrue);
    },
  );

  test('clear also forgets the in-memory values', () async {
    prefs.failing = true;
    await store.setString('k', 'v');
    prefs.failing = false;
    await store.clear();
    expect((await store.getString('k')).valueOrNull, isNull);
  });

  test('a value saved after recovery is persisted again', () async {
    prefs.failing = true;
    await store.setString('k', 'old');
    prefs.failing = false;
    await store.setString('k', 'new');
    expect(prefs.data['k'], 'new');
  });
}
