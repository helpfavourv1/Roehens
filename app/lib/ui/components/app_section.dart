import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_divider.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A section: an overline header, a group of rows on one card with hairlines
/// between them, and an optional footnote.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.children,
    this.title,
    this.footer,
    this.inset = 0,
  });

  final List<Widget> children;
  final String? title;
  final String? footer;

  /// Start inset of the hairlines, to line them up with the row text.
  final double inset;

  /// Upper-cases only scripts that have case; for the others the text is shown
  /// as written.
  static String overlineText(String text) {
    final String upper = text.toUpperCase();
    final bool hasCase = upper != text.toLowerCase();
    return hasCase ? upper : text;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> grouped = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        grouped.add(AppDivider(inset: inset));
      }
      grouped.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              overlineText(title!),
              style: context.type.overline.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.bgSecondary,
            borderRadius: AppRadius.allLg,
            border: Border.all(
              color: context.colors.borderSubtle,
              width: AppSizes.hairline,
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.allLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: grouped,
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
              top: AppSpacing.sm,
            ),
            child: Text(
              footer!,
              style: context.type.footnote.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

/// A section header with nothing grouped under it, for forms whose fields are
/// separate inputs rather than rows of one card.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          AppSection.overlineText(text),
          style: context.type.overline.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
