import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/help_article.dart';
import 'package:roehens/core/models/troubleshoot_node.dart';
import 'package:roehens/core/services/help_catalog.dart';
import 'package:roehens/core/services/url_builder.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/help/help_article_screen.dart';
import 'package:roehens/screens/help/help_support.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/help/help_choice_card.dart';
import 'package:roehens/widgets/help/help_step_card.dart';
import 'package:roehens/widgets/help/help_test_button.dart';

Future<void> openRemoteAccessWizard(BuildContext context, HelpActions actions) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => RemoteAccessWizardScreen(actions: actions),
    ),
  );
}

/// One way of reaching a camera away from home, one step at a time. Every
/// step has "Test this step", which runs the connection tester for a saved
/// camera and the address and port typed here, so the person can check each
/// stage of the setup, on mobile data, as they go.
class RemoteAccessWizardScreen extends StatefulWidget {
  const RemoteAccessWizardScreen({super.key, required this.actions});

  final HelpActions actions;

  @override
  State<RemoteAccessWizardScreen> createState() =>
      _RemoteAccessWizardScreenState();
}

class _RemoteAccessWizardScreenState extends State<RemoteAccessWizardScreen> {
  final ValueNotifier<String?> _path = ValueNotifier<String?>(null);
  final ValueNotifier<int> _step = ValueNotifier<int>(0);
  final ValueNotifier<String?> _cameraId = ValueNotifier<String?>(null);
  final ValueNotifier<HelpTestState> _test = ValueNotifier<HelpTestState>(
    HelpTestState.idle,
  );
  final ValueNotifier<String?> _failure = ValueNotifier<String?>(null);
  final TextEditingController _host = TextEditingController();
  final TextEditingController _port = TextEditingController();
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
        _pick(cameras.first);
      }
    }
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    for (final ChangeNotifier n in <ChangeNotifier>[
      _path,
      _step,
      _cameraId,
      _test,
      _failure,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  void _pick(Camera camera) {
    _cameraId.value = camera.id;
    _host.text = camera.host;
    _port.text = '${camera.port}';
    _test.value = HelpTestState.idle;
  }

  Future<void> _runTest() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Camera? saved = _app.cameras.value.byId(_cameraId.value ?? '');
    if (saved == null) {
      return;
    }
    final String host = _host.text.trim();
    final int? port = int.tryParse(_port.text.trim());
    if (!UrlBuilder.isValidHost(host) ||
        port == null ||
        port < 1 ||
        port > 65535) {
      _failure.value = !UrlBuilder.isValidHost(host)
          ? l10n.editHostInvalid
          : l10n.editPortInvalid;
      _test.value = HelpTestState.failed;
      return;
    }
    _test.value = HelpTestState.running;
    final CameraCredentials credentials =
        (await _app.repository.credentialsFor(saved.id)).valueOrNull ??
        CameraCredentials.none;
    final ConnectionTestResult result = await _app.connectionTester.run(
      saved.copyWith(host: host, port: port),
      credentials,
    );
    if (!mounted) {
      return;
    }
    _failure.value = result.error == null
        ? null
        : errorMessage(l10n, result.error!);
    _test.value = result.passed ? HelpTestState.passed : HelpTestState.failed;
  }

  void _go(int step) {
    _step.value = step;
    _test.value = HelpTestState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return HelpContent(
      builder:
          (BuildContext context, HelpCatalog catalog, HelpStrings strings) {
            return ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[_path, _app.flags]),
              builder: (BuildContext context, Widget? _) {
                return AppScaffold(
                  navBar: AppNavBar(
                    title: l10n.wizardTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                    backLabel: l10n.actionBack,
                  ),
                  body: _body(context, l10n, catalog, strings),
                );
              },
            );
          },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    HelpCatalog catalog,
    HelpStrings strings,
  ) {
    if (!_app.flags.isEnabled('helpContent')) {
      return AppEmptyState(icon: AppIconName.warning, title: l10n.helpDisabled);
    }
    if (_app.cameras.value.cameras.isEmpty) {
      return AppEmptyState(
        icon: AppIconName.cameraDome,
        title: l10n.wizardNoCameras,
        actionLabel: l10n.actionAddCamera,
        onAction: widget.actions.onAddCamera,
      );
    }
    final String? pathId = _path.value;
    if (pathId == null) {
      return ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppSectionTitle(l10n.wizardChoosePath),
          for (final WizardPath p in catalog.wizardPaths) ...<Widget>[
            HelpChoiceCard(
              icon: AppIconName.route,
              title: strings.text(HelpCatalog.titleKey(p.articleId)),
              body: strings.text(HelpCatalog.summaryKey(p.articleId)),
              onTap: () {
                _step.value = 0;
                _test.value = HelpTestState.idle;
                _path.value = p.id;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }
    final HelpArticle article = catalog.article(
      catalog.wizardPaths
          .firstWhere((WizardPath p) => p.id == pathId)
          .articleId,
    )!;
    return _steps(context, l10n, strings, article);
  }

  Widget _steps(
    BuildContext context,
    AppLocalizations l10n,
    HelpStrings strings,
    HelpArticle article,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _step,
        _test,
        _cameraId,
        _failure,
      ]),
      builder: (BuildContext context, Widget? _) {
        final int index = _step.value;
        final HelpStep step = article.steps[index];
        final bool last = index == article.steps.length - 1;
        final HelpArticleScreen view = HelpArticleScreen(
          articleId: article.id,
          actions: widget.actions,
        );
        return ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              strings.text(HelpCatalog.titleKey(article.id)),
              style: context.type.title1.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.wizardStepOf(index + 1, article.steps.length),
              style: context.type.footnote.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HelpStepCard(
              number: index + 1,
              numberLabel: l10n.helpStepNumber(index + 1),
              text: strings.text(HelpCatalog.stepKey(article.id, step.id)),
              children: <Widget>[
                ...view.stepParts(context, l10n, strings, article, step),
                HelpTestButton(
                  label: l10n.wizardTestStep,
                  state: _test.value,
                  onPressed: () => unawaited(_runTest()),
                  passedText: l10n.wizardTestPassed,
                  failedText: _failure.value == null
                      ? l10n.wizardTestFailed
                      : '${l10n.wizardTestFailed} ${_failure.value}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _target(context, l10n),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: l10n.wizardPrevious,
                    kind: AppButtonKind.secondary,
                    onPressed: index == 0 ? null : () => _go(index - 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l10n.wizardNext,
                    onPressed: last ? null : () => _go(index + 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.wizardOtherPath,
              kind: AppButtonKind.secondary,
              expand: true,
              onPressed: () => _path.value = null,
            ),
          ],
        );
      },
    );
  }

  Widget _target(BuildContext context, AppLocalizations l10n) {
    final List<Camera> cameras = _app.cameras.value.cameras;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionTitle(l10n.wizardCameraSection),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final Camera c in cameras)
              AppChip(
                label: c.name,
                selected: c.id == _cameraId.value,
                onTap: () => _pick(c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _host,
          label: l10n.wizardAddress,
          keyboardType: TextInputType.url,
          forceLtr: true,
          onChanged: (String _) => _test.value = HelpTestState.idle,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _port,
          label: l10n.wizardPort,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          forceLtr: true,
          onChanged: (String _) => _test.value = HelpTestState.idle,
        ),
      ],
    );
  }
}
