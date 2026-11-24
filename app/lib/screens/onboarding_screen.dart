import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/onboarding_page.dart';
import 'package:roehens/widgets/page_dots.dart';
import 'package:roehens/widgets/wordmark.dart';

/// Three pages: what Roehens does; the honest limits (your network, while it
/// is open); and the start. The product name shows on page 1 only. Finishing
/// records it, then [onFinished] moves on to the local network explanation.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pages = 3;
  final ValueNotifier<int> _page = ValueNotifier<int>(0);
  late AppProviders _app;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _app = AppScope.of(context);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await _app.onboarding.complete();
    if (mounted) {
      widget.onFinished();
    }
  }

  void _next() {
    unawaited(_app.haptics.light());
    if (_page.value < _pages - 1) {
      _page.value++;
    } else {
      unawaited(_finish());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: _page,
        builder: (BuildContext context, int page, Widget? _) {
          final bool last = page == _pages - 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: last
                      ? const SizedBox(height: AppSpacing.xl)
                      : AppButton(
                          label: l10n.onboardingSkip,
                          kind: AppButtonKind.secondary,
                          onPressed: () => unawaited(_finish()),
                        ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: context.motion(AppMotion.autoCycle),
                  switchInCurve: AppMotion.settle,
                  switchOutCurve: AppMotion.settle,
                  child: KeyedSubtree(
                    key: ValueKey<int>(page),
                    child: _pageFor(page, l10n),
                  ),
                ),
              ),
              PageDots(
                count: _pages,
                current: page,
                pageLabel: (int i) => l10n.onboardingPageOf(i + 1, _pages),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: last ? l10n.onboardingStart : l10n.onboardingNext,
                  expand: true,
                  onPressed: _next,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pageFor(int page, AppLocalizations l10n) {
    return switch (page) {
      0 => OnboardingPage(
        icon: AppIconName.cameraDome,
        header: Wordmark(l10n.appName),
        title: l10n.onboardingOneTitle,
        message: l10n.onboardingOneBody,
        points: <String>[
          l10n.onboardingOnePointOne,
          l10n.onboardingOnePointTwo,
        ],
      ),
      1 => OnboardingPage(
        icon: AppIconName.wifi,
        title: l10n.onboardingTwoTitle,
        message: l10n.onboardingTwoBody,
        points: <String>[
          l10n.onboardingTwoPointOne,
          l10n.onboardingTwoPointTwo,
        ],
      ),
      _ => OnboardingPage(
        icon: AppIconName.scanNetwork,
        title: l10n.onboardingThreeTitle,
        message: l10n.onboardingThreeBody,
      ),
    };
  }
}
