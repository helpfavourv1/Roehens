import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/camera_form.dart';
import 'package:roehens/core/services/rtsp_url_normalizer.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/brand_picker_screen.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_switch.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/connection_test_panel.dart';

/// Opens the camera form: a new camera (optionally started from something
/// discovery found) or an existing one. Completes with the saved camera, or
/// null when the person goes back.
Future<Camera?> openCameraEdit(
  BuildContext context, {
  Camera? camera,
  DiscoveryResult? prefill,
  VoidCallback? onOpenTroubleshooter,
}) {
  return Navigator.of(context).push<Camera>(
    AppPageRoute<Camera>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => CameraEditScreen(
        camera: camera,
        prefill: prefill,
        onOpenTroubleshooter: onOpenTroubleshooter,
      ),
    ),
  );
}

/// Add or edit one camera, with a connection test that says in plain words
/// what is wrong.
class CameraEditScreen extends StatefulWidget {
  const CameraEditScreen({
    super.key,
    this.camera,
    this.prefill,
    this.onOpenTroubleshooter,
  });

  /// The camera being edited; null adds a new one.
  final Camera? camera;
  final DiscoveryResult? prefill;

  /// Shown as a pill after a failed test, when the troubleshooter exists.
  final VoidCallback? onOpenTroubleshooter;

  @override
  State<CameraEditScreen> createState() => _CameraEditScreenState();
}

class _CameraEditScreenState extends State<CameraEditScreen> {
  final TextEditingController _address = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _host = TextEditingController();
  final TextEditingController _port = TextEditingController();
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _main = TextEditingController();
  final TextEditingController _sub = TextEditingController();
  final TextEditingController _onvifPort = TextEditingController();
  final TextEditingController _model = TextEditingController();

  final ValueNotifier<StreamProtocol> _protocol =
      ValueNotifier<StreamProtocol>(StreamProtocol.rtsp);
  final ValueNotifier<StreamTransport> _transport =
      ValueNotifier<StreamTransport>(StreamTransport.auto);
  final ValueNotifier<bool> _onvif = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _brandId = ValueNotifier<String?>(null);
  final ValueNotifier<Map<CameraFormField, CameraFormIssue>> _issues =
      ValueNotifier<Map<CameraFormField, CameraFormIssue>>(
        const <CameraFormField, CameraFormIssue>{},
      );
  final ValueNotifier<bool> _addressBad = ValueNotifier<bool>(false);
  final ValueNotifier<ConnectionTestResult?> _result =
      ValueNotifier<ConnectionTestResult?>(null);
  final ValueNotifier<bool> _testing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _saving = ValueNotifier<bool>(false);

  late AppProviders _app;
  bool _started = false;
  int _addressLength = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _app = AppScope.of(context);
    final Camera? existing = widget.camera;
    if (existing != null) {
      _show(CameraFormValues.fromCamera(existing, CameraCredentials.none));
      unawaited(_loadCredentials(existing));
    } else if (widget.prefill != null) {
      _show(CameraForm.fromDiscovery(widget.prefill!));
    } else {
      _show(const CameraFormValues());
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _address,
      _name,
      _host,
      _port,
      _user,
      _pass,
      _main,
      _sub,
      _onvifPort,
      _model,
    ]) {
      c.dispose();
    }
    for (final ChangeNotifier n in <ChangeNotifier>[
      _protocol,
      _transport,
      _onvif,
      _brandId,
      _issues,
      _addressBad,
      _result,
      _testing,
      _saving,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCredentials(Camera camera) async {
    final CameraCredentials credentials =
        (await _app.repository.credentialsFor(camera.id)).valueOrNull ??
        CameraCredentials.none;
    if (!mounted) {
      return;
    }
    _user.text = credentials.username;
    _pass.text = credentials.password;
  }

  /// Puts [values] on screen.
  void _show(CameraFormValues values) {
    _name.text = values.name;
    _host.text = values.host;
    _port.text = values.port;
    _user.text = values.username;
    _pass.text = values.password;
    _main.text = values.mainPath;
    _sub.text = values.subPath;
    _onvifPort.text = values.onvifPort;
    _model.text = values.modelHint;
    _protocol.value = values.protocol;
    _transport.value = values.transport;
    _onvif.value = values.onvifEnabled;
    _brandId.value = values.brandId;
  }

  CameraFormValues _collect() {
    return CameraFormValues(
      name: _name.text,
      protocol: _protocol.value,
      host: _host.text,
      port: _port.text,
      username: _user.text,
      password: _pass.text,
      mainPath: _main.text,
      subPath: _sub.text,
      transport: _transport.value,
      onvifEnabled: _onvif.value,
      onvifPort: _onvifPort.text,
      brandId: _brandId.value,
      modelHint: _model.text,
    );
  }

  void _clearTest() {
    _result.value = null;
  }

  void _parseAddress({required bool submitted}) {
    final String text = _address.text.trim();
    if (text.isEmpty) {
      _addressBad.value = false;
      return;
    }
    final Result<ParsedStreamAddress> parsed = RtspUrlNormalizer.parse(text);
    final ParsedStreamAddress? address = parsed.valueOrNull;
    if (address == null) {
      _addressBad.value = submitted;
      return;
    }
    _addressBad.value = false;
    _show(CameraForm.applyAddress(_collect(), address));
    // The password now lives in its own field; it does not stay in this one.
    _address.clear();
    _addressLength = 0;
    _clearTest();
  }

  void _onAddressChanged(String text) {
    // A paste adds many characters at once; typing adds one.
    final bool pasted = text.length - _addressLength > 8;
    _addressLength = text.length;
    if (pasted) {
      _parseAddress(submitted: false);
    }
  }

  void _setProtocol(StreamProtocol protocol) {
    _show(CameraForm.applyProtocol(_collect(), protocol));
    _clearTest();
  }

  Future<void> _pickBrand() async {
    final CameraBrandProfile? picked = await openBrandPicker(
      context,
      selectedId: _brandId.value,
    );
    if (picked == null || !mounted) {
      return;
    }
    final CameraBrandProfile? previous = _app.profiles.byId(
      _brandId.value ?? '',
    );
    _show(CameraForm.applyBrand(_collect(), picked, previous: previous));
    _clearTest();
  }

  Camera? _draft(CameraFormValues values) {
    final Map<CameraFormField, CameraFormIssue> issues = CameraForm.validate(
      values,
    );
    _issues.value = issues;
    if (issues.isNotEmpty) {
      return null;
    }
    return CameraForm.build(
      values,
      existing: widget.camera,
      now: DateTime.now().toUtc(),
    );
  }

  Future<void> _runTest() async {
    final CameraFormValues values = _collect();
    final Camera? draft = _draft(values);
    if (draft == null) {
      return;
    }
    _testing.value = true;
    _result.value = null;
    final ConnectionTestResult result = await _app.connectionTester.run(
      draft,
      values.credentials,
      onProgress: (List<StageResult> stages) {
        if (mounted) {
          _result.value = ConnectionTestResult(stages: stages);
        }
      },
    );
    if (!mounted) {
      return;
    }
    _result.value = result;
    _testing.value = false;
  }

  Future<void> _save() async {
    if (_saving.value) {
      return;
    }
    final CameraFormValues values = _collect();
    final Camera? draft = _draft(values);
    if (draft == null) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    _saving.value = true;
    final Result<Camera> result = widget.camera == null
        ? await _app.cameras.add(draft, values.credentials)
        : await _app.cameras.update(draft, credentials: values.credentials);
    if (!mounted) {
      return;
    }
    _saving.value = false;
    final Camera? saved = result.valueOrNull;
    if (saved == null) {
      AppToast.show(
        context,
        message: errorMessage(
          l10n,
          result.errorOrNull ?? const AppError(ErrorClass.fatal),
        ),
        bottomOffset: AppSpacing.xxl,
      );
      return;
    }
    unawaited(_app.haptics.success());
    Navigator.of(context).pop(saved);
  }

  String? _issueText(
    AppLocalizations l10n,
    Map<CameraFormField, CameraFormIssue> issues,
    CameraFormField field,
  ) {
    final CameraFormIssue? issue = issues[field];
    return issue == null ? null : formIssueLabel(l10n, issue);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: widget.camera == null ? l10n.editAddTitle : l10n.editEditTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (widget.camera == null) _addressField(l10n),
                _cameraSection(l10n),
                _signInSection(l10n),
                _streamsSection(l10n),
                _advancedSection(l10n),
                _testSection(l10n),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ValueListenableBuilder<bool>(
              valueListenable: _saving,
              builder: (BuildContext context, bool saving, Widget? _) {
                return AppButton(
                  label: l10n.editSave,
                  expand: true,
                  isLoading: saving,
                  onPressed: saving ? null : () => unawaited(_save()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: AppSpacing.md);

  Widget _addressField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ValueListenableBuilder<bool>(
        valueListenable: _addressBad,
        builder: (BuildContext context, bool bad, Widget? _) {
          return AppTextField(
            controller: _address,
            label: l10n.editStreamAddress,
            hint: l10n.editStreamAddressHint,
            helperText: l10n.editStreamAddressHelp,
            errorText: bad ? l10n.editAddressNotUnderstood : null,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            forceLtr: true,
            monospace: true,
            onChanged: _onAddressChanged,
            onSubmitted: (String _) => _parseAddress(submitted: true),
          );
        },
      ),
    );
  }

  Widget _cameraSection(AppLocalizations l10n) {
    return ValueListenableBuilder<Map<CameraFormField, CameraFormIssue>>(
      valueListenable: _issues,
      builder: (BuildContext context, Map<CameraFormField, CameraFormIssue> issues, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppSectionTitle(l10n.editSectionCamera),
            AppTextField(
              controller: _name,
              label: l10n.editName,
              hint: l10n.editNameHint,
              errorText: _issueText(l10n, issues, CameraFormField.name),
              textInputAction: TextInputAction.next,
            ),
            _gap(),
            Semantics(
              label: l10n.editProtocol,
              child: ValueListenableBuilder<StreamProtocol>(
                valueListenable: _protocol,
                builder: (BuildContext context, StreamProtocol protocol, Widget? _) {
                  return AppSegmentedControl<StreamProtocol>(
                    selected: protocol,
                    onChanged: _setProtocol,
                    segments: <AppSegment<StreamProtocol>>[
                      for (final StreamProtocol p in StreamProtocol.values)
                        AppSegment<StreamProtocol>(
                          value: p,
                          label: protocolLabel(l10n, p),
                        ),
                    ],
                  );
                },
              ),
            ),
            _gap(),
            AppTextField(
              controller: _host,
              label: l10n.editHost,
              hint: l10n.editHostHint,
              errorText: _issueText(l10n, issues, CameraFormField.host),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              forceLtr: true,
              onChanged: (String _) => _clearTest(),
            ),
            _gap(),
            AppTextField(
              controller: _port,
              label: l10n.editPort,
              errorText: _issueText(l10n, issues, CameraFormField.port),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.next,
              forceLtr: true,
              onChanged: (String _) => _clearTest(),
            ),
            _gap(),
            _brandRow(l10n),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _brandRow(AppLocalizations l10n) {
    return ValueListenableBuilder<String?>(
      valueListenable: _brandId,
      builder: (BuildContext context, String? id, Widget? _) {
        final CameraBrandProfile? brand = id == null
            ? null
            : _app.profiles.byId(id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppSection(
              children: <Widget>[
                AppListRow(
                  title: l10n.editBrand,
                  subtitle: brand?.displayName ?? l10n.editBrandNone,
                  leading: AppIconName.cameraDome,
                  onTap: () => unawaited(_pickBrand()),
                ),
              ],
            ),
            if (brand?.notes != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                brand!.notes!,
                style: context.type.footnote.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
            if (brand != null) ...<Widget>[
              _gap(),
              AppTextField(
                controller: _model,
                label: l10n.editModel,
                textInputAction: TextInputAction.next,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _signInSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionTitle(l10n.editSectionSignIn),
        AppTextField(
          controller: _user,
          label: l10n.editUsername,
          textInputAction: TextInputAction.next,
          forceLtr: true,
          onChanged: (String _) => _clearTest(),
        ),
        _gap(),
        AppTextField(
          controller: _pass,
          label: l10n.editPassword,
          obscureText: true,
          revealLabel: l10n.editShowPassword,
          concealLabel: l10n.editHidePassword,
          textInputAction: TextInputAction.done,
          forceLtr: true,
          onChanged: (String _) => _clearTest(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _streamsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionTitle(l10n.editSectionStreams),
        AppTextField(
          controller: _main,
          label: l10n.editMainPath,
          textInputAction: TextInputAction.next,
          forceLtr: true,
          monospace: true,
          onChanged: (String _) => _clearTest(),
        ),
        ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[_main, _brandId, _protocol]),
          builder: (BuildContext context, Widget? _) {
            final List<String> others = CameraForm.alternativeMainPaths(
              _collect(),
              _app.profiles.byId(_brandId.value ?? ''),
            );
            if (others.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.editBrandPaths,
                    style: context.type.footnote.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final String path in others)
                        AppChip(
                          label: path,
                          onTap: () {
                            _main.text = path;
                            _clearTest();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        _gap(),
        AppTextField(
          controller: _sub,
          label: l10n.editSubPath,
          textInputAction: TextInputAction.next,
          forceLtr: true,
          monospace: true,
          onChanged: (String _) => _clearTest(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _advancedSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionTitle(l10n.editSectionAdvanced),
        ValueListenableBuilder<StreamProtocol>(
          valueListenable: _protocol,
          builder: (BuildContext context, StreamProtocol protocol, Widget? _) {
            if (protocol != StreamProtocol.rtsp) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Semantics(
                label: l10n.editTransport,
                child: ValueListenableBuilder<StreamTransport>(
                  valueListenable: _transport,
                  builder: (BuildContext context, StreamTransport value, Widget? _) {
                    return AppSegmentedControl<StreamTransport>(
                      selected: value,
                      onChanged: (StreamTransport next) {
                        _transport.value = next;
                        _clearTest();
                      },
                      segments: <AppSegment<StreamTransport>>[
                        AppSegment<StreamTransport>(
                          value: StreamTransport.auto,
                          label: l10n.transportAuto,
                        ),
                        AppSegment<StreamTransport>(
                          value: StreamTransport.tcp,
                          label: l10n.transportTcp,
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _onvif,
          builder: (BuildContext context, bool on, Widget? _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSection(
                  footer: l10n.editOnvifHelp,
                  children: <Widget>[
                    AppListRow(
                      title: l10n.editOnvif,
                      showChevron: false,
                      trailing: AppSwitch(
                        value: on,
                        semanticLabel: l10n.editOnvif,
                        onChanged: (bool v) => _onvif.value = v,
                      ),
                      onTap: () => _onvif.value = !on,
                    ),
                  ],
                ),
                if (on) ...<Widget>[
                  _gap(),
                  ValueListenableBuilder<Map<CameraFormField, CameraFormIssue>>(
                    valueListenable: _issues,
                    builder: (BuildContext context, Map<CameraFormField, CameraFormIssue> issues, Widget? _) {
                      return AppTextField(
                        controller: _onvifPort,
                        label: l10n.editOnvifPort,
                        errorText: _issueText(
                          l10n,
                          issues,
                          CameraFormField.onvifPort,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        forceLtr: true,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _testSection(AppLocalizations l10n) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_result, _testing]),
      builder: (BuildContext context, Widget? _) {
        final ConnectionTestResult? result = _result.value;
        final AppError? error = result?.error;
        final List<String> suggestions = <String>[
          for (final String key in result?.suggestionKeys ?? const <String>[])
            ?testSuggestionLabel(l10n, key),
        ];
        return ConnectionTestPanel(
          labels: ConnectionTestLabels(
            run: l10n.testRun,
            runAgain: l10n.testRunAgain,
            running: l10n.testRunning,
            passed: l10n.testPassed,
            failed: l10n.testFailed,
            stage: (TestStage s) => testStageLabel(l10n, s),
            stageStatus: (StageStatus s) => testStatusLabel(l10n, s),
            elapsed: l10n.testElapsed,
            troubleshoot: l10n.testOpenTroubleshooter,
          ),
          result: result,
          isRunning: _testing.value,
          diagnosis: error == null ? null : errorMessage(l10n, error),
          suggestions: suggestions,
          onRun: () => unawaited(_runTest()),
          onTroubleshoot: widget.onOpenTroubleshooter,
        );
      },
    );
  }
}
