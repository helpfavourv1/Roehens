import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/elevation_tokens.dart';
import 'package:roehens/ui/tokens/typography_tokens.dart';

/// Everything that varies with theme or script, resolved once.
///
/// Spacing, radius, motion and size tokens never vary, so they are static
/// constants on [AppSpacing], [AppRadius], [AppMotion] and [AppSizes].
class AppTokensData {
  const AppTokensData({
    required this.brightness,
    required this.scriptFactor,
    required this.colors,
    required this.typography,
    required this.elevation,
  });

  factory AppTokensData.resolve({
    required Brightness brightness,
    double scriptFactor = 1.0,
  }) {
    final bool isDark = brightness == Brightness.dark;
    return AppTokensData(
      brightness: brightness,
      scriptFactor: scriptFactor,
      colors: isDark ? AppColors.dark : AppColors.light,
      typography: AppTypography.forScript(scriptFactor),
      elevation: isDark ? AppElevation.dark : AppElevation.light,
    );
  }

  final Brightness brightness;
  final double scriptFactor;
  final AppColors colors;
  final AppTypography typography;
  final AppElevation elevation;

  bool get isDark => brightness == Brightness.dark;
}

/// Provides [AppTokensData] to the tree. Read it with [AppTokens.of] or the
/// `context.tokens` extension.
class AppTokens extends InheritedWidget {
  const AppTokens({super.key, required this.data, required super.child});

  final AppTokensData data;

  static AppTokensData of(BuildContext context) {
    final AppTokens? scope =
        context.dependOnInheritedWidgetOfExactType<AppTokens>();
    if (scope == null) {
      throw FlutterError('AppTokens is missing above this context.');
    }
    return scope.data;
  }

  static AppTokensData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTokens>()?.data;
  }

  @override
  bool updateShouldNotify(AppTokens oldWidget) {
    return data.brightness != oldWidget.data.brightness ||
        data.scriptFactor != oldWidget.data.scriptFactor;
  }
}
