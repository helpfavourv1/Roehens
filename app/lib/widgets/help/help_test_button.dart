import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';

/// Where a step's test stands.
enum HelpTestState { idle, running, passed, failed }

/// "Test this step": runs the connection tester for the step and shows the
/// plain-language result under the button.
class HelpTestButton extends StatelessWidget {
  const HelpTestButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
    this.passedText,
    this.failedText,
  });

  final String label;
  final HelpTestState state;
  final VoidCallback onPressed;
  final String? passedText;
  final String? failedText;

  @override
  Widget build(BuildContext context) {
    final bool running = state == HelpTestState.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          label: label,
          icon: AppIconName.play,
          kind: AppButtonKind.secondary,
          expand: true,
          isLoading: running,
          onPressed: running ? null : onPressed,
        ),
        if (state == HelpTestState.passed && passedText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppBanner(message: passedText!, tone: AppBannerTone.success),
        ],
        if (state == HelpTestState.failed && failedText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppBanner(message: failedText!, tone: AppBannerTone.error),
        ],
      ],
    );
  }
}
