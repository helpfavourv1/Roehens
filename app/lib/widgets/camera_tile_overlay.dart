import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// What sits on top of a tile's picture: the status pill at the top, and a plate
/// with the camera name (and resolution) at the bottom. Text on the plate is
/// always white and never scales beyond 130%, so the plate stays inside the
/// tile.
class CameraTileOverlay extends StatelessWidget {
  const CameraTileOverlay({
    super.key,
    required this.name,
    required this.statusPill,
    this.resolutionLabel,
    this.ageLabel,
    this.showLabels = true,
    this.compact = false,
  });

  final String name;
  final Widget statusPill;

  /// For example "1920x1080". Technical values stay left-to-right.
  final String? resolutionLabel;

  /// How old the shown still is, when the tile shows a poster.
  final String? ageLabel;

  /// False hides the name plate (the setting "show overlay labels").
  final bool showLabels;

  /// A narrow tile: the plate shows the name only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler =
        context.clampedTextScaler(max: AppSizes.tileOverlayMaxTextScale);
    final Color white = context.colors.onVideoText;
    final bool hasPlate = showLabels;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(child: Align(alignment: AlignmentDirectional.centerStart, child: statusPill)),
              if (ageLabel != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.overlayOnVideo,
                    borderRadius: AppRadius.allPill,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Text(
                      ageLabel!,
                      maxLines: 1,
                      textScaler: scaler,
                      style: context.type.data.copyWith(color: white),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (hasPlate)
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.overlayOnVideo,
                borderRadius: AppRadius.allSm,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: scaler,
                        style: context.type.callout.copyWith(color: white),
                      ),
                    ),
                    if (resolutionLabel != null && !compact) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      LtrText(
                        resolutionLabel!,
                        textScaler: scaler,
                        style: context.type.data.copyWith(color: white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
