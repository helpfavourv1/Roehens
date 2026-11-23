import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/contracts/file_transfer_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/services/camera_export_service.dart';
import 'package:roehens/core/services/camera_import_service.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

Future<void> openImportExport(BuildContext context) {
  return Navigator.of(context).push<void>(
    AppPageRoute<void>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => const ImportExportScreen(),
    ),
  );
}

/// Share the camera list as a file, or bring one back with a preview and a
/// choice for cameras that already exist. Passwords never leave the phone.
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final ValueNotifier<ImportPreview?> _preview = ValueNotifier<ImportPreview?>(
    null,
  );
  final ValueNotifier<ImportConflictMode> _mode =
      ValueNotifier<ImportConflictMode>(ImportConflictMode.skip);
  final ValueNotifier<ImportOutcome?> _outcome = ValueNotifier<ImportOutcome?>(
    null,
  );
  final ValueNotifier<AppError?> _error = ValueNotifier<AppError?>(null);
  final ValueNotifier<bool> _busy = ValueNotifier<bool>(false);
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
    for (final ChangeNotifier n in <ChangeNotifier>[
      _preview,
      _mode,
      _outcome,
      _error,
      _busy,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _export() async {
    final List<Camera> cameras = _app.cameras.value.cameras;
    if (cameras.isEmpty || _busy.value) {
      return;
    }
    _error.value = null;
    _outcome.value = null;
    final ExportFile file = _app.exporter.build(cameras);
    final Result<void> shared = await _app.fileTransfer.shareBytes(
      bytes: file.bytes,
      fileName: file.fileName,
      mimeType: file.mimeType,
    );
    if (mounted) {
      _error.value = shared.errorOrNull;
    }
  }

  Future<void> _pick() async {
    if (_busy.value) {
      return;
    }
    _error.value = null;
    _outcome.value = null;
    _preview.value = null;
    final Result<PickedFile?> picked = await _app.fileTransfer.pickJsonFile();
    if (!mounted) {
      return;
    }
    final AppError? failure = picked.errorOrNull;
    if (failure != null) {
      _error.value = failure;
      return;
    }
    final PickedFile? file = picked.valueOrNull;
    if (file == null) {
      return; // The person closed the picker.
    }
    final Result<ImportPreview> parsed = _app.importer.parse(
      file.bytes,
      _app.cameras.value.cameras,
    );
    _error.value = parsed.errorOrNull;
    _preview.value = parsed.valueOrNull;
  }

  Future<void> _apply() async {
    final ImportPreview? preview = _preview.value;
    if (preview == null || _busy.value) {
      return;
    }
    _busy.value = true;
    final ImportOutcome outcome = await _app.importer.apply(
      preview,
      _mode.value,
    );
    await _app.cameras.load();
    if (!mounted) {
      return;
    }
    _busy.value = false;
    _preview.value = null;
    _outcome.value = outcome;
    unawaited(_app.haptics.success());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.ioTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _app.cameras,
          _preview,
          _mode,
          _outcome,
          _error,
          _busy,
        ]),
        builder: (BuildContext context, Widget? _) {
          final AppError? error = _error.value;
          final ImportOutcome? outcome = _outcome.value;
          final ImportPreview? preview = _preview.value;
          final int count = _app.cameras.value.cameras.length;
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (error != null) ...<Widget>[
                AppBanner(
                  message: errorMessage(l10n, error),
                  tone: AppBannerTone.error,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (outcome != null) ...<Widget>[
                AppBanner(
                  message: l10n.ioDone(
                    outcome.added,
                    outcome.replaced,
                    outcome.skipped,
                    outcome.failed,
                  ),
                  tone: outcome.failed == 0
                      ? AppBannerTone.success
                      : AppBannerTone.warning,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppSection(
                title: l10n.ioExportSection,
                footer: l10n.ioExportBody(count),
                children: <Widget>[
                  AppListRow(
                    title: l10n.ioExportRow,
                    leading: AppIconName.exportFile,
                    onTap: count == 0 ? null : () => unawaited(_export()),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSection(
                title: l10n.ioImportSection,
                footer: l10n.ioImportBody,
                children: <Widget>[
                  AppListRow(
                    title: l10n.ioImportRow,
                    leading: AppIconName.importFile,
                    onTap: () => unawaited(_pick()),
                  ),
                ],
              ),
              if (preview != null) ..._previewWidgets(l10n, preview),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _previewWidgets(AppLocalizations l10n, ImportPreview preview) {
    final bool anyExisting = preview.items.any(
      (ImportItem i) => i.existing != null,
    );
    return <Widget>[
      const SizedBox(height: AppSpacing.lg),
      AppSection(
        title: l10n.ioPreviewSection(preview.items.length),
        footer: preview.invalidCount > 0
            ? l10n.ioInvalidEntries(preview.invalidCount)
            : null,
        children: <Widget>[
          for (final ImportItem item in preview.items)
            AppListRow(
              title: item.camera.name,
              subtitle: cameraAddress(item.camera.host, item.camera.port),
              showChevron: false,
              trailing: AppBadge(
                item.existing == null ? l10n.ioItemNew : l10n.ioItemExists,
                tone: item.existing == null
                    ? AppBadgeTone.accent
                    : AppBadgeTone.neutral,
              ),
            ),
        ],
      ),
      if (anyExisting) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        AppSectionTitle(l10n.ioConflictSection),
        ValueListenableBuilder<ImportConflictMode>(
          valueListenable: _mode,
          builder: (BuildContext context, ImportConflictMode mode, Widget? _) {
            return AppSegmentedControl<ImportConflictMode>(
              selected: mode,
              onChanged: (ImportConflictMode next) => _mode.value = next,
              segments: <AppSegment<ImportConflictMode>>[
                AppSegment<ImportConflictMode>(
                  value: ImportConflictMode.skip,
                  label: l10n.ioSkip,
                ),
                AppSegment<ImportConflictMode>(
                  value: ImportConflictMode.replace,
                  label: l10n.ioReplace,
                ),
                AppSegment<ImportConflictMode>(
                  value: ImportConflictMode.duplicate,
                  label: l10n.ioDuplicate,
                ),
              ],
            );
          },
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        label: l10n.ioApply,
        expand: true,
        isLoading: _busy.value,
        onPressed: _busy.value ? null : () => unawaited(_apply()),
      ),
    ];
  }
}
