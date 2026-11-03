import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/camera_export_bundle.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/models/stream_profile.dart';

import '../../support/fakes.dart';

/// Sends a model through real JSON text, the way storage and files do.
Map<String, Object?> viaJson(Map<String, Object?> json) {
  return jsonDecode(jsonEncode(json)) as Map<String, Object?>;
}

void main() {
  group('DiscoveryResult', () {
    test('round-trips with every field', () {
      const DiscoveryResult result = DiscoveryResult(
        host: '192.168.1.20',
        port: 80,
        source: DiscoverySource.onvif,
        name: 'Porch',
        model: 'DS-2CD',
        scopes: <String>['onvif://www.onvif.org/name/Porch'],
        xaddrs: <String>['http://192.168.1.20/onvif/device_service'],
      );
      final DiscoveryResult back = DiscoveryResult.fromJson(
        viaJson(result.toJson()),
      );
      expect(back, result);
      expect(back.hashCode, result.hashCode);
    });

    test('optional fields may be missing', () {
      final DiscoveryResult back = DiscoveryResult.fromJson(
        viaJson(<String, Object?>{
          'host': '10.0.0.5',
          'port': 554,
          'source': 'sweep',
        }),
      );
      expect(back.name, isNull);
      expect(back.scopes, isEmpty);
      expect(back.source, DiscoverySource.sweep);
    });

    test('differs by any field', () {
      const DiscoveryResult base = DiscoveryResult(
        host: 'a',
        port: 1,
        source: DiscoverySource.sweep,
      );
      expect(
        base,
        isNot(
          const DiscoveryResult(
            host: 'b',
            port: 1,
            source: DiscoverySource.sweep,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const DiscoveryResult(
            host: 'a',
            port: 2,
            source: DiscoverySource.sweep,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const DiscoveryResult(
            host: 'a',
            port: 1,
            source: DiscoverySource.onvif,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const DiscoveryResult(
            host: 'a',
            port: 1,
            source: DiscoverySource.sweep,
            name: 'n',
          ),
        ),
      );
    });

    test('an unknown source name is rejected', () {
      expect(
        () => DiscoveryResult.fromJson(<String, Object?>{
          'host': 'a',
          'port': 1,
          'source': 'bluetooth',
        }),
        throwsArgumentError,
      );
    });
  });

  group('StreamProfile', () {
    test('round-trips and copies', () {
      const StreamProfile profile = StreamProfile(
        kind: StreamKind.sub,
        path: '/stream2',
        codecHint: 'h264',
        resolutionHint: '640x360',
      );
      expect(StreamProfile.fromJson(viaJson(profile.toJson())), profile);
      expect(profile.copyWith(path: '/other').path, '/other');
      expect(profile.copyWith(path: '/other').kind, StreamKind.sub);
      expect(profile.copyWith(kind: StreamKind.main).kind, StreamKind.main);
      expect(profile, isNot(profile.copyWith(path: '/other')));
      expect(
        profile.hashCode,
        const StreamProfile(
          kind: StreamKind.sub,
          path: '/stream2',
          codecHint: 'h264',
          resolutionHint: '640x360',
        ).hashCode,
      );
    });
  });

  group('ConnectionTestResult', () {
    const StageResult ok = StageResult(
      stage: TestStage.dns,
      status: StageStatus.passed,
      elapsedMillis: 5,
    );
    const StageResult bad = StageResult(
      stage: TestStage.tcp,
      status: StageStatus.failed,
      detail: 'refused',
    );

    test('passes only when something passed and nothing failed', () {
      expect(
        const ConnectionTestResult(stages: <StageResult>[ok]).passed,
        isTrue,
      );
      expect(
        const ConnectionTestResult(stages: <StageResult>[ok, bad]).passed,
        isFalse,
      );
      expect(
        const ConnectionTestResult(stages: <StageResult>[]).passed,
        isFalse,
      );
      expect(
        const ConnectionTestResult(
          stages: <StageResult>[
            StageResult(stage: TestStage.dns, status: StageStatus.pending),
          ],
        ).passed,
        isFalse,
      );
      expect(
        const ConnectionTestResult(
          stages: <StageResult>[ok],
          error: AppError(ErrorClass.authFailed),
        ).passed,
        isFalse,
      );
    });

    test('finds the first failed stage', () {
      const ConnectionTestResult result = ConnectionTestResult(
        stages: <StageResult>[ok, bad],
      );
      expect(result.firstFailure, bad);
      expect(
        const ConnectionTestResult(stages: <StageResult>[ok]).firstFailure,
        isNull,
      );
    });

    test('compares stages, error and suggestions', () {
      const ConnectionTestResult a = ConnectionTestResult(
        stages: <StageResult>[ok],
        suggestionKeys: <String>['checkWifi'],
      );
      const ConnectionTestResult b = ConnectionTestResult(
        stages: <StageResult>[ok],
        suggestionKeys: <String>['checkWifi'],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ConnectionTestResult(stages: <StageResult>[bad])));
      expect(ok, isNot(bad));
      expect(
        ok.hashCode,
        const StageResult(
          stage: TestStage.dns,
          status: StageStatus.passed,
          elapsedMillis: 5,
        ).hashCode,
      );
    });
  });

  group('PtzCommand', () {
    test('a continuous move is clamped to the allowed range', () {
      final PtzCommand command = PtzCommand.continuous(
        pan: 3,
        tilt: -3,
        zoom: 0.4,
        speed: 9,
      );
      expect(command.pan, 1);
      expect(command.tilt, -1);
      expect(command.zoom, 0.4);
      expect(command.speed, 1);
      expect(PtzCommand.continuous(speed: -1).speed, 0);
    });

    test('every kind round-trips through JSON', () {
      final List<PtzCommand> commands = <PtzCommand>[
        PtzCommand.continuous(pan: 0.5, tilt: -0.25, zoom: 1, speed: 0.75),
        const PtzCommand.stop(),
        const PtzCommand.home(),
        const PtzCommand.preset('preset-3'),
      ];
      for (final PtzCommand command in commands) {
        final PtzCommand back = PtzCommand.fromJson(viaJson(command.toJson()));
        expect(back, command);
        expect(back.hashCode, command.hashCode);
        expect(back.kind, command.kind);
      }
      expect(const PtzCommand.preset('p').presetToken, 'p');
    });

    test('commands of different kinds are different', () {
      expect(const PtzCommand.stop(), isNot(const PtzCommand.home()));
      expect(const PtzCommand.preset('a'), isNot(const PtzCommand.preset('b')));
      expect(
        PtzCommand.continuous(pan: 0.5),
        isNot(PtzCommand.continuous(pan: 0.6)),
      );
    });
  });

  group('CameraBrandProfile', () {
    const CameraBrandProfile profile = CameraBrandProfile(
      id: 'hikvision',
      displayName: 'Hikvision',
      defaultPorts: <int>[554, 8000],
      mainPathTemplates: <String>['/Streaming/Channels/{channel}01'],
      subPathTemplates: <String>['/Streaming/Channels/{channel}02'],
      mjpegTemplates: <String>[
        '/ISAPI/Streaming/channels/{channel}01/httppreview',
      ],
      snapshotTemplates: <String>[
        '/ISAPI/Streaming/channels/{channel}01/picture',
      ],
      notes: 'Digest authentication',
      verified: true,
    );

    test('round-trips through JSON text', () {
      final CameraBrandProfile back = CameraBrandProfile.fromJson(
        viaJson(profile.toJson()),
      );
      expect(back, profile);
      expect(back.hashCode, profile.hashCode);
    });

    test('missing lists are empty and verified defaults to false', () {
      final CameraBrandProfile back = CameraBrandProfile.fromJson(
        <String, Object?>{'id': 'x', 'displayName': 'X'},
      );
      expect(back.defaultPorts, isEmpty);
      expect(back.mainPathTemplates, isEmpty);
      expect(back.verified, isFalse);
      expect(back.notes, isNull);
    });

    test('differs by id and by verified flag', () {
      final CameraBrandProfile other = CameraBrandProfile.fromJson(
        <String, Object?>{...profile.toJson(), 'verified': false},
      );
      expect(other, isNot(profile));
    });
  });

  group('RemoteFlags', () {
    test('round-trips and keeps only the switches it knows', () {
      final RemoteFlags flags = RemoteFlags.fromJson(<String, Object?>{
        'schemaVersion': 2,
        'killSwitches': <String, Object?>{
          'ptz': true,
          'ads': false,
          'future': true,
          'pip': 'yes',
        },
        'minSupportedVersion': '1.2.0',
        'message': 'Maintenance',
      });
      expect(flags.killSwitches, <String, bool>{'ptz': true, 'ads': false});
      expect(flags.isOff('ptz'), isTrue);
      expect(flags.isOff('ads'), isFalse);
      expect(flags.isOff('discovery'), isFalse);
      expect(flags.isOff('future'), isFalse);
      expect(RemoteFlags.fromJson(viaJson(flags.toJson())), flags);
      expect(
        RemoteFlags.fromJson(viaJson(flags.toJson())).hashCode,
        flags.hashCode,
      );
    });

    test('an empty file means everything on', () {
      expect(
        RemoteFlags.fromJson(const <String, Object?>{}),
        RemoteFlags.defaults,
      );
    });

    test('lists every switch of the first release', () {
      expect(
        RemoteFlagKeys.all,
        containsAll(<String>[
          'discovery',
          'ptz',
          'ads',
          'snapshots',
          'helpContent',
          'pip',
        ]),
      );
    });
  });

  group('CameraExportBundle', () {
    final DateTime when = DateTime.utc(2026, 10, 31, 9);
    final List<Camera> cameras = <Camera>[testCamera(id: 'a', name: 'Garden')];

    test('round-trips and never contains credentials', () {
      final CameraExportBundle bundle = CameraExportBundle(
        exportedAt: when,
        cameras: cameras,
        appVersion: '0.1.0',
      );
      final String text = jsonEncode(bundle.toJson());
      expect(text.toLowerCase(), isNot(contains('password')));
      final CameraExportBundle back = CameraExportBundle.fromJson(
        jsonDecode(text) as Map<String, Object?>,
      );
      expect(back, bundle);
      expect(back.hashCode, bundle.hashCode);
      expect(back.appVersion, '0.1.0');
    });

    test('refuses files that are not camera lists', () {
      expect(
        () => CameraExportBundle.fromJson(<String, Object?>{'format': 'other'}),
        throwsFormatException,
      );
    });

    test('refuses a newer or invalid schema', () {
      Map<String, Object?> withSchema(Object? schema) => <String, Object?>{
        'format': AppConstants.exportFormatId,
        'schemaVersion': schema,
        'exportedAtMillis': 1,
        'cameras': <Object?>[],
      };
      expect(
        () => CameraExportBundle.fromJson(
          withSchema(AppConstants.exportSchemaVersion + 1),
        ),
        throwsFormatException,
      );
      expect(
        () => CameraExportBundle.fromJson(withSchema(0)),
        throwsFormatException,
      );
      expect(
        () => CameraExportBundle.fromJson(withSchema(null)),
        throwsFormatException,
      );
    });

    test('a file with no cameras is valid and empty', () {
      final CameraExportBundle back = CameraExportBundle.fromJson(
        <String, Object?>{
          'format': AppConstants.exportFormatId,
          'schemaVersion': 1,
          'exportedAtMillis': 1,
        },
      );
      expect(back.cameras, isEmpty);
    });
  });

  group('PlayerState', () {
    test('states of the same kind are equal', () {
      expect(const PlayerPlaying(), const PlayerPlaying());
      expect(const PlayerPlaying().hashCode, const PlayerPlaying().hashCode);
      expect(const PlayerPlaying(), isNot(const PlayerBuffering()));
    });

    test('knows which states are active', () {
      expect(const PlayerConnecting().isActive, isTrue);
      expect(const PlayerBuffering().isActive, isTrue);
      expect(const PlayerPlaying().isActive, isTrue);
      expect(const PlayerReconnecting(attempt: 1).isActive, isTrue);
      expect(const PlayerIdle().isActive, isFalse);
      expect(const PlayerStopped().isActive, isFalse);
      expect(
        const PlayerError(AppError(ErrorClass.authFailed)).isActive,
        isFalse,
      );
    });

    test('an error carries its cause and a reconnect carries its attempt', () {
      const PlayerError error = PlayerError(AppError(ErrorClass.authFailed));
      expect(error.error.errorClass, ErrorClass.authFailed);
      expect(const PlayerReconnecting(attempt: 3).attempt, 3);
    });
  });
}
