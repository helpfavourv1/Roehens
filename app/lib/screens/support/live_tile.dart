import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/app/live_sessions.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/utils/date_formatter.dart';
import 'package:roehens/widgets/camera_tile.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// One camera in the grid: the tile wired to that camera's session.
///
/// Without a session (the camera is not decoding) it shows the last picture,
/// dimmed, with its age. With one it follows the session's state and fades the
/// video in over the picture.
class LiveTile extends StatelessWidget {
  const LiveTile({
    super.key,
    required this.camera,
    required this.onOpen,
    required this.onProblem,
    this.showLabels = true,
  });

  final Camera camera;

  /// Open the camera fullscreen.
  final VoidCallback onOpen;

  /// The tile is in error: open its message and actions.
  final void Function(AppError error) onProblem;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final LiveSessions live = AppScope.of(context).live;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: live,
      builder: (BuildContext context, Widget? _) {
        final LiveSession? pooled = live.sessionFor(camera.id);
        final PosterFrame? poster = live.posterFor(camera.id);
        final String? age = poster == null
            ? null
            : ageLabel(
                l10n,
                DateFormatter.age(poster.capturedAt, DateTime.now()),
              );
        if (pooled == null) {
          return CameraTile(
            name: camera.name,
            status: StreamStatus.offline,
            statusLabel: streamStatusLabel(l10n, StreamStatus.offline),
            poster: poster?.bytes,
            posterAgeLabel: age,
            showLabels: showLabels,
            onTap: onOpen,
          );
        }
        return ValueListenableBuilder<PlayerState>(
          valueListenable: pooled.state,
          builder: (BuildContext context, PlayerState state, Widget? _) {
            final StreamStatus status = StreamStatus.fromPlayerState(state);
            final AppError? error = state is PlayerError ? state.error : null;
            return ValueListenableBuilder<VideoSize?>(
              valueListenable: pooled.videoSize,
              builder: (BuildContext context, VideoSize? size, Widget? _) {
                return CameraTile(
                  name: camera.name,
                  status: status,
                  statusLabel: streamStatusLabel(l10n, status),
                  video: AppScope.of(context).videoBuilder(
                    pooled.viewHandle,
                    backdrop: context.colors.videoBackdrop,
                  ),
                  isVideoVisible: state is PlayerPlaying,
                  poster: poster?.bytes,
                  posterAgeLabel: age,
                  resolutionLabel: size == null
                      ? null
                      : '${size.width}x${size.height}',
                  showLabels: showLabels,
                  onTap: error == null ? onOpen : () => onProblem(error),
                  onStatusTap: error == null ? null : () => onProblem(error),
                );
              },
            );
          },
        );
      },
    );
  }
}
