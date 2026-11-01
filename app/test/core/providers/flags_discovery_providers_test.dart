import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/providers/discovery_provider.dart';
import 'package:roehens/core/providers/flags_provider.dart';

import '../../support/async_helpers.dart';
import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';

void main() {
  group('FlagsProvider', () {
    late FakeFlags source;
    late FlagsProvider flags;

    setUp(() {
      source = FakeFlags();
      flags = FlagsProvider(flags: source);
    });

    tearDown(() => flags.dispose());

    test('everything is on by default', () {
      for (final String key in RemoteFlagKeys.all) {
        expect(flags.isEnabled(key), isTrue);
      }
    });

    test('a switch changed while the app is open reaches the screens', () {
      int changes = 0;
      flags.addListener(() => changes++);
      source.notifier.value = const RemoteFlags(
        killSwitches: <String, bool>{'ptz': true},
        message: 'Paused for maintenance',
      );

      expect(flags.isEnabled(RemoteFlagKeys.ptz), isFalse);
      expect(flags.isEnabled(RemoteFlagKeys.ads), isTrue);
      expect(changes, 1);
      final error = flags.disabledError(RemoteFlagKeys.ptz);
      expect(error.errorClass, ErrorClass.flagDisabled);
      expect(error.detail, 'Paused for maintenance');
    });

    test('refresh asks the service', () async {
      await flags.refresh();
      expect(source.refreshCalls, 1);
    });

    test('compares versions numerically', () {
      expect(FlagsProvider.compareVersions('1.2.10', '1.2.9'), 1);
      expect(FlagsProvider.compareVersions('1.2', '1.2.0'), 0);
      expect(FlagsProvider.compareVersions('0.9.9', '1.0'), -1);
      expect(FlagsProvider.compareVersions('1.0.0+14', '1.0.0'), 0);
      expect(FlagsProvider.compareVersions('2.0.0-beta', '1.9.9'), 1);
    });

    test('an update is required only below the minimum', () {
      expect(flags.isUpdateRequired('0.1.0'), isFalse);
      source.notifier.value = const RemoteFlags(minSupportedVersion: '1.2.0');
      expect(flags.isUpdateRequired('1.1.9'), isTrue);
      expect(flags.isUpdateRequired('1.2.0'), isFalse);
    });
  });

  group('DiscoveryProvider', () {
    late FakeFlags flagSource;
    late FlagsProvider flags;
    late FakeDiscovery discovery;

    const DiscoveryResult sweepHit = DiscoveryResult(
      host: '192.168.1.20',
      port: 554,
      source: DiscoverySource.sweep,
    );
    const DiscoveryResult onvifHit = DiscoveryResult(
      host: '192.168.1.20',
      port: 80,
      source: DiscoverySource.onvif,
      name: 'Porch',
    );

    DiscoveryProvider build({FakePermission? permission}) {
      return DiscoveryProvider(
        discovery: discovery,
        flags: flags,
        logger: FakeLogger(),
        permission: permission,
      );
    }

    setUp(() {
      flagSource = FakeFlags();
      flags = FlagsProvider(flags: flagSource);
      discovery = FakeDiscovery();
    });

    tearDown(() => flags.dispose());

    test('lists finds, shows progress and finishes', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      expect(provider.value.isScanning, isTrue);

      discovery.controller.add(const DiscoveryProgressed(0.4));
      discovery.controller.add(const DiscoveryFound(sweepHit));
      await waitUntil(() => provider.value.results.length == 1);
      expect(provider.value.progress, 0.4);

      discovery.controller.add(const DiscoveryFinished());
      await waitUntil(() => provider.value.status == DiscoveryStatus.done);
      expect(provider.value.progress, 1);
      provider.dispose();
    });

    test('a device found twice is listed once, keeping the ONVIF details', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      discovery.controller.add(const DiscoveryFound(sweepHit));
      discovery.controller.add(const DiscoveryFound(onvifHit));
      discovery.controller.add(const DiscoveryFound(sweepHit));
      await waitUntil(
        () =>
            provider.value.results.isNotEmpty &&
            provider.value.results.first.source == DiscoverySource.onvif,
      );

      expect(provider.value.results, hasLength(1));
      expect(provider.value.results.single.name, 'Porch');
      provider.dispose();
    });

    test('a finished run with no devices reports found nothing', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      discovery.controller.add(const DiscoveryFinished());
      await waitUntil(() => provider.value.foundNothing);
      provider.dispose();
    });

    test('the stream ending also finishes the run', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      await discovery.controller.close();
      await waitUntil(() => provider.value.status == DiscoveryStatus.done);
      provider.dispose();
    });

    test('cancel keeps what was found', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      discovery.controller.add(const DiscoveryFound(sweepHit));
      await waitUntil(() => provider.value.results.isNotEmpty);
      await provider.cancel();

      expect(provider.value.status, DiscoveryStatus.done);
      expect(provider.value.results, hasLength(1));
      provider.dispose();
    });

    test('the kill switch stops the scan before it starts', () async {
      flagSource.notifier.value = const RemoteFlags(
        killSwitches: <String, bool>{'discovery': true},
        message: 'Off for now',
      );
      final DiscoveryProvider provider = build();
      await provider.start();

      expect(provider.value.status, DiscoveryStatus.disabled);
      expect(provider.value.message, 'Off for now');
      expect(discovery.runs, 0);
      provider.dispose();
    });

    test('a refused permission stops the scan', () async {
      final FakePermission permission = FakePermission(
        PermissionStatus.denied,
        afterRequest: PermissionStatus.permanentlyDenied,
      );
      final DiscoveryProvider provider = build(permission: permission);
      await provider.start();

      expect(permission.requests, 1);
      expect(provider.value.status, DiscoveryStatus.permissionDenied);
      expect(discovery.runs, 0);
      provider.dispose();
    });

    test('a granted prompt lets the scan run', () async {
      final FakePermission permission = FakePermission(
        PermissionStatus.denied,
        afterRequest: PermissionStatus.granted,
      );
      final DiscoveryProvider provider = build(permission: permission);
      await provider.start();

      expect(provider.value.isScanning, isTrue);
      provider.dispose();
    });

    test('no permission is needed on Android', () async {
      final DiscoveryProvider provider =
          build(permission: FakePermission(PermissionStatus.notRequired));
      await provider.start();
      expect(provider.value.isScanning, isTrue);
      provider.dispose();
    });

    test('starting twice runs once', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      await provider.start();
      expect(discovery.runs, 1);
      provider.dispose();
    });

    test('clear returns to idle', () async {
      final DiscoveryProvider provider = build();
      await provider.start();
      await provider.cancel();
      provider.clear();
      expect(provider.value.status, DiscoveryStatus.idle);
      provider.dispose();
    });
  });
}
