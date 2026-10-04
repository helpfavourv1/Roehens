import 'package:flutter/widgets.dart';
import 'package:roehens/ui/icons/app_icons.dart';

/// The one icon widget. Size comes from a size token, color from a color token.
///
/// Pass [semanticLabel] for any icon that conveys meaning; leave it null only for
/// purely decorative icons, which are then hidden from accessibility services.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    super.key,
    required this.size,
    required this.color,
    this.weight = AppIconWeight.bold,
    this.secondaryColor,
    this.semanticLabel,
  });

  final AppIconName name;
  final double size;
  final Color color;
  final AppIconWeight weight;

  /// Tone of the lighter layer of a duotone icon. Defaults to [color].
  final Color? secondaryColor;

  final String? semanticLabel;

  /// Opacity of the secondary layer of a duotone icon.
  static const double _secondaryOpacity = 0.20;

  @override
  Widget build(BuildContext context) {
    final AppIconLayers layers = AppIcons.layers(name, weight);
    final TextDirection? direction =
        name.mirrorsInRtl ? null : TextDirection.ltr;

    final Icon primary = Icon(
      layers.primary,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: direction,
    );

    final IconData? secondary = layers.secondary;
    if (secondary == null) {
      return primary;
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(
          opacity: _secondaryOpacity,
          child: Icon(
            secondary,
            size: size,
            color: secondaryColor ?? color,
            textDirection: direction,
          ),
        ),
        primary,
      ],
    );
  }
}
