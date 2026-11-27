import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/diagnostics_report.dart';
import 'package:roehens/core/services/public_address.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_support.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

Future<void> openNetworkDiagnostics(BuildContext context, HelpActions actions) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const NetworkDiagnosticsScreen(),
    ),
  );
}

/// Five network checks, each on its own button and never run by itself:
/// this phone on the network, a saved camera, a name lookup, a host and port,
/// and the public address the internet sees.
class NetworkDiagnosticsScreen extends StatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  State<NetworkDiagnosticsScreen> createState() =>
      _NetworkDiagnosticsScreenState();
}

class _NetworkDiagnosticsScreenState extends State<NetworkDiagnosticsScreen> {
  final ValueNotifier<DiagnosticsReport> _report =
      ValueNotifier<DiagnosticsReport>(const DiagnosticsReport());
  final ValueNotifier<String?> _cameraId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _hostMissing = ValueNotifier<bool>(false);
  final TextEditingController _host = TextEditingController();
  final TextEditingController _port = TextEditingController(text: '554');
  late AppProviders _app;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _app = AppScope.of(context);
      final List<Camera> cameras = _app.cameras.value.cameras;
      if (cameras.isNotEmpty) {
        _cameraId.value = cameras.first.id;
      }
    }
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _report.dispose();
    _cameraId.dispose();
    _hostMissing.dispose();
    super.dispose();
  }

  Future<void> _run(
    DiagnosticCheck check,
    Future<CheckOutcome> Function() action,
  ) async {
    _report.value = _report.value.withOutcome(
      CheckOutcome(check: check, status: CheckStatus.running),
    );
    final CheckOutcome outcome = await action();
    if (mounted) {
      _report.value = _report.value.withOutcome(outcome);
    }
  }

  bool _hostOk() {
    final bool ok = _host.text.trim().isNotEmpty;
    _hostMissing.value = !ok;
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.diagTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListenableBuilder(
        listenable: _app.flags,
        builder: (BuildContext context, Widget? _) {
          if (!_app.flags.isEnabled('helpContent')) {
            return AppEmptyState(
              icon: AppIconName.warning,
              title: l10n.helpDisabled,
            );
          }
          return ValueListenableBuilder<DiagnosticsReport>(
            valueListenable: _report,
            builder:
                (BuildContext context, DiagnosticsReport report, Widget? _) {
                  return ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      Text(
                        l10n.diagIntro,
                        style: context.type.callout.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _local(context, l10n, report),
                      const SizedBox(height: AppSpacing.md),
                      _lan(context, l10n, report),
                      const SizedBox(height: AppSpacing.md),
                      _host_(context, l10n, report),
                      const SizedBox(height: AppSpacing.md),
                      _hostPort(context, l10n, report),
                      const SizedBox(height: AppSpacing.md),
                      _public(context, l10n, report),
                    ],
                  );
                },
          );
        },
      ),
    );
  }

  /// A check's card: title, what it does, its inputs, the run button and the
  /// result.
  Widget _card({
    required BuildContext context,
    required AppLocalizations l10n,
    required String title,
    required String help,
    required CheckOutcome outcome,
    required VoidCallback? onRun,
    List<Widget> inputs = const <Widget>[],
    List<Widget> result = const <Widget>[],
  }) {
    final bool running = outcome.status == CheckStatus.running;
    final bool ran =
        outcome.status == CheckStatus.passed ||
        outcome.status == CheckStatus.failed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.type.title2.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            help,
            style: context.type.footnote.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          for (final Widget w in inputs) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            w,
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: running
                ? l10n.diagRunning
                : ran
                ? l10n.diagRunAgain
                : l10n.diagRun,
            icon: AppIconName.play,
            kind: AppButtonKind.secondary,
            expand: true,
            isLoading: running,
            onPressed: running ? null : onRun,
          ),
          if (ran) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppBanner(
              message: outcome.status == CheckStatus.passed
                  ? l10n.diagPassed
                  : outcome.error == null
                  ? l10n.diagFailed
                  : '${l10n.diagFailed}: ${errorMessage(l10n, outcome.error!)}',
              tone: outcome.status == CheckStatus.passed
                  ? AppBannerTone.success
                  : AppBannerTone.error,
            ),
            ...result,
          ],
        ],
      ),
    );
  }

  Widget _value(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.type.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          LtrBlock(
            value,
            style: context.type.mono.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _local(
    BuildContext context,
    AppLocalizations l10n,
    DiagnosticsReport r,
  ) {
    final CheckOutcome out = r.of(DiagnosticCheck.localNetwork);
    final List<String> lines = (out.detail ?? '').split('\n');
    return _card(
      context: context,
      l10n: l10n,
      title: l10n.diagLocalTitle,
      help: l10n.diagLocalHelp,
      outcome: out,
      onRun: () => unawaited(
        _run(DiagnosticCheck.localNetwork, _app.networkChecks.localNetwork),
      ),
      result: <Widget>[
        if (out.status == CheckStatus.passed && lines.isNotEmpty)
          _value(context, l10n.diagLocalAddress, lines.first),
        if (out.status == CheckStatus.passed && lines.length > 1)
          _value(context, l10n.diagLocalGateway, lines[1]),
      ],
    );
  }

  Widget _lan(
    BuildContext context,
    AppLocalizations l10n,
    DiagnosticsReport r,
  ) {
    final List<Camera> cameras = _app.cameras.value.cameras;
    return ValueListenableBuilder<String?>(
      valueListenable: _cameraId,
      builder: (BuildContext context, String? chosen, Widget? _) {
        return _card(
          context: context,
          l10n: l10n,
          title: l10n.diagLanTitle,
          help: cameras.isEmpty ? l10n.diagLanNoCameras : l10n.diagLanHelp,
          outcome: r.of(DiagnosticCheck.lanReachability),
          onRun: cameras.isEmpty || chosen == null
              ? null
              : () => unawaited(_runLan(chosen)),
          inputs: <Widget>[
            if (cameras.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final Camera c in cameras)
                    AppChip(
                      label: c.name,
                      selected: c.id == chosen,
                      onTap: () => _cameraId.value = c.id,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _runLan(String id) async {
    final Camera? camera = _app.cameras.value.byId(id);
    if (camera == null) {
      return;
    }
    await _run(DiagnosticCheck.lanReachability, () async {
      final CameraCredentials credentials =
          (await _app.repository.credentialsFor(camera.id)).valueOrNull ??
          CameraCredentials.none;
      return _app.networkChecks.lanReachability(camera, credentials);
    });
  }

  Widget _hostField(AppLocalizations l10n) {
    return ValueListenableBuilder<bool>(
      valueListenable: _hostMissing,
      builder: (BuildContext context, bool missing, Widget? _) {
        return AppTextField(
          controller: _host,
          label: l10n.diagHostField,
          errorText: missing ? l10n.diagHostRequired : null,
          keyboardType: TextInputType.url,
          forceLtr: true,
          onChanged: (String _) => _hostMissing.value = false,
        );
      },
    );
  }

  Widget _host_(
    BuildContext context,
    AppLocalizations l10n,
    DiagnosticsReport r,
  ) {
    final CheckOutcome out = r.of(DiagnosticCheck.hostResolution);
    return _card(
      context: context,
      l10n: l10n,
      title: l10n.diagHostTitle,
      help: l10n.diagHostHelp,
      outcome: out,
      inputs: <Widget>[_hostField(l10n)],
      onRun: () {
        if (_hostOk()) {
          unawaited(
            _run(
              DiagnosticCheck.hostResolution,
              () => _app.networkChecks.hostResolution(_host.text.trim()),
            ),
          );
        }
      },
      result: <Widget>[
        if (out.status == CheckStatus.passed && out.detail != null)
          _value(context, l10n.diagResolved, out.detail!),
      ],
    );
  }

  Widget _hostPort(
    BuildContext context,
    AppLocalizations l10n,
    DiagnosticsReport r,
  ) {
    final CheckOutcome out = r.of(DiagnosticCheck.hostPort);
    return _card(
      context: context,
      l10n: l10n,
      title: l10n.diagHostPortTitle,
      help: l10n.diagHostPortHelp,
      outcome: out,
      inputs: <Widget>[
        _hostField(l10n),
        AppTextField(
          controller: _port,
          label: l10n.diagPortField,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          forceLtr: true,
        ),
      ],
      onRun: () {
        final int? port = int.tryParse(_port.text.trim());
        if (_hostOk() && port != null && port >= 1 && port <= 65535) {
          unawaited(
            _run(
              DiagnosticCheck.hostPort,
              () => _app.networkChecks.hostPort(_host.text.trim(), port),
            ),
          );
        }
      },
      result: <Widget>[
        if (out.status == CheckStatus.passed && out.detail != null)
          _value(context, l10n.diagTime, out.detail!),
      ],
    );
  }

  String _kindText(AppLocalizations l10n, AddressKind kind) {
    return switch (kind) {
      AddressKind.public => l10n.diagKindPublic,
      AddressKind.private => l10n.diagKindPrivate,
      AddressKind.shared => l10n.diagKindShared,
      _ => l10n.diagKindOther,
    };
  }

  Widget _public(
    BuildContext context,
    AppLocalizations l10n,
    DiagnosticsReport r,
  ) {
    final CheckOutcome out = r.of(DiagnosticCheck.publicAddress);
    final String? address = out.status == CheckStatus.passed
        ? out.detail
        : null;
    return _card(
      context: context,
      l10n: l10n,
      title: l10n.diagPublicTitle,
      help: l10n.diagPublicHelp,
      outcome: out,
      onRun: () => unawaited(
        _run(DiagnosticCheck.publicAddress, _app.networkChecks.publicAddress),
      ),
      result: <Widget>[
        if (address != null) ...<Widget>[
          _value(context, l10n.diagPublicTitle, address),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _kindText(l10n, PublicAddress.classify(address)),
            style: context.type.body.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.diagPublicCompare,
            style: context.type.footnote.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
