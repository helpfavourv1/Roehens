import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/app/live_sessions.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/fullscreen_screen.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_sheet.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/widgets/camera_list_row.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

/// The camera list: search, open, edit, and swipe or long-press to delete
/// with an Undo pill.
class CamerasScreen extends StatefulWidget {
  const CamerasScreen({
    super.key,
    required this.onAddCamera,
    required this.onEditCamera,
  });

  final VoidCallback onAddCamera;
  final ValueChanged<Camera> onEditCamera;

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context, Camera camera) async {
    final AppProviders app = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Result<DeletedCamera> result = await app.cameras.delete(camera.id);
    if (!context.mounted) {
      return;
    }
    final DeletedCamera? deleted = result.valueOrNull;
    if (deleted == null) {
      final AppError? error = result.errorOrNull;
      AppToast.show(
        context,
        message: errorMessage(l10n, error ?? const AppError(ErrorClass.fatal)),
      );
      return;
    }
    app.undo.offer(deleted);
    AppToast.show(
      context,
      message: l10n.cameraDeleted(camera.name),
      actionLabel: l10n.actionUndo,
      duration: app.undo.window,
      onAction: () => unawaited(_undo(context)),
    );
  }

  Future<void> _undo(BuildContext context) async {
    final AppProviders app = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Result<Camera>? restored = await app.undo.undo();
    final AppError? error = restored?.errorOrNull;
    if (error != null && context.mounted) {
      AppToast.show(context, message: errorMessage(l10n, error));
    }
  }

  void _actions(BuildContext context, Camera camera) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    unawaited(
      showAppSheet<void>(
        context,
        title: camera.name,
        dismissLabel: l10n.actionClose,
        builder: (BuildContext sheet) {
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: AppSection(
              children: <Widget>[
                AppListRow(
                  title: l10n.actionEdit,
                  leading: AppIconName.edit,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    widget.onEditCamera(camera);
                  },
                ),
                AppListRow(
                  title: l10n.actionDelete,
                  leading: AppIconName.delete,
                  destructive: true,
                  showChevron: false,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(_delete(context, camera));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppProviders app = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppNavBar(
          title: l10n.camerasTitle,
          actions: <Widget>[
            AppIconButton(
              icon: AppIconName.cameraAdd,
              semanticLabel: l10n.actionAddCamera,
              onPressed: widget.onAddCamera,
            ),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              app.cameras,
              app.cameras.query,
              app.live,
            ]),
            builder: (BuildContext context, Widget? _) {
              final CamerasState state = app.cameras.value;
              if (!state.isLoaded) {
                return const SizedBox.shrink();
              }
              if (state.isEmpty) {
                return AppEmptyState(
                  icon: AppIconName.cameraDome,
                  title: l10n.camerasEmptyTitle,
                  message: l10n.camerasEmptyBody,
                  actionLabel: l10n.actionAddCamera,
                  onAction: widget.onAddCamera,
                );
              }
              final List<Camera> shown = CamerasProvider.filter(
                state.cameras,
                app.cameras.query.value,
              );
              final Widget search = AppTextField(
                controller: _search,
                hint: l10n.camerasSearchHint,
                semanticLabel: l10n.camerasSearchHint,
                leadingIcon: AppIconName.search,
                textInputAction: TextInputAction.search,
                onChanged: (String text) => app.cameras.query.value = text,
              );
              if (shown.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: search,
                    ),
                    Expanded(
                      child: AppEmptyState(
                        icon: AppIconName.search,
                        title: l10n.camerasNoResultsTitle,
                        message: l10n.camerasNoResultsBody,
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                children: <Widget>[
                  search,
                  const SizedBox(height: AppSpacing.md),
                  AppSection(
                    children: <Widget>[
                      for (final Camera camera in shown)
                        _row(context, app, l10n, camera),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppProviders app,
    AppLocalizations l10n,
    Camera camera,
  ) {
    final LiveSession? session = app.live.sessionFor(camera.id);
    return ValueListenableBuilder<PlayerState>(
      valueListenable: session?.state ?? _noState,
      builder: (BuildContext context, PlayerState state, Widget? _) {
        final StreamStatus? status = session == null
            ? null
            : StreamStatus.fromPlayerState(state);
        return CameraListRow(
          dismissKey: ValueKey<String>(camera.id),
          name: camera.name,
          address: cameraAddress(camera.host, camera.port),
          protocolLabel: protocolLabel(l10n, camera.protocol),
          status: status,
          statusLabel: status == null ? null : streamStatusLabel(l10n, status),
          deleteLabel: l10n.cameraDeleteSwipe,
          onTap: () =>
              unawaited(openFullscreen(context, camera.id, fromLive: false)),
          onLongPress: () => _actions(context, camera),
          onDelete: () => unawaited(_delete(context, camera)),
        );
      },
    );
  }

  static final ValueNotifier<PlayerState> _noState = ValueNotifier<PlayerState>(
    const PlayerIdle(),
  );
}
