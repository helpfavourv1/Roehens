import 'package:roehens/core/models/app_settings.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/services/lan_selector.dart';
import 'package:roehens/core/services/redactor.dart';

/// Everything the diagnostics report is built from.
class DiagnosticsInput {
  const DiagnosticsInput({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.localeCode,
    required this.settings,
    required this.cameras,
    required this.logLines,
    required this.storageDegraded,
    required this.flags,
    required this.generatedAt,
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String localeCode;
  final AppSettings settings;
  final List<Camera> cameras;
  final List<String> logLines;
  final bool storageDegraded;
  final RemoteFlags flags;
  final DateTime generatedAt;
}

/// Builds the optional report a person can attach to a feedback mail. It is
/// only built when the person asks. It never contains camera names, addresses,
/// paths or logins: cameras are described by type only.
class DiagnosticsService {
  const DiagnosticsService({this.maxLogLines = 200});

  final int maxLogLines;

  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  /// `private-ip`, `public-ip` or `hostname`: what kind of address a camera has,
  /// without revealing it.
  static String hostKind(String host) {
    final String trimmed = host.trim();
    if (_ipv4.hasMatch(trimmed)) {
      return LanSelector.isPrivateIpv4(trimmed) ? 'private-ip' : 'public-ip';
    }
    if (trimmed.contains(':')) {
      return 'ipv6';
    }
    return 'hostname';
  }

  String build(DiagnosticsInput input) {
    final StringBuffer out = StringBuffer()
      ..writeln('${input.appName} diagnostics')
      ..writeln('generated: ${input.generatedAt.toUtc().toIso8601String()}')
      ..writeln()
      ..writeln('[app]')
      ..writeln('version: ${input.version} (${input.buildNumber})')
      ..writeln('platform: ${input.platform} ${input.osVersion}')
      ..writeln('device: ${input.deviceModel}')
      ..writeln('language: ${input.localeCode}')
      ..writeln('storage degraded: ${input.storageDegraded}')
      ..writeln()
      ..writeln('[settings]')
      ..writeln('theme: ${input.settings.themeMode.name}')
      ..writeln('default transport: ${input.settings.defaultTransport.name}')
      ..writeln('grid substream: ${input.settings.gridSubstreamDefault}')
      ..writeln('keep awake: ${input.settings.keepAwake}')
      ..writeln('auto-cycle: ${input.settings.autoCycleEnabled} '
          '(${input.settings.autoCycleSeconds}s)')
      ..writeln()
      ..writeln('[remote switches]')
      ..writeln(
        input.flags.killSwitches.isEmpty
            ? 'none set'
            : input.flags.killSwitches.entries
                .map((MapEntry<String, bool> e) => '${e.key}=${e.value}')
                .join(', '),
      )
      ..writeln()
      ..writeln('[cameras: ${input.cameras.length}]');
    for (int i = 0; i < input.cameras.length; i++) {
      final Camera c = input.cameras[i];
      out.writeln(
        '#${i + 1} ${c.protocol.name} ${hostKind(c.host)} port ${c.port} '
        'transport ${c.transport.name} brand ${c.brandId ?? '-'} '
        'substream ${c.hasSubstream} onvif ${c.onvifEnabled}',
      );
    }
    final List<String> lines = input.logLines.length > maxLogLines
        ? input.logLines.sublist(input.logLines.length - maxLogLines)
        : input.logLines;
    out
      ..writeln()
      ..writeln('[log: last ${lines.length} lines]');
    for (final String line in lines) {
      out.writeln(Redactor.redactUrls(line));
    }
    return out.toString();
  }
}
