import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/connection_tester.dart';

import '../../support/fakes.dart';

class FakeProbes implements ConnectivityProbes {
  bool dnsOk = true;
  Result<void> tcp = const Ok<void>(null);
  Result<RtspDescribeResult> rtsp = const Ok<RtspDescribeResult>(
    RtspDescribeResult(
      statusCode: 200,
      authRequired: true,
      videoCodecs: <String>['H265'],
    ),
  );
  Result<HttpHeadResult> http = const Ok<HttpHeadResult>(
    HttpHeadResult(statusCode: 200, contentType: 'multipart/x-mixed-replace'),
  );
  final List<String> calls = <String>[];

  @override
  Future<bool> resolves(String host) async {
    calls.add('dns $host');
    return dnsOk;
  }

  @override
  Future<Result<void>> tcpConnect(String host, int port) async {
    calls.add('tcp $host:$port');
    return tcp;
  }

  @override
  Future<Result<RtspDescribeResult>> describeRtsp(Uri uri, CameraCredentials c) async {
    calls.add('rtsp $uri');
    return rtsp;
  }

  @override
  Future<Result<HttpHeadResult>> probeHttp(Uri uri, CameraCredentials c) async {
    calls.add('http $uri');
    return http;
  }
}

const CameraCredentials login =
    CameraCredentials(username: 'admin', password: 'pw12345');

Camera rtspCamera({String host = '192.168.1.64'}) {
  return testCamera().copyWith(host: host, port: 554, mainPath: '/stream0');
}

Camera httpCamera() {
  return testCamera().copyWith(
    host: '192.168.1.70',
    port: 8080,
    mainPath: '/video.mjpg',
    protocol: StreamProtocol.mjpeg,
  );
}

Map<TestStage, StageStatus> statuses(ConnectionTestResult r) {
  return <TestStage, StageStatus>{for (final StageResult s in r.stages) s.stage: s.status};
}

void main() {
  late FakeProbes probes;
  late ConnectionTester tester;

  setUp(() {
    probes = FakeProbes();
    tester = ConnectionTester(
      probes: probes,
      firstFrame: (Camera c, CameraCredentials cr) async => const Ok<void>(null),
    );
  });

  test('a healthy RTSP camera passes every step', () async {
    final ConnectionTestResult result = await tester.run(rtspCamera(), login);
    expect(result.passed, isTrue);
    expect(result.error, isNull);
    expect(result.suggestionKeys, isEmpty);
    expect(statuses(result), <TestStage, StageStatus>{
      TestStage.dns: StageStatus.skipped,
      TestStage.tcp: StageStatus.passed,
      TestStage.auth: StageStatus.passed,
      TestStage.describe: StageStatus.passed,
      TestStage.firstFrame: StageStatus.passed,
    });
    expect(
      result.stages.firstWhere((StageResult s) => s.stage == TestStage.describe).detail,
      'video: H265',
    );
    expect(probes.calls, <String>[
      'tcp 192.168.1.64:554',
      'rtsp rtsp://192.168.1.64:554/stream0',
    ]);
  });

  test('the address handed to the probes carries no credentials', () async {
    await tester.run(rtspCamera(), login);
    expect(probes.calls.any((String c) => c.contains('@')), isFalse);
    expect(probes.calls.any((String c) => c.contains('pw12345')), isFalse);
  });

  group('failures stop the test and say what to try', () {
    test('a host name that does not exist', () async {
      probes.dnsOk = false;
      final ConnectionTestResult result =
          await tester.run(rtspCamera(host: 'cam.example'), login);
      expect(result.passed, isFalse);
      expect(result.error!.errorClass, ErrorClass.networkUnreachable);
      expect(result.suggestionKeys, contains(TestSuggestion.checkHostName));
      expect(statuses(result)[TestStage.dns], StageStatus.failed);
      expect(statuses(result)[TestStage.tcp], StageStatus.skipped);
      expect(probes.calls.any((String c) => c.startsWith('tcp')), isFalse);
    });

    test('a number address skips the name lookup', () async {
      await tester.run(rtspCamera(), login);
      expect(probes.calls.any((String c) => c.startsWith('dns')), isFalse);
    });

    test('a host name is looked up first', () async {
      await tester.run(rtspCamera(host: 'cam.local'), login);
      expect(probes.calls.first, 'dns cam.local');
    });

    test('a closed port', () async {
      probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(statuses(result)[TestStage.tcp], StageStatus.failed);
      expect(statuses(result)[TestStage.auth], StageStatus.skipped);
      expect(result.suggestionKeys, containsAll(<String>[
        TestSuggestion.checkPort,
        TestSuggestion.enableRtsp,
        TestSuggestion.openTroubleshooter,
      ]));
    });

    test('enabling RTSP is only suggested for RTSP cameras', () async {
      probes.tcp = const Err<void>(AppError(ErrorClass.networkUnreachable));
      final ConnectionTestResult result = await tester.run(httpCamera(), login);
      expect(result.suggestionKeys.contains(TestSuggestion.enableRtsp), isFalse);
    });

    test('a wrong login', () async {
      probes.rtsp = const Ok<RtspDescribeResult>(
        RtspDescribeResult(statusCode: 401, authRequired: true),
      );
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.error!.errorClass, ErrorClass.authFailed);
      expect(result.suggestionKeys, <String>[TestSuggestion.checkCredentials]);
      expect(statuses(result)[TestStage.auth], StageStatus.failed);
      expect(statuses(result)[TestStage.describe], StageStatus.skipped);
    });

    test('a wrong path', () async {
      probes.rtsp = const Ok<RtspDescribeResult>(
        RtspDescribeResult(statusCode: 404, authRequired: false),
      );
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.error!.errorClass, ErrorClass.pathNotFound);
      expect(result.suggestionKeys, contains(TestSuggestion.tryBrandPaths));
      expect(statuses(result)[TestStage.auth], StageStatus.passed);
      expect(statuses(result)[TestStage.describe], StageStatus.failed);
    });

    test('a transport the camera refuses', () async {
      probes.rtsp = const Ok<RtspDescribeResult>(
        RtspDescribeResult(statusCode: 461, authRequired: false),
      );
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.error!.errorClass, ErrorClass.unsupportedMedia);
      expect(result.suggestionKeys, contains(TestSuggestion.trySubstream));
    });

    test('a camera that answers with a server error', () async {
      probes.rtsp = const Ok<RtspDescribeResult>(
        RtspDescribeResult(statusCode: 503, authRequired: false),
      );
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.error!.errorClass, ErrorClass.networkUnreachable);
    });

    test('a probe that cannot complete', () async {
      probes.rtsp = const Err<RtspDescribeResult>(AppError(ErrorClass.networkUnreachable));
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.passed, isFalse);
      expect(result.error!.errorClass, ErrorClass.networkUnreachable);
    });

    test('no picture appears', () async {
      tester = ConnectionTester(
        probes: probes,
        firstFrame: (Camera c, CameraCredentials cr) async =>
            const Err<void>(AppError(ErrorClass.unsupportedMedia)),
      );
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      expect(result.passed, isFalse);
      expect(statuses(result)[TestStage.describe], StageStatus.passed);
      expect(statuses(result)[TestStage.firstFrame], StageStatus.failed);
      expect(result.suggestionKeys, containsAll(<String>[
        TestSuggestion.trySubstream,
        TestSuggestion.tryMjpeg,
      ]));
    });

    test('an address that cannot be built', () async {
      final ConnectionTestResult result =
          await tester.run(rtspCamera(host: 'bad host'), login);
      expect(result.passed, isFalse);
      expect(result.suggestionKeys, <String>[TestSuggestion.checkHostName]);
      expect(probes.calls, isEmpty);
    });
  });

  group('HTTP cameras', () {
    test('an MJPEG stream passes', () async {
      final ConnectionTestResult result = await tester.run(httpCamera(), login);
      expect(result.passed, isTrue);
      expect(probes.calls.last, 'http http://192.168.1.70:8080/video.mjpg');
    });

    test('a still-image address passes', () async {
      probes.http = const Ok<HttpHeadResult>(
        HttpHeadResult(statusCode: 200, contentType: 'image/jpeg'),
      );
      expect((await tester.run(httpCamera(), login)).passed, isTrue);
    });

    test('a web page instead of a stream is a wrong path', () async {
      probes.http = const Ok<HttpHeadResult>(
        HttpHeadResult(statusCode: 200, contentType: 'text/html'),
      );
      final ConnectionTestResult result = await tester.run(httpCamera(), login);
      expect(result.error!.errorClass, ErrorClass.pathNotFound);
      expect(result.suggestionKeys, contains(TestSuggestion.tryBrandPaths));
    });

    test('a login rejection', () async {
      probes.http = const Ok<HttpHeadResult>(HttpHeadResult(statusCode: 401));
      final ConnectionTestResult result = await tester.run(httpCamera(), login);
      expect(result.error!.errorClass, ErrorClass.authFailed);
    });

    test('a missing page', () async {
      probes.http = const Ok<HttpHeadResult>(HttpHeadResult(statusCode: 404));
      final ConnectionTestResult result = await tester.run(httpCamera(), login);
      expect(result.error!.errorClass, ErrorClass.pathNotFound);
    });
  });

  group('progress and optional steps', () {
    test('without a picture check the last step is skipped and the test passes', () async {
      final ConnectionTester noPlayer = ConnectionTester(probes: probes);
      final ConnectionTestResult result = await noPlayer.run(rtspCamera(), login);
      expect(statuses(result)[TestStage.firstFrame], StageStatus.skipped);
      expect(result.passed, isTrue);
    });

    test('progress reports every step and ends with a final answer for each', () async {
      final List<List<StageResult>> seen = <List<StageResult>>[];
      final ConnectionTestResult result =
          await tester.run(rtspCamera(), login, onProgress: seen.add);

      expect(seen, isNotEmpty);
      expect(seen.first.length, TestStage.values.length);
      expect(
        seen.any((List<StageResult> s) => s.any((StageResult r) => r.status == StageStatus.running)),
        isTrue,
      );
      for (final StageResult stage in seen.last) {
        expect(
          stage.status == StageStatus.pending || stage.status == StageStatus.running,
          isFalse,
          reason: '${stage.stage} has no final answer',
        );
      }
      expect(seen.last.map((StageResult s) => s.status), result.stages.map((StageResult s) => s.status));
    });

    test('a failed run still leaves no step pending', () async {
      probes.dnsOk = false;
      final List<List<StageResult>> seen = <List<StageResult>>[];
      await tester.run(rtspCamera(host: 'cam.local'), login, onProgress: seen.add);
      for (final StageResult stage in seen.last) {
        expect(stage.status, isNot(StageStatus.pending));
      }
    });

    test('each step that ran reports how long it took', () async {
      final ConnectionTestResult result = await tester.run(rtspCamera(), login);
      final StageResult tcp = result.stages.firstWhere((StageResult s) => s.stage == TestStage.tcp);
      expect(tcp.elapsedMillis, isNotNull);
    });
  });
}
