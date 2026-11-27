import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A tappable card with a title and an optional line under it: the hub's four
/// cards, and each answer of the troubleshooter.
class HelpChoiceCard extends StatelessWidget {
  const HelpChoiceCard({
    super.key,
    required this.title,
    required this.onTap,
    this.body,
    this.icon,
  });

  final String title;
  final String? body;
  final AppIconName? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      semanticLabel: <String>[title, ?body].join('. '),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              AppIcon(
                icon!,
                size: AppSizes.iconRowLeading,
                color: context.colors.accent,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.type.title2.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (body != null)
                    Text(
                      body!,
                      style: context.type.footnote.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
