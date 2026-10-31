import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/services/flag_service.dart';

import '../../support/fakes.dart';

void main() {
  final Uri url = Uri.parse('https://example.test/flags.json');
  late FakeKeyValueStore store;
  late FakeClock clock;
  late int fetchCount;

  String flagsJson({bool ptzOff = false, String? message}) {
    return jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'killSwitches': <String, Object?>{'ptz': ptzOff, 'unknownFuture': true},
      'message': message,
    });
  }

  FlagService build({
    required Future<String> Function() fetch,
    Uri? flagsUrl,
  }) {
    return FlagService(
      store: store,
      clock: clock,
      logger: FakeLogger(),
      url: flagsUrl ?? url,
      fetcher: (Uri _, Duration __) {
        fetchCount++;
        return fetch();
      },
    );
  }

  setUp(() {
    store = FakeKeyValueStore();
    clock = FakeClock();
    fetchCount = 0;
  });

  test('starts with everything on', () {
    final FlagService service = build(fetch: () async => flagsJson());
    expect(service.flags.value, RemoteFlags.defaults);
    expect(service.flags.value.isOff(RemoteFlagKeys.ptz), isFalse);
  });

  test('a fetched file is applied and cached; unknown switches are ignored',
      () async {
    final FlagService service =
        build(fetch: () async => flagsJson(ptzOff: true, message: 'maintenance'));
    await service.refresh();

    expect(service.flags.value.isOff(RemoteFlagKeys.ptz), isTrue);
    expect(service.flags.value.message, 'maintenance');
    expect(service.flags.value.killSwitches.containsKey('unknownFuture'), isFalse);
    expect(store.values[StorageKeys.flagsCache], isNotNull);
    expect(store.values[StorageKeys.flagsFetchedAtMillis], isNotNull);
  });

  test('a failed fetch keeps the cached flags', () async {
    store.values[StorageKeys.flagsCache] = flagsJson(ptzOff: true);
    final FlagService service =
        build(fetch: () async => throw Exception('offline'));
    await service.refresh();

    expect(service.flags.value.isOff(RemoteFlagKeys.ptz), isTrue);
  });

  test('a failed fetch with no cache leaves the defaults', () async {
    final FlagService service =
        build(fetch: () async => throw Exception('offline'));
    await service.refresh();

    expect(service.flags.value, RemoteFlags.defaults);
  });

  test('an invalid file is ignored and does not replace the cache', () async {
    store.values[StorageKeys.flagsCache] = flagsJson(ptzOff: true);
    final FlagService service = build(fetch: () async => '<html>not json</html>');
    await service.refresh();

    expect(service.flags.value.isOff(RemoteFlagKeys.ptz), isTrue);
    expect(store.values[StorageKeys.flagsCache], flagsJson(ptzOff: true));
  });

  test('a corrupt cache is ignored', () async {
    store.values[StorageKeys.flagsCache] = '{{{';
    final FlagService service =
        build(fetch: () async => throw Exception('offline'));
    await service.refresh();

    expect(service.flags.value, RemoteFlags.defaults);
  });

  test('without a url the network is never used', () async {
    final FlagService service = FlagService(
      store: store,
      clock: clock,
      logger: FakeLogger(),
      fetcher: (Uri _, Duration __) async {
        fetchCount++;
        return flagsJson();
      },
    );
    await service.refresh();

    expect(fetchCount, 0);
  });

  test('a plain http url is refused', () async {
    final FlagService service = build(
      fetch: () async => flagsJson(),
      flagsUrl: Uri.parse('http://example.test/flags.json'),
    );
    await service.refresh();

    expect(fetchCount, 0);
  });

  test('resume skips a recheck made moments ago, then allows one later',
      () async {
    final FlagService service = build(fetch: () async => flagsJson());
    await service.refresh();
    expect(fetchCount, 1);

    clock.advance(const Duration(minutes: 1));
    await service.onResume();
    expect(fetchCount, 1);

    clock.advance(Limits.flagsResumeMinInterval);
    await service.onResume();
    expect(fetchCount, 2);
  });

  test('listeners are told when the flags change', () async {
    final FlagService service =
        build(fetch: () async => flagsJson(ptzOff: true));
    int notifications = 0;
    service.flags.addListener(() => notifications++);
    await service.refresh();

    expect(notifications, 1);
  });
}
