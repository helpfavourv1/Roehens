import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A hairline. [inset] leaves space at the start edge (for example under a
/// row's icon) and follows the reading direction.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.inset = 0});

  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: inset),
      child: SizedBox(
        height: AppSizes.hairline,
        width: double.infinity,
        child: ColoredBox(color: context.colors.borderSubtle),
      ),
    );
  }
}
