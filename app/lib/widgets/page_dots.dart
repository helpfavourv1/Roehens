import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Page indicator under a paged grid. It is announced as one element
/// ("Page 2 of 3") and offers increase and decrease actions to screen readers.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.current,
    required this.semanticLabel,
    this.onNext,
    this.onPrevious,
    this.nextLabel,
    this.previousLabel,
  });

  final int count;
  final int current;
  final String semanticLabel;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final String? nextLabel;
  final String? previousLabel;

  @override
  Widget build(BuildContext context) {
    if (count < 2) {
      // One page needs no indicator: nothing is drawn.
      return const SizedBox.shrink();
    }
    final AppColors colors = context.colors;
    final Duration fade = context.motion(AppMotion.tileConnect);
    return Semantics(
      container: true,
      label: semanticLabel,
      onIncrease: onNext,
      onDecrease: onPrevious,
      increasedValue: nextLabel,
      decreasedValue: previousLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  child: AnimatedContainer(
                    duration: fade,
                    curve: AppMotion.settle,
                    width: AppSizes.pageDot,
                    height: AppSizes.pageDot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == current ? colors.accent : colors.borderStrong,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
