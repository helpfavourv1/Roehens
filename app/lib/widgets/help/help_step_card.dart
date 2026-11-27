import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// One step of an article: a number, the text, and whatever the step carries
/// (a callout, values to copy, buttons). The step's parts come in as widgets
/// so this card knows nothing of Help's data.
class HelpStepCard extends StatelessWidget {
  const HelpStepCard({
    super.key,
    required this.number,
    required this.numberLabel,
    required this.text,
    this.children = const <Widget>[],
  });

  final int number;

  /// Spoken form of the number, for example "Step 3".
  final String numberLabel;
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: numberLabel,
            child: ExcludeSemantics(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppBadge('$number', tone: AppBadgeTone.accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: context.type.body.copyWith(color: context.colors.textPrimary),
          ),
          for (final Widget child in children) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ],
      ),
    );
  }
}
