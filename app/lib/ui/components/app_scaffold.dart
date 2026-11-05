import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/app_theme.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The frame of every screen: the scaffold color, an optional nav bar, the
/// content, and a bottom stack of an optional embed (the ad slot) above an
/// optional bottom bar.
///
/// Safe areas are protected at the top and bottom. While the keyboard is open
/// the whole bottom stack collapses and returns when it closes, so content
/// above never gets squeezed by bars (C8.4).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.navBar,
    this.bottomEmbed,
    this.bottomBar,
    this.immersive = false,
  });

  final Widget body;
  final Widget? navBar;

  /// Sits directly above the bottom bar; collapses to nothing when empty.
  final Widget? bottomEmbed;
  final Widget? bottomBar;

  /// Fullscreen video: no safe-area padding at all.
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double keyboard = media.viewInsets.bottom;
    final bool keyboardUp = keyboard > 0;
    final bool hasBottomStack = bottomBar != null || bottomEmbed != null;

    final double top = immersive ? 0 : media.padding.top;
    final double bottomPadding = immersive
        ? 0
        : keyboardUp
        ? keyboard
        : (bottomBar == null ? media.padding.bottom : 0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status and navigation bar icons contrast with the theme (white icons on
      // a light screen are invisible), and the bars are transparent.
      value: AppTheme.overlayStyle(context.tokens),
      child: ColoredBox(
      color: context.colors.bgPrimary,
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ?navBar,
            Expanded(child: body),
            if (hasBottomStack)
              AnimatedSize(
                duration: context.motion(AppMotion.adSlot),
                curve: AppMotion.settle,
                alignment: Alignment.topCenter,
                child: keyboardUp || immersive
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[?bottomEmbed, ?bottomBar],
                      ),
              ),
          ],
        ),
      ),
    ));
  }
}
