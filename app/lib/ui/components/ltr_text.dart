import 'package:flutter/widgets.dart';

/// Text for technical values (addresses, ports, resolutions, bitrates, paths)
/// that must read left-to-right even inside a right-to-left layout.
class LtrText extends StatelessWidget {
  const LtrText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textScaler,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextScaler? textScaler;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
      style: style,
    );
  }
}

/// A block of selectable text that always reads left-to-right, for legal
/// notices and diagnostics that are English or technical whatever the app
/// language is.
class LtrBlock extends StatelessWidget {
  const LtrBlock(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SelectableText(text, style: style),
    );
  }
}
