import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// A saved camera in the Cameras list: name, address and protocol, and its
/// status as icon and word. Tap to open, long-press for more, swipe toward the
/// end to delete (the list then offers Undo).
class CameraListRow extends StatelessWidget {
  const CameraListRow({
    super.key,
    required this.dismissKey,
    required this.name,
    required this.address,
    required this.protocolLabel,
    this.status,
    this.statusLabel,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.deleteLabel,
  }) : assert(
         onDelete == null || deleteLabel != null,
         'A swipe-to-delete row needs a spoken label for delete.',
       );

  /// Stable per camera, so a swipe applies to the right row.
  final Key dismissKey;
  final String name;

  /// Host and port, shown left-to-right.
  final String address;
  final String protocolLabel;
  final StreamStatus? status;
  final String? statusLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final StreamStatus? state = status;
    final Widget row = AppPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      style: AppPressStyle.tint,
      semanticLabel: <String>[
        name,
        address,
        protocolLabel,
        ?statusLabel,
      ].join(', '),
      child: ColoredBox(
        color: colors.bgSecondary,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                AppIcon(
                  AppIconName.cameraDome,
                  size: AppSizes.iconRowLeading,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: context.type.callout.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: LtrText(
                              address,
                              style: context.type.footnote.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          LtrText(
                            protocolLabel,
                            style: context.type.data.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state != null && statusLabel != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  AppIcon(
                    state.icon,
                    size: AppSizes.iconChipGlyph,
                    color: state.color(colors),
                    weight: AppIconWeight.fill,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusLabel!,
                    style: context.type.data.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                AppIcon(
                  AppIconName.chevronRight,
                  size: AppSizes.iconRowTrailing,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (onDelete == null) {
      return row;
    }
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      // The list removes the row when the camera is really gone; the row only
      // asks, so a failed delete leaves it in place.
      confirmDismiss: (DismissDirection _) async {
        onDelete!();
        return false;
      },
      background: ColoredBox(
        color: colors.error,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Semantics(
              label: deleteLabel,
              child: AppIcon(
                AppIconName.delete,
                size: AppSizes.iconNavBar,
                color: colors.textOnAccent,
              ),
            ),
          ),
        ),
      ),
      child: row,
    );
  }
}
