import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A small picture of the app in one theme, with its name under it. System
/// shows the light and dark pictures side by side.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.light,
    required this.dark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Whether the picture includes the light theme, the dark theme, or both.
  final bool light;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      selected: selected,
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: AppSizes.themePreviewAspect,
              child: ClipRRect(
                borderRadius: AppRadius.allMd,
                child: Row(
                  children: <Widget>[
                    if (light)
                      Expanded(child: _Mock(brightness: Brightness.light)),
                    if (dark)
                      Expanded(child: _Mock(brightness: Brightness.dark)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: context.type.callout.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                ExcludeSemantics(
                  child: AppIcon(
                    AppIconName.check,
                    size: AppSizes.iconRowTrailing,
                    color: context.colors.accent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The mock screen: a scaffold, one video tile and two lines of text, drawn
/// with the colors of the theme it shows, whatever theme the app is in.
class _Mock extends StatelessWidget {
  const _Mock({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppTokensData.resolve(brightness: brightness).colors;
    return ColoredBox(
      color: c.bgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.videoBackdrop,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(color: c.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.7,
              child: SizedBox(
                height: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.textPrimary,
                    borderRadius: AppRadius.allXs,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.45,
              child: SizedBox(
                height: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: AppRadius.allXs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
