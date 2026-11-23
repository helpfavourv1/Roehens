import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/providers/discovery_provider.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_progress.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/discovery_result_row.dart';
import 'package:roehens/widgets/permission_rationale_view.dart';

/// Opens network discovery. The screen closes itself first, then calls
/// [onPick] with the camera the person tapped, or [onManual] when they chose
/// to type the address themselves.
Future<void> openDiscovery(
  BuildContext context, {
  required ValueChanged<DiscoveryResult> onPick,
  required VoidCallback onManual,
}) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext route) => DiscoveryScreen(
        onPick: (DiscoveryResult found) {
          Navigator.of(route).pop();
          onPick(found);
        },
        onManual: () {
          Navigator.of(route).pop();
          onManual();
        },
      ),
    ),
  );
}

/// Looks for cameras on the network and lists them as they answer.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.onPick,
    required this.onManual,
  });

  final ValueChanged<DiscoveryResult> onPick;
  final VoidCallback onManual;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
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
    // The provider notifies its listeners, so the scan starts after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_app.discovery.start());
      }
    });
  }

  @override
  void dispose() {
    final AppProviders app = _app;
    scheduleMicrotask(() {
      unawaited(app.discovery.cancel());
      app.discovery.clear();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.discoveryTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ValueListenableBuilder<DiscoveryState>(
        valueListenable: _app.discovery,
        builder: (BuildContext context, DiscoveryState state, Widget? _) {
          return switch (state.status) {
            DiscoveryStatus.disabled => AppEmptyState(
              icon: AppIconName.warning,
              title: l10n.discoveryDisabled,
              actionLabel: l10n.discoveryManual,
              onAction: widget.onManual,
            ),
            DiscoveryStatus.permissionDenied => PermissionRationaleView(
              title: l10n.discoveryPermissionTitle,
              message: l10n.discoveryPermissionBody,
              primaryLabel: l10n.discoveryOpenSettings,
              onPrimary: () => unawaited(_app.permission.openAppSettings()),
              secondaryLabel: l10n.discoveryManual,
              onSecondary: widget.onManual,
            ),
            _ => _content(context, l10n, state),
          };
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    DiscoveryState state,
  ) {
    final bool nothing = state.foundNothing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: state.isScanning
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.discoveryScanning,
                      style: context.type.callout.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppProgress.bar(
                      value: state.progress.clamp(0, 1),
                      semanticLabel: l10n.discoveryScanning,
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.discoveryFound(state.results.length),
                        style: context.type.callout.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    AppButton(
                      label: l10n.discoveryRescan,
                      icon: AppIconName.refresh,
                      kind: AppButtonKind.secondary,
                      onPressed: () => unawaited(_app.discovery.start()),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: nothing
              ? AppEmptyState(
                  icon: AppIconName.scanNetwork,
                  title: l10n.discoveryNone,
                  message: l10n.discoveryNoneBody,
                )
              : ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  children: <Widget>[
                    if (state.results.isNotEmpty)
                      AppSection(
                        children: <Widget>[
                          for (final DiscoveryResult found in state.results)
                            DiscoveryResultRow(
                              title: found.name ?? found.host,
                              address: cameraAddress(found.host, found.port),
                              subtitle: found.model,
                              sourceLabel: switch (found.source) {
                                DiscoverySource.onvif =>
                                  l10n.discoverySourceOnvif,
                                DiscoverySource.sweep =>
                                  l10n.discoverySourceSweep,
                              },
                              onTap: () => widget.onPick(found),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: l10n.discoveryManual,
            kind: AppButtonKind.secondary,
            expand: true,
            onPressed: widget.onManual,
          ),
        ),
      ],
    );
  }
}
