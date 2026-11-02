import 'package:flutter/widgets.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Marks the ad-free unlock: a small filled pill with a diamond and a word.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, required this.label});

  /// For example "PRO".
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = context.colors.textOnAccent;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.accent,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(
                AppIconName.upgrade,
                size: AppSizes.iconChipGlyph,
                color: color,
                weight: AppIconWeight.fill,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: context.type.data.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
