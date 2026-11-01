import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A letter that heads an alphabetical group. Use [AppLetterHeader.sliver] in a
/// scrolling list so it stays pinned at the top while its group scrolls.
class AppLetterHeader extends StatelessWidget {
  const AppLetterHeader(this.letter, {super.key});

  /// Pinned header for a [CustomScrollView].
  static Widget sliver(String letter) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LetterHeaderDelegate(letter),
    );
  }

  static const double height = AppSizes.rowMinHeight / 2 + AppSpacing.xs;

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: ColoredBox(
        color: context.colors.bgPrimary,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                letter,
                style: context.type.overline.copyWith(color: context.colors.accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LetterHeaderDelegate(this.letter);

  final String letter;

  @override
  double get minExtent => AppLetterHeader.height;

  @override
  double get maxExtent => AppLetterHeader.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AppLetterHeader(letter);
  }

  @override
  bool shouldRebuild(_LetterHeaderDelegate oldDelegate) => oldDelegate.letter != letter;
}
