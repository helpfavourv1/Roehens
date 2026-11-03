import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The surface of a bottom sheet: elevated fill, rounded top corners only, a
/// hairline on the top edge, and in light mode the sheet shadow.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  /// Tallest a sheet gets, as a share of the screen.
  static const double maxHeightFactor = 0.9;

  @override
  Widget build(BuildContext context) {
    final AppTokensData tokens = context.tokens;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double maxHeight =
        MediaQuery.sizeOf(context).height * maxHeightFactor;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.bgElevated,
            borderRadius: AppRadius.sheetTop,
            boxShadow: tokens.elevation.sheet,
            border: Border(
              top: BorderSide(
                color: tokens.colors.borderSubtle,
                width: AppSizes.hairline,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: keyboard > 0 ? keyboard : safe.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (title != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      title!,
                      style: context.type.title2.copyWith(
                        color: tokens.colors.textPrimary,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: AppSpacing.sm),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents [builder] as a bottom sheet. Closes on a tap outside, on Escape and
/// on the system back gesture. [dismissLabel] is the spoken name of the
/// scrim, for example "Close".
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required String dismissLabel,
  String? title,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppModalRoute<T>(
      scrim: context.colors.scrim,
      motion: AppModalMotion.slideUp,
      dismissLabel: dismissLabel,
      reduceMotion: context.reduceMotion,
      builder: (BuildContext context) =>
          AppSheet(title: title, child: builder(context)),
    ),
  );
}
