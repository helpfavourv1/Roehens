import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/camera_tile_overlay.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// One camera in the grid. It fills the space it is given.
///
/// Under the overlay there are two layers: the last still ([poster], dimmed)
/// and the live [video]. The video fades in over the poster when it connects.
/// A tile narrower than 120 shows the status as an icon only; tapping that icon
/// ([onStatusTap]) opens the full message.
class CameraTile extends StatelessWidget {
  const CameraTile({
    super.key,
    required this.name,
    required this.status,
    required this.statusLabel,
    this.video,
    this.isVideoVisible = false,
    this.poster,
    this.posterAgeLabel,
    this.resolutionLabel,
    this.onTap,
    this.onLongPress,
    this.onStatusTap,
    this.showLabels = true,
    this.focused = false,
    this.semanticLabel,
  });

  final String name;
  final StreamStatus status;
  final String statusLabel;

  /// The engine's video view, built by the shell from the session's handle.
  final Widget? video;

  /// True once the first frame is on screen, so the video can fade in.
  final bool isVideoVisible;

  /// JPEG bytes of the last still, shown dimmed while the video is not visible.
  final Uint8List? poster;
  final String? posterAgeLabel;
  final String? resolutionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStatusTap;
  final bool showLabels;
  final bool focused;

  /// Replaces the spoken label. By default: name, status, resolution.
  final String? semanticLabel;

  String get _spoken {
    final String? custom = semanticLabel;
    if (custom != null) {
      return custom;
    }
    final String? resolution = resolutionLabel;
    return resolution == null
        ? '$name, $statusLabel'
        : '$name, $statusLabel, $resolution';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Duration fade = context.motion(AppMotion.tileConnect);
    final Uint8List? still = poster;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final bool narrow = box.maxWidth < AppSizes.tileIconOnlyWidth;
        final Widget content = ClipRRect(
          borderRadius: AppRadius.allMd,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.videoBackdrop,
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: focused ? colors.borderFocus : colors.borderSubtle,
                width: focused ? AppSizes.focusRing : AppSizes.hairline,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (still != null)
                  Opacity(
                    opacity: AppMotion.pressedOpacity,
                    child: Image.memory(
                      still,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                if (video != null)
                  AnimatedOpacity(
                    opacity: isVideoVisible ? 1 : 0,
                    duration: fade,
                    curve: AppMotion.settle,
                    child: video,
                  ),
                CameraTileOverlay(
                  name: name,
                  resolutionLabel: resolutionLabel,
                  ageLabel: isVideoVisible ? null : posterAgeLabel,
                  showLabels: showLabels,
                  compact: narrow,
                  statusPill: StreamStatusPill(
                    status: status,
                    label: statusLabel,
                    iconOnly: narrow,
                    expandHitArea: !narrow,
                    plate: !narrow,
                    onTap: onStatusTap,
                  ),
                ),
              ],
            ),
          ),
        );
        if (onTap == null && onLongPress == null) {
          return Semantics(label: _spoken, container: true, child: content);
        }
        return AppPressable(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.allMd,
          semanticLabel: _spoken,
          child: content,
        );
      },
    );
  }
}
