import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/url_builder.dart';

/// What an RTSP DESCRIBE answered.
class RtspDescribeResult {
  const RtspDescribeResult({
    required this.statusCode,
    required this.authRequired,
    this.statusText = '',
    this.videoCodecs = const <String>[],
    this.audioCodecs = const <String>[],
  });

  final int statusCode;
  final String statusText;
  final bool authRequired;
  final List<String> videoCodecs;
  final List<String> audioCodecs;
}

/// What an HTTP request answered, before any body was read.
class HttpHeadResult {
  const HttpHeadResult({required this.statusCode, this.contentType});

  final int statusCode;
  final String? contentType;

  bool get isStreamOrImage {
    final String type = contentType ?? '';
    return type.startsWith('multipart/') || type.startsWith('image/');
  }
}

/// The network operations the tester needs. The platform layer implements
/// them; tests replace them with fakes.
abstract interface class ConnectivityProbes {
  Future<bool> resolves(String host);

  /// Ok when a TCP connection was made.
  Future<Result<void>> tcpConnect(String host, int port);

  Future<Result<RtspDescribeResult>> describeRtsp(
    Uri uri,
    CameraCredentials credentials,
  );

  Future<Result<HttpHeadResult>> probeHttp(
    Uri uri,
    CameraCredentials credentials,
  );
}

/// Plays the stream briefly and reports whether a picture appeared.
typedef FirstFrameCheck = Future<Result<void>> Function(
  Camera camera,
  CameraCredentials credentials,
);

/// Localization keys of the things a person can try next.
class TestSuggestion {
  TestSuggestion._();

  static const String checkHostName = 'testSuggestCheckHostName';
  static const String checkWifi = 'testSuggestCheckWifi';
  static const String checkPort = 'testSuggestCheckPort';
  static const String enableRtsp = 'testSuggestEnableRtsp';
  static const String checkCredentials = 'testSuggestCheckCredentials';
  static const String tryBrandPaths = 'testSuggestTryBrandPaths';
  static const String trySubstream = 'testSuggestTrySubstream';
  static const String tryMjpeg = 'testSuggestTryMjpeg';
  static const String openTroubleshooter = 'testSuggestOpenTroubleshooter';
}

/// Tests a camera in five steps (specification D5): the name resolves, the port
/// accepts a connection, the login works, the stream description is right, and
/// a picture appears. It stops at the first failure and says what to try.
class ConnectionTester {
  ConnectionTester({
    required this.probes,
    this.firstFrame,
    this.errorMapper = const ErrorMapper(),
  });

  final ConnectivityProbes probes;

  /// Null skips the picture step (for example when no player is available).
  final FirstFrameCheck? firstFrame;
  final ErrorMapper errorMapper;

  static final RegExp _ipLiteral =
      RegExp(r'^(\d{1,3}(\.\d{1,3}){3}|[0-9a-fA-F:]*:[0-9a-fA-F:]*)$');

  Future<ConnectionTestResult> run(
    Camera camera,
    CameraCredentials credentials, {
    void Function(List<StageResult> stages)? onProgress,
  }) async {
    final Map<TestStage, StageResult> stages = <TestStage, StageResult>{
      for (final TestStage stage in TestStage.values)
        stage: StageResult(stage: stage, status: StageStatus.pending),
    };
    void publish() => onProgress?.call(
          <StageResult>[for (final TestStage s in TestStage.values) stages[s]!],
        );

    void set(TestStage stage, StageStatus status, {String? detail, int? ms}) {
      stages[stage] = StageResult(
        stage: stage,
        status: status,
        detail: detail,
        elapsedMillis: ms,
      );
      publish();
    }

    ConnectionTestResult finish(AppError? error, List<String> suggestions) {
      // Anything not reached is skipped, so every stage has a final answer.
      for (final TestStage stage in TestStage.values) {
        final StageStatus status = stages[stage]!.status;
        if (status == StageStatus.pending || status == StageStatus.running) {
          stages[stage] = StageResult(stage: stage, status: StageStatus.skipped);
        }
      }
      publish();
      return ConnectionTestResult(
        stages: <StageResult>[for (final TestStage s in TestStage.values) stages[s]!],
        error: error,
        suggestionKeys: suggestions,
      );
    }

    final Uri? uri = UrlBuilder.streamUri(camera);
    if (uri == null) {
      set(TestStage.dns, StageStatus.failed, detail: 'invalid address');
      return finish(
        const AppError(ErrorClass.pathNotFound, detail: 'invalid address'),
        const <String>[TestSuggestion.checkHostName],
      );
    }
    final bool isRtsp = camera.protocol == StreamProtocol.rtsp;

    // 1. Name lookup.
    if (_ipLiteral.hasMatch(camera.host.trim())) {
      set(TestStage.dns, StageStatus.skipped, detail: 'address is a number');
    } else {
      set(TestStage.dns, StageStatus.running);
      final Stopwatch clock = Stopwatch()..start();
      final bool found = await probes.resolves(camera.host.trim());
      if (!found) {
        set(TestStage.dns, StageStatus.failed, detail: 'name not found', ms: clock.elapsedMilliseconds);
        return finish(
          const AppError(ErrorClass.networkUnreachable, detail: 'name not found'),
          const <String>[TestSuggestion.checkHostName, TestSuggestion.checkWifi],
        );
      }
      set(TestStage.dns, StageStatus.passed, ms: clock.elapsedMilliseconds);
    }

    // 2. Port.
    set(TestStage.tcp, StageStatus.running);
    final Stopwatch tcpClock = Stopwatch()..start();
    final Result<void> connected = await probes.tcpConnect(camera.host.trim(), camera.port);
    if (connected.errorOrNull != null) {
      set(TestStage.tcp, StageStatus.failed, ms: tcpClock.elapsedMilliseconds);
      return finish(
        connected.errorOrNull,
        <String>[
          TestSuggestion.checkPort,
          if (isRtsp) TestSuggestion.enableRtsp,
          TestSuggestion.checkWifi,
          TestSuggestion.openTroubleshooter,
        ],
      );
    }
    set(TestStage.tcp, StageStatus.passed, ms: tcpClock.elapsedMilliseconds);

    // 3 and 4. Login and stream description.
    set(TestStage.auth, StageStatus.running);
    final Stopwatch describeClock = Stopwatch()..start();
    int? status;
    String? detail;
    bool contentOk = true;
    if (isRtsp) {
      final Result<RtspDescribeResult> described = await probes.describeRtsp(uri, credentials);
      if (described.errorOrNull != null) {
        set(TestStage.auth, StageStatus.failed, ms: describeClock.elapsedMilliseconds);
        return finish(
          described.errorOrNull,
          const <String>[TestSuggestion.checkWifi, TestSuggestion.openTroubleshooter],
        );
      }
      final RtspDescribeResult reply = described.valueOrNull!;
      status = reply.statusCode;
      if (reply.videoCodecs.isNotEmpty) {
        detail = 'video: ${reply.videoCodecs.join(', ')}';
      }
    } else {
      final Result<HttpHeadResult> head = await probes.probeHttp(uri, credentials);
      if (head.errorOrNull != null) {
        set(TestStage.auth, StageStatus.failed, ms: describeClock.elapsedMilliseconds);
        return finish(
          head.errorOrNull,
          const <String>[TestSuggestion.checkWifi, TestSuggestion.openTroubleshooter],
        );
      }
      status = head.valueOrNull!.statusCode;
      contentOk = head.valueOrNull!.isStreamOrImage;
      detail = head.valueOrNull!.contentType;
    }
    final int elapsed = describeClock.elapsedMilliseconds;

    if (status == 401 || status == 403) {
      set(TestStage.auth, StageStatus.failed, detail: 'status $status', ms: elapsed);
      return finish(
        errorMapper.fromStatus(status),
        const <String>[TestSuggestion.checkCredentials],
      );
    }
    set(TestStage.auth, StageStatus.passed, ms: elapsed);

    if (status != 200) {
      set(TestStage.describe, StageStatus.failed, detail: 'status $status', ms: elapsed);
      final AppError error = errorMapper.fromStatus(status);
      return finish(
        error,
        <String>[
          if (error.errorClass == ErrorClass.pathNotFound) TestSuggestion.tryBrandPaths,
          if (error.errorClass == ErrorClass.unsupportedMedia) ...<String>[
            TestSuggestion.trySubstream,
            TestSuggestion.tryMjpeg,
          ],
          if (error.errorClass == ErrorClass.networkUnreachable) ...<String>[
            TestSuggestion.checkPort,
            TestSuggestion.openTroubleshooter,
          ],
        ],
      );
    }
    if (!contentOk) {
      set(TestStage.describe, StageStatus.failed, detail: detail ?? 'not a video or image', ms: elapsed);
      return finish(
        const AppError(
          ErrorClass.pathNotFound,
          detail: 'the address answered with something that is not a video or image',
        ),
        const <String>[TestSuggestion.tryBrandPaths],
      );
    }
    set(TestStage.describe, StageStatus.passed, detail: detail, ms: elapsed);

    // 5. A picture.
    final FirstFrameCheck? check = firstFrame;
    if (check == null) {
      set(TestStage.firstFrame, StageStatus.skipped);
      return finish(null, const <String>[]);
    }
    set(TestStage.firstFrame, StageStatus.running);
    final Stopwatch frameClock = Stopwatch()..start();
    final Result<void> frame = await check(camera, credentials);
    if (frame.errorOrNull != null) {
      set(TestStage.firstFrame, StageStatus.failed, ms: frameClock.elapsedMilliseconds);
      return finish(
        frame.errorOrNull,
        const <String>[TestSuggestion.trySubstream, TestSuggestion.tryMjpeg],
      );
    }
    set(TestStage.firstFrame, StageStatus.passed, ms: frameClock.elapsedMilliseconds);
    return finish(null, const <String>[]);
  }
}
