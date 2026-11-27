import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_banner.dart';

/// A short aside inside a Help step: a warning or a tip, set apart from the
/// step's own text. Icon, text and color together, like every status.
class HelpCallout extends StatelessWidget {
  const HelpCallout(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppBanner(message: text, tone: AppBannerTone.info);
  }
}
