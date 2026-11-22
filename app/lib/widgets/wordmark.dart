import 'package:flutter/widgets.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The product name in the Display role. It appears once per screen, in the
/// Live nav bar (C8.7), and on onboarding page 1.
class Wordmark extends StatelessWidget {
  const Wordmark(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.type.headline.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
