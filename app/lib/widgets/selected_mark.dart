import 'package:flutter/widgets.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The check at the end of the chosen row in a list of choices. Decorative:
/// the row itself reports that it is selected.
class SelectedMark extends StatelessWidget {
  const SelectedMark({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AppIcon(
        AppIconName.check,
        size: AppSizes.iconRowTrailing,
        color: context.colors.accent,
      ),
    );
  }
}
