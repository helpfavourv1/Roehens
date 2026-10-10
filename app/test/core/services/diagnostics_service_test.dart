import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/services/diagnostics_service.dart';
import 'package:roehens/core/services/redactor.dart';

import '../../support/fakes.dart';

DiagnosticsInput input({
  List<Camera>? cameras,
  List<String>? logs,
  RemoteFlags flags = RemoteFlags.defaults,
}) {
  return DiagnosticsInput(
    appName: 'Roehens',
    version: '1.0.0',
    buildNumber: '7',
    platform: 'Android',
    osVersion: '15',
    deviceModel: 'TestPhone',
    localeCode: 'en',
    settings: const AppSettings(),
    cameras: cameras ?? <Camera>[],
    logLines: logs ?? <String>[],
    storageDegraded: false,
    flags: flags,
    generatedAt: DateTime.utc(2026, 10, 5, 12),
  );
}

void main() {
  const DiagnosticsService service = DiagnosticsService();

  test('describes the app, the device and the settings', () {
    final String text = service.build(input());
    expect(text, contains('Roehens diagnostics'));
    expect(text, contains('generated: 2026-10-05T12:00:00.000Z'));
    expect(text, contains('version: 1.0.0 (7)'));
    expect(text, contains('platform: Android 15'));
    expect(text, contains('device: TestPhone'));
    expect(text, contains('theme: system'));
    expect(text, contains('storage degraded: false'));
    expect(text, contains('none set'));
  });

  test('cameras are described by type only', () {
    final Camera camera = testCamera(id: 'secret-id', name: 'Bedroom cam', host: '203.0.113.9')
        .copyWith(mainPath: '/secret/path?token=abc', brandId: 'hikvision', subPath: '/sub');
    final String text = service.build(input(cameras: <Camera>[camera]));
    expect(text, contains('[cameras: 1]'));
    expect(text, contains('public-ip'));
    expect(text, contains('brand hikvision'));
    expect(text, contains('substream true'));
    for (final String leak in <String>['Bedroom', '203.0.113.9', 'secret', 'token', 'abc']) {
      expect(text.contains(leak), isFalse, reason: leak);
    }
  });

  group('hostKind', () {
    test('tells private, public, hostname and IPv6 apart', () {
      expect(DiagnosticsService.hostKind('192.168.1.5'), 'private-ip');
      expect(DiagnosticsService.hostKind('10.0.0.1'), 'private-ip');
      expect(DiagnosticsService.hostKind('8.8.8.8'), 'public-ip');
      expect(DiagnosticsService.hostKind('my.cam.example'), 'hostname');
      expect(DiagnosticsService.hostKind('fe80::1'), 'ipv6');
    });
  });

  test('credentials in log lines are masked', () {
    const String line = 'opening rtsp://' 'admin:hunter22@10.0.0.5/stream0';
    final String text = service.build(input(logs: <String>[line]));
    expect(text.contains('hunter22'), isFalse);
    expect(text.contains('admin:'), isFalse);
    expect(text, contains('rtsp://***@10.0.0.5/stream0'));
  });

  test('only the newest log lines are kept', () {
    final List<String> logs = <String>[for (int i = 0; i < 500; i++) 'line $i'];
    final String text = const DiagnosticsService(maxLogLines: 50).build(input(logs: logs));
    expect(text, contains('[log: last 50 lines]'));
    expect(text, contains('line 499'));
    expect(text, contains('line 450'));
    expect(text.contains('line 449'), isFalse);
  });

  test('active remote switches are listed', () {
    final String text = service.build(
      input(flags: const RemoteFlags(killSwitches: <String, bool>{'ads': true})),
    );
    expect(text, contains('ads=true'));
  });

  group('Redactor', () {
    test('masks every login in a text', () {
      const String text = 'a http://' 'u:p@h/x and rtsp://' 'a:b@c/d';
      expect(Redactor.redactUrls(text), 'a http://***@h/x and rtsp://***@c/d');
    });

    test('leaves text without logins alone', () {
      const String text = 'rtsp://10.0.0.5:554/stream0 and user@example.com';
      expect(Redactor.redactUrls(text), text);
    });
  });
}
