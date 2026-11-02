import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// What a camera is doing, in the words a person needs.
enum StreamStatus {
  live,
  connecting,
  reconnecting,
  error,
  offline;

  /// The status that matches a playback state.
  static StreamStatus fromPlayerState(PlayerState state) {
    return switch (state) {
      PlayerPlaying() => StreamStatus.live,
      PlayerConnecting() || PlayerBuffering() => StreamStatus.connecting,
      PlayerReconnecting() => StreamStatus.reconnecting,
      PlayerError() => StreamStatus.error,
      PlayerIdle() || PlayerStopped() => StreamStatus.offline,
    };
  }

  AppIconName get icon => switch (this) {
        StreamStatus.live => AppIconName.live,
        StreamStatus.connecting || StreamStatus.reconnecting => AppIconName.refresh,
        StreamStatus.error => AppIconName.warning,
        StreamStatus.offline => AppIconName.wifiOff,
      };

  Color color(AppColors colors) => switch (this) {
        StreamStatus.live => colors.streamLive,
        StreamStatus.connecting || StreamStatus.reconnecting => colors.streamConnecting,
        StreamStatus.error => colors.streamError,
        StreamStatus.offline => colors.streamOffline,
      };
}

/// Status as icon, text and color together, on a dark plate so it reads over
/// any picture. Below the icon-only width the text is dropped and a tap opens
/// the full message. Live pulses; reduced motion keeps it still.
class StreamStatusPill extends StatefulWidget {
  const StreamStatusPill({
    super.key,
    required this.status,
    required this.label,
    this.iconOnly = false,
    this.onTap,
  });

  final StreamStatus status;

  /// The status in words, already translated. Always the spoken label too.
  final String label;
  final bool iconOnly;
  final VoidCallback? onTap;

  @override
  State<StreamStatusPill> createState() => _StreamStatusPillState();
}

class _StreamStatusPillState extends State<StreamStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.livePulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(StreamStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final bool pulse = widget.status == StreamStatus.live && !context.reduceMotion;
    if (pulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!pulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color tone = widget.status.color(colors);
    final Widget icon = FadeTransition(
      opacity: Tween<double>(begin: 1, end: AppMotion.pulseMinOpacity).animate(_pulse),
      child: AppIcon(
        widget.status.icon,
        size: AppSizes.iconChipGlyph,
        color: tone,
        weight: AppIconWeight.fill,
      ),
    );

    final Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.overlayOnVideo,
        borderRadius: AppRadius.allPill,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            if (!widget.iconOnly) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: context.clampedTextScaler(max: AppSizes.tileOverlayMaxTextScale),
                  style: context.type.data.copyWith(color: colors.onVideoText),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return Semantics(label: widget.label, excludeSemantics: true, child: pill);
    }
    return AppPressable(
      onTap: widget.onTap,
      borderRadius: AppRadius.allPill,
      semanticLabel: widget.label,
      minHitSize: widget.iconOnly ? const Size.square(AppSizes.touchTarget) : null,
      child: pill,
    );
  }
}
