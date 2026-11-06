import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_animated_size.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The banner slot, built to the embed spec (C8.4): the height the ad SDK
/// returned (never more than 100), a gap of 8 above and below, one hairline on
/// the top edge, and nothing at all when there is no ad. It grows and shrinks
/// over 200 ms, so the content above moves once and never jumps.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({
    super.key,
    required this.state,
    required this.viewBuilder,
  });

  final ValueListenable<AdSlotState> state;

  /// Turns the SDK's opaque banner view into a widget (done in the platform
  /// layer, which is the only place that knows the ad SDK).
  final Widget Function(Object view) viewBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdSlotState>(
      valueListenable: state,
      builder: (BuildContext context, AdSlotState slot, Widget? _) {
        final Object? view = slot.view;
        return AppAnimatedSize(
child: slot.isVisible && view != null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colors.borderSubtle,
                        width: AppSizes.hairline,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      height: slot.height.clamp(0, AppSizes.bannerMaxHeight),
                      width: double.infinity,
                      child: viewBuilder(view),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}
