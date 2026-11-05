import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The bar at the top of a screen: back or brand at the start, the title, and
/// actions at the end as 40x40 chips. It is 56 high and has a hairline below.
/// The brand wordmark belongs here only on Live (C8.7), as [leading].
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    this.title,
    this.leading,
    this.onBack,
    this.backLabel,
    this.actions = const <Widget>[],
  }) : assert(
         onBack == null || backLabel != null,
         'A back button needs a spoken label.',
       );

  final String? title;

  /// Replaces the back button, for example the wordmark on Live.
  final Widget? leading;
  final VoidCallback? onBack;

  /// Spoken name of the back button, for example "Back".
  final String? backLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final Widget? start =
        leading ??
        (onBack == null
            ? null
            : AppIconButton(
                icon: AppIconName.back,
                semanticLabel: backLabel!,
                onPressed: onBack,
              ));
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderSubtle,
            width: AppSizes.hairline,
          ),
        ),
      ),
      child: SizedBox(
        height: AppSizes.navBarHeight,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              if (start != null) ...<Widget>[
                start,
                SizedBox(
                  width: leading != null ? AppSpacing.md : AppSpacing.xs,
                ),
              ],
              Expanded(
                child: title == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: start == null ? AppSpacing.sm : 0,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.type.title2.copyWith(
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
              ),
              for (final Widget action in actions) action,
            ],
          ),
        ),
      ),
    );
  }
}
