import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';

/// Scrolling without bounce, spring or glow: clamping physics everywhere and no
/// overscroll indicator (specification C1.7).
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Theme builders. The app is hosted on `WidgetsApp`, so there is no Material
/// theme and no ink splash to disable: press feedback is an opacity change
/// implemented once in the component library.
class AppTheme {
  AppTheme._();

  static AppTokensData dark({double scriptFactor = 1.0}) {
    return AppTokensData.resolve(
      brightness: Brightness.dark,
      scriptFactor: scriptFactor,
    );
  }

  static AppTokensData light({double scriptFactor = 1.0}) {
    return AppTokensData.resolve(
      brightness: Brightness.light,
      scriptFactor: scriptFactor,
    );
  }

  /// Default text style for the whole app.
  static TextStyle baseTextStyle(AppTokensData tokens) {
    return tokens.typography.body.copyWith(
      color: tokens.colors.textPrimary,
      decoration: TextDecoration.none,
    );
  }

  /// Transparent system bars with icons that contrast with the theme.
  static SystemUiOverlayStyle overlayStyle(AppTokensData tokens) {
    final Brightness icons = tokens.isDark ? Brightness.light : Brightness.dark;
    final Brightness statusBar =
        tokens.isDark ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarDividerColor: const Color(0x00000000),
      statusBarIconBrightness: icons,
      systemNavigationBarIconBrightness: icons,
      statusBarBrightness: statusBar,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }
}
