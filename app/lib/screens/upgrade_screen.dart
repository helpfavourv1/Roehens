import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

Future<void> openUpgrade(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const UpgradeScreen(),
    ),
  );
}

/// The one-time purchase that removes the Live banner. Never a gate: it is
/// reached from Settings only, restore is always visible, and every state
/// (loading, unavailable, failed, already owned) says so in words.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  late AppProviders _app;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _app = AppScope.of(context);
    // The provider notifies its listeners, so the price loads after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _app.storeConfig.iapSupported) {
        _app.subscription.failure.value = null;
        unawaited(_app.subscription.loadProduct());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.upgradeTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text(
            l10n.upgradeHeadline,
            style: context.type.title1.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.upgradeBody,
            style: context.type.body.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            children: <Widget>[
              for (final String text in <String>[
                l10n.upgradeBenefitBanner,
                l10n.upgradeBenefitOnce,
                l10n.upgradeBenefitSame,
              ])
                AppListRow(
                  title: text,
                  leading: AppIconName.success,
                  showChevron: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _purchase(context, l10n),
        ],
      ),
    );
  }

  Widget _purchase(BuildContext context, AppLocalizations l10n) {
    if (!_app.storeConfig.iapSupported) {
      return AppBanner(
        message: l10n.upgradeUnavailable,
        tone: AppBannerTone.info,
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _app.subscription,
        _app.subscription.product,
        _app.subscription.failure,
        _app.subscription.busy,
      ]),
      builder: (BuildContext context, Widget? _) {
        final Entitlement entitlement = _app.subscription.value;
        final ProductInfo? product = _app.subscription.product.value;
        final AppError? failure = _app.subscription.failure.value;
        final bool busy = _app.subscription.busy.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (entitlement.isAdFree)
              AppBanner(message: l10n.upgradeOwned, tone: AppBannerTone.success)
            else ...<Widget>[
              if (failure != null) ...<Widget>[
                AppBanner(
                  message: errorMessage(l10n, failure),
                  tone: AppBannerTone.error,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (product == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.upgradePriceUnavailable,
                    style: context.type.footnote.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              AppButton(
                label: l10n.upgradeBuy(product?.priceLabel ?? ''),
                expand: true,
                isLoading: busy,
                onPressed: product == null || busy
                    ? null
                    : () => unawaited(_app.subscription.buy()),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.upgradeRestore,
              kind: AppButtonKind.secondary,
              expand: true,
              onPressed: busy
                  ? null
                  : () => unawaited(_app.subscription.restore()),
            ),
          ],
        );
      },
    );
  }
}
