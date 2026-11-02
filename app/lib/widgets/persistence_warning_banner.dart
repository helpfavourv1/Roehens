import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/providers/persistence_health_provider.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The persistent warning when local storage is not working: saved cameras may
/// not survive closing the app. It stays until the problem is gone and offers
/// one way out (for example exporting what is on screen).
class PersistenceWarningBanner extends StatelessWidget {
  const PersistenceWarningBanner({
    super.key,
    required this.issue,
    required this.degradedMessage,
    required this.updateMessage,
    this.actionLabel,
    this.onAction,
  });

  final ValueListenable<PersistenceIssue> issue;
  final String degradedMessage;
  final String updateMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PersistenceIssue>(
      valueListenable: issue,
      builder: (BuildContext context, PersistenceIssue current, Widget? _) {
        final Widget? banner = switch (current) {
          PersistenceIssue.none => null,
          PersistenceIssue.degraded => AppBanner(
              message: degradedMessage,
              tone: AppBannerTone.warning,
              actionLabel: actionLabel,
              onAction: onAction,
            ),
          PersistenceIssue.updateRequired => AppBanner(
              message: updateMessage,
              tone: AppBannerTone.error,
            ),
        };
        return AnimatedSize(
          duration: context.motion(AppMotion.adSlot),
          curve: AppMotion.settle,
          alignment: Alignment.topCenter,
          child: banner == null
              ? const SizedBox(width: double.infinity)
              : Padding(padding: AppSpacing.allMd, child: banner),
        );
      },
    );
  }
}
