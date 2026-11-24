import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/widgets/permission_rationale_view.dart';

/// Explains why local network access is asked for, before the system prompt.
/// If access was refused for good, it turns into the way back to Settings.
/// [onDone] runs when the person moves on, whatever they answered.
class LocalNetworkRationaleScreen extends StatefulWidget {
  const LocalNetworkRationaleScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  /// Whether the person should see this screen for [status]: only where the
  /// system asks (iOS) and has not yet said yes.
  static bool isNeeded(PermissionStatus status) {
    return status != PermissionStatus.granted &&
        status != PermissionStatus.notRequired;
  }

  @override
  State<LocalNetworkRationaleScreen> createState() =>
      _LocalNetworkRationaleScreenState();
}

class _LocalNetworkRationaleScreenState
    extends State<LocalNetworkRationaleScreen> {
  final ValueNotifier<bool> _denied = ValueNotifier<bool>(false);
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
    _denied.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final PermissionStatus status = await _app.permission.requestLocalNetwork();
    unawaited(_app.onboarding.markLocalNetworkRationaleSeen());
    if (!mounted) {
      return;
    }
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      _denied.value = true;
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: _denied,
        builder: (BuildContext context, bool denied, Widget? _) {
          if (denied) {
            return PermissionRationaleView(
              icon: AppIconName.wifiOff,
              title: l10n.rationaleDeniedTitle,
              message: l10n.rationaleDeniedBody,
              reasons: const <String>[],
              primaryLabel: l10n.rationaleOpenSettings,
              onPrimary: () => unawaited(_app.permission.openAppSettings()),
              secondaryLabel: l10n.rationaleNotNow,
              onSecondary: widget.onDone,
            );
          }
          return PermissionRationaleView(
            icon: AppIconName.wifi,
            title: l10n.rationaleTitle,
            message: l10n.rationaleBody,
            reasons: <String>[
              l10n.rationaleReasonOne,
              l10n.rationaleReasonTwo,
              l10n.rationaleReasonThree,
            ],
            primaryLabel: l10n.rationaleContinue,
            onPrimary: () => unawaited(_continue()),
            secondaryLabel: l10n.rationaleNotNow,
            onSecondary: widget.onDone,
          );
        },
      ),
    );
  }
}
