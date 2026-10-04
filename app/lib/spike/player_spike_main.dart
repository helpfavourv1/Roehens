// Temporary entrypoint for the player spike (checkpoint CP1). Removed in P8.
//
// Plays the two spike streams, whose addresses arrive as build-time defines from
// CI secrets (never committed), and records what the engine can do: first-frame
// time, codec, hardware decoding, frame access, stream-to-file and the
// picture-in-picture hook. Read the results on the phone and report them.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:roehens/platform/system/logger_service.dart';
import 'package:roehens/ui/tokens/app_theme.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';

const String _rtspUrl = String.fromEnvironment('SPIKE_RTSP_URL');
const String _mjpegUrl = String.fromEnvironment('SPIKE_MJPEG_URL');
const MethodChannel _pipChannel = MethodChannel('roehens/pip');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const _SpikeApp());
}

class _SpikeApp extends StatelessWidget {
  const _SpikeApp();

  @override
  Widget build(BuildContext context) {
    final AppTokensData tokens = AppTheme.dark();
    return AppTokens(
      data: tokens,
      child: WidgetsApp(
        color: tokens.colors.bgPrimary,
        textStyle: AppTheme.baseTextStyle(tokens),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) {
              return builder(c);
            },
          );
        },
        home: const _SpikeHome(),
      ),
    );
  }
}

/// One stream under test.
class _Probe {
  _Probe({required this.label, required this.url, required this.isRtsp})
      : player = Player(
          configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
        ) {
    controller = VideoController(player);
  }

  final String label;
  final String url;
  final bool isRtsp;
  final Player player;
  late final VideoController controller;
  final ValueNotifier<List<String>> lines = ValueNotifier<List<String>>(<String>[]);

  void _add(String text) {
    lines.value = <String>[...lines.value, LoggerService.redact(text)];
  }

  Future<String> _prop(NativePlayer native, String name) async {
    try {
      final String value = await native.getProperty(name);
      return value.isEmpty ? '-' : value;
    } catch (error) {
      return 'n/a';
    }
  }

  Future<void> run() async {
    if (url.isEmpty) {
      _add('No address was given at build time.');
      return;
    }
    final NativePlayer native = player.platform! as NativePlayer;
    try {
      if (isRtsp) {
        await native.setProperty('demuxer-lavf-o', 'rtsp_transport=tcp');
      }
      await native.setProperty('profile', 'low-latency');
    } catch (error) {
      _add('option error: $error');
    }

    int logged = 0;
    player.stream.log.listen((PlayerLog log) {
      if (logged < 14) {
        logged++;
        _add('mpv ${log.level}/${log.prefix}: ${log.text.trim()}');
      }
    });
    player.stream.error.listen((String message) => _add('ERROR: $message'));

    final Stopwatch clock = Stopwatch()..start();
    final Completer<void> firstFrame = Completer<void>();
    player.stream.width.listen((int? width) {
      if ((width ?? 0) > 0 && !firstFrame.isCompleted) {
        firstFrame.complete();
      }
    });

    _add('opening (${isRtsp ? 'RTSP over TCP' : 'MJPEG over HTTP'})');
    await player.open(Media(url));
    try {
      await firstFrame.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _add('NO FRAME within 20 s');
      return;
    }
    _add('first frame after ${clock.elapsedMilliseconds} ms');
    _add('size ${player.state.width} x ${player.state.height}');
    await Future<void>.delayed(const Duration(seconds: 3));
    _add('video codec: ${await _prop(native, 'video-codec')}');
    _add('audio codec: ${await _prop(native, 'audio-codec-name')}');
    _add('hardware decoder: ${await _prop(native, 'hwdec-current')}');
    _add('frame rate: ${await _prop(native, 'estimated-vf-fps')}');
    _add('bitrate (bits/s): ${await _prop(native, 'video-bitrate')}');

    try {
      final Uint8List? shot = await player.screenshot();
      _add(
        shot == null
            ? 'FRAME ACCESS: screenshot returned nothing'
            : 'FRAME ACCESS: ok, ${shot.length} bytes',
      );
    } catch (error) {
      _add('FRAME ACCESS: failed ($error)');
    }

    try {
      final String path = '${Directory.systemTemp.path}/spike_$label.ts';
      final File file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      await native.setProperty('stream-record', path);
      await Future<void>.delayed(const Duration(seconds: 5));
      await native.setProperty('stream-record', '');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final int size = file.existsSync() ? file.lengthSync() : 0;
      _add('STREAM TO FILE: ${size > 0 ? 'ok' : 'EMPTY'}, $size bytes in 5 s');
    } catch (error) {
      _add('STREAM TO FILE: failed ($error)');
    }
    _add('done');
  }
}

class _SpikeHome extends StatefulWidget {
  const _SpikeHome();

  @override
  State<_SpikeHome> createState() => _SpikeHomeState();
}

class _SpikeHomeState extends State<_SpikeHome> {
  late final _Probe _rtsp;
  late final _Probe _mjpeg;
  final ValueNotifier<String> _pipResult = ValueNotifier<String>('PiP: not tried');

  @override
  void initState() {
    super.initState();
    _rtsp = _Probe(label: 'rtsp', url: _rtspUrl, isRtsp: true);
    _mjpeg = _Probe(label: 'mjpeg', url: _mjpegUrl, isRtsp: false);
    unawaited(_rtsp.run());
    unawaited(_mjpeg.run());
  }

  @override
  void dispose() {
    unawaited(_rtsp.player.dispose());
    unawaited(_mjpeg.player.dispose());
    _pipResult.dispose();
    super.dispose();
  }

  Future<void> _tryPip() async {
    try {
      final bool? supported = await _pipChannel.invokeMethod<bool>('isSupported');
      final bool? entered = await _pipChannel.invokeMethod<bool>('enter');
      _pipResult.value = 'PiP: supported=$supported entered=$entered';
    } catch (error) {
      _pipResult.value = 'PiP: failed ($error)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTokens.of(context).colors;
    return ColoredBox(
      color: colors.bgPrimary,
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.allSm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Roehens player spike',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
              Expanded(child: _ProbeView(probe: _rtsp, colors: colors)),
              Expanded(child: _ProbeView(probe: _mjpeg, colors: colors)),
              GestureDetector(
                onTap: _tryPip,
                child: ColoredBox(
                  color: colors.accent,
                  child: Padding(
                    padding: AppSpacing.allSm,
                    child: Text(
                      'Try picture-in-picture',
                      style: TextStyle(color: colors.textOnAccent),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: _pipResult,
                builder: (BuildContext c, String value, Widget? w) {
                  return Text(value, style: TextStyle(color: colors.textSecondary));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProbeView extends StatelessWidget {
  const _ProbeView({required this.probe, required this.colors});

  final _Probe probe;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: ColoredBox(
            color: colors.videoBackdrop,
            child: Video(controller: probe.controller, controls: null),
          ),
        ),
        Expanded(
          flex: 6,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: probe.lines,
            builder: (BuildContext c, List<String> lines, Widget? w) {
              return SingleChildScrollView(
                child: Text(
                  '${probe.label.toUpperCase()}\n${lines.join('\n')}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
