import 'package:flutter/widgets.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';

/// An icon centered on the first line of the text beside it. A plain icon at
/// the top of a row sits above the text's first line when the text grows with
/// the person's text size.
class FirstLineIcon extends StatelessWidget {
  const FirstLineIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    required this.textStyle,
    this.weight = AppIconWeight.bold,
  });

  final AppIconName icon;
  final double size;
  final Color color;

  /// The style of the text the icon sits beside.
  final TextStyle textStyle;
  final AppIconWeight weight;

  @override
  Widget build(BuildContext context) {
    final double fontSize = textStyle.fontSize ?? size;
    final double lineHeight = MediaQuery.textScalerOf(
      context,
    ).scale(fontSize * (textStyle.height ?? 1.2));
    return SizedBox(
      height: lineHeight < size ? size : lineHeight,
      child: Center(
        child: AppIcon(icon, size: size, color: color, weight: weight),
      ),
    );
  }
}
