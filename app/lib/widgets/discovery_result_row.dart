import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_pressable.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A device found on the network. The address is shown left-to-right in every
/// language. Tapping it starts adding the camera with the address filled in.
class DiscoveryResultRow extends StatelessWidget {
  const DiscoveryResultRow({
    super.key,
    required this.title,
    required this.address,
    required this.sourceLabel,
    required this.onTap,
    this.subtitle,
  });

  /// The camera's name or model, or its address when it has neither.
  final String title;

  /// Host and port, for example `192.168.1.20:554`.
  final String address;

  /// How it was found, for example "ONVIF" or "Network scan".
  final String sourceLabel;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      style: AppPressStyle.tint,
      semanticLabel: <String>[title, address, sourceLabel].join(', '),
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
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: context.type.callout.copyWith(color: context.colors.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle!, style: context.type.footnote.copyWith(color: context.colors.textSecondary)),
                    LtrText(address, style: context.type.mono.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(sourceLabel),
              const SizedBox(width: AppSpacing.xs),
              AppIcon(
                AppIconName.chevronRight,
                size: AppSizes.iconRowTrailing,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
