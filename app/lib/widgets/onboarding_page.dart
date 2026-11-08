import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/first_line_icon.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// One page of onboarding: an optional header (the wordmark appears here on
/// page one only), a duotone hero icon, a title, a message and short points.
/// It scrolls when the text is very large, and the hero never takes more than a
/// third of the height.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.header,
    this.points = const <String>[],
  });

  final AppIconName icon;
  final String title;
  final String message;

  /// The brand wordmark, on the first page only.
  final Widget? header;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double heroBox = box.hasBoundedHeight
            ? box.maxHeight / 3
            : AppSizes.iconHero * 3;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: AppSpacing.allLg,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.hasBoundedHeight
                  ? box.maxHeight - AppSpacing.lg * 2
                  : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (header != null) ...<Widget>[
                      Center(child: header),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    SizedBox(
                      height: heroBox.clamp(
                        AppSizes.iconHero,
                        AppSizes.iconHero * 2,
                      ),
                      child: Center(
                        child: AppIcon(
                          icon,
                          size: AppSizes.iconHero * 2,
                          color: colors.textSecondary,
                          weight: AppIconWeight.duotone,
                          secondaryColor: colors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: context.type.headline.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: context.type.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (points.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      for (final String point in points)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FirstLineIcon(
                                icon: AppIconName.check,
                                size: AppSizes.iconRowTrailing,
                                color: colors.success,
                                textStyle: context.type.body,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  point,
                                  style: context.type.body.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
