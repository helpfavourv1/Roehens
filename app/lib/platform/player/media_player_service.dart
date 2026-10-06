import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/platform/player/mjpeg_session.dart';
import 'package:roehens/platform/player/player_session.dart';

/// The playback engine: media_kit (libmpv) for RTSP, and the Dart MJPEG client
/// for MJPEG cameras. Implements [PlayerContract] and supplies the
/// `PlayerPool`'s session factory.
class MediaPlayerService implements PlayerContract {
  MediaPlayerService({
    this.options = const PlayerOptions(),
    this.clock = const SystemClock(),
    this.logger,
  });

  final PlayerOptions options;
  final ClockContract clock;
  final LoggerContract? logger;

  /// Picture-in-picture needs the video drawn into the app's own view. media_kit
  /// renders into a Flutter texture, so the answer is yes by design. This has not
  /// been verified on a device: the available phone has no picture-in-picture.
  @override
  PlayerCapabilities get capabilities {
    return const PlayerCapabilities(pictureInPictureSurface: true);
  }

  @override
  PlayerSessionContract createSession() => _engineSession();

  /// Session for [protocol]: MJPEG cameras use the Dart client, everything else
  /// the video engine.
  PlayerSessionContract sessionFor(StreamProtocol protocol) {
    return protocol == StreamProtocol.mjpeg ? MjpegSession() : _engineSession();
  }

  PlayerSessionContract _engineSession() {
    return MediaKitPlayerSession(options: options, clock: clock, logger: logger);
  }
}
