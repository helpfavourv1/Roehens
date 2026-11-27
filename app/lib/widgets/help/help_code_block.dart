import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A value to copy: a port, a range, an address. The value is in the Mono
/// face and always left-to-right, even in right-to-left languages. A copy
/// button sits at the end.
class HelpCodeBlock extends StatelessWidget {
  const HelpCodeBlock({
    super.key,
    required this.value,
    required this.copyLabel,
    this.caption,
    this.onCopied,
  });

  final String value;

  /// What a screen reader says for the copy button.
  final String copyLabel;

  /// What the value is, in the person's language, shown under it.
  final String? caption;

  /// Called after the value was put on the clipboard.
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: colors.borderStrong, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LtrText(
                    value,
                    maxLines: 3,
                    style: context.type.mono.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: context.type.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIconName.copy,
              semanticLabel: copyLabel,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                onCopied?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
