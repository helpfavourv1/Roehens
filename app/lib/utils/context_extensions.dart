import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/ui/tokens/typography_tokens.dart';

/// Shorthand for the values every widget needs.
extension AppContext on BuildContext {
  AppTokensData get tokens => AppTokens.of(this);

  AppColors get colors => AppTokens.of(this).colors;

  AppTypography get type => AppTokens.of(this).typography;

  bool get isTablet {
    return MediaQuery.sizeOf(this).shortestSide >= AppSizes.tabletShortestSide;
  }

  /// True when the person asked the system to reduce motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// [duration], or zero when motion is reduced.
  Duration motion(Duration duration) {
    return AppMotion.resolve(duration, reduceMotion: reduceMotion);
  }

  double get gridGutter {
    return isTablet ? AppSpacing.gridGutterTablet : AppSpacing.gridGutterPhone;
  }
}
