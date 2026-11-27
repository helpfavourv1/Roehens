import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/icons/app_icons.dart';

/// A button that takes the person somewhere inside Roehens, or to the phone's
/// own Settings. Help has no button that leaves the app for the web.
class HelpDeepLinkButton extends StatelessWidget {
  const HelpDeepLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIconName.chevronRight,
  });

  final String label;
  final VoidCallback onPressed;
  final AppIconName icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      kind: AppButtonKind.secondary,
      expand: true,
      onPressed: onPressed,
    );
  }
}
