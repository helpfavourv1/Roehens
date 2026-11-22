import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/fullscreen_screen.dart';
import 'package:roehens/screens/layout_sheet.dart';
import 'package:roehens/screens/support/live_tile.dart';
import 'package:roehens/screens/support/status_sheet.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/camera_grid.dart';
import 'package:roehens/widgets/page_dots.dart';
import 'package:roehens/widgets/persistence_warning_banner.dart';
import 'package:roehens/widgets/wordmark.dart';

/// Live: the grid of tiles for the cameras on the current page.
///
/// Only the cameras on this page decode, within the phone's decoder budget;
/// the rest show their last picture (D3). The page changes by swipe, by the
/// dots' accessibility actions, or by auto-cycle.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isActive,
    required this.onAddCamera,
    required this.onFindCameras,
    required this.onEditCamera,
  });

  /// The Live tab is the one on screen.
  final bool isActive;
  final VoidCallback onAddCamera;
  final VoidCallback onFindCameras;
  final ValueChanged<Camera> onEditCamera;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppProviders _app;
  VoidCallback? _onTick;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _app = AppScope.of(context);
      _onTick = _advance;
      _app.autoCycle.ticks.addListener(_onTick!);
    }
    _sync();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _sync();
    }
  }

  @override
  void dispose() {
    final VoidCallback? listener = _onTick;
    if (listener != null) {
      _app.autoCycle.ticks.removeListener(listener);
      scheduleMicrotask(() {
        _app.live.setViewingGrid(viewing: false);
        _app.adState.setLive(live: false);
      });
    }
    super.dispose();
  }

  void _sync() {
    final bool active = widget.isActive;
    final bool tablet = context.isTablet;
    // Providers notify listeners, so this runs after the frame, never while
    // the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _app.live.setViewingGrid(viewing: active, isTablet: tablet);
      _app.adState.setLive(live: active);
      _app.autoCycle.setViewing(viewing: active);
    });
  }

  void _advance() {
    if (!mounted || !widget.isActive || _app.live.focusedId != null) {
      return;
    }
    _app.layout.nextPage(cameraCount: _app.cameras.value.cameras.length);
  }

  void _swipe(DragEndDetails details) {
    final double v = details.primaryVelocity ?? 0;
    final int count = _app.cameras.value.cameras.length;
    if (v.abs() < 300) {
      return;
    }
    // A swipe toward the end of the reading direction goes to the next page.
    final bool toNext = context.isRtl ? v > 0 : v < 0;
    if (toNext) {
      _app.layout.nextPage(cameraCount: count);
    } else {
      _app.layout.previousPage(cameraCount: count);
    }
    _app.autoCycle.userInteracted();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _app.settings,
            _app.cameras,
          ]),
          builder: (BuildContext context, Widget? _) {
            final bool cycling = _app.settings.value.autoCycleEnabled;
            return AppNavBar(
              leading: Wordmark(l10n.appName),
              actions: <Widget>[
                if (_app.cameras.value.cameras.length > 1)
                  AppIconButton(
                    icon: AppIconName.autoCycle,
                    semanticLabel: cycling
                        ? l10n.liveAutoCycleStop
                        : l10n.liveAutoCycleStart,
                    tone: cycling
                        ? AppIconButtonTone.selected
                        : AppIconButtonTone.neutral,
                    onPressed: () => unawaited(
                      _app.settings.setAutoCycle(enabled: !cycling),
                    ),
                  ),
                if (_app.cameras.value.cameras.isNotEmpty)
                  AppIconButton(
                    icon: AppIconName.layoutGrid4,
                    semanticLabel: l10n.liveLayoutButton,
                    onPressed: () => unawaited(showLayoutSheet(context)),
                  ),
                AppIconButton(
                  icon: AppIconName.cameraAdd,
                  semanticLabel: l10n.actionAddCamera,
                  onPressed: widget.onAddCamera,
                ),
              ],
            );
          },
        ),
        PersistenceWarningBanner(
          issue: _app.persistence,
          degradedMessage: l10n.persistenceDegraded,
          updateMessage: l10n.persistenceUpdate,
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              _app.cameras,
              _app.layout,
              _app.layout.page,
              _app.settings,
            ]),
            builder: (BuildContext context, Widget? _) {
              final CamerasState state = _app.cameras.value;
              if (!state.isLoaded) {
                // Reads are fast: the chrome shows and nothing else.
                return const SizedBox.shrink();
              }
              if (state.isEmpty) {
                return _empty(l10n);
              }
              return _grid(context, l10n, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: AppEmptyState(
            icon: AppIconName.cameraDome,
            title: l10n.liveEmptyTitle,
            message: l10n.liveEmptyBody,
            actionLabel: l10n.actionAddCamera,
            onAction: widget.onAddCamera,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: AppButton(
            label: l10n.liveFindCameras,
            icon: AppIconName.scanNetwork,
            kind: AppButtonKind.secondary,
            expand: true,
            onPressed: widget.onFindCameras,
          ),
        ),
      ],
    );
  }

  Widget _grid(
    BuildContext context,
    AppLocalizations l10n,
    CamerasState state,
  ) {
    final int total = state.cameras.length;
    final int pages = _app.layout.pageCount(total);
    final int page = _app.layout.page.value;
    final List<Camera> visible = _app.layout.camerasOnPage(state.cameras);
    final Duration fade = context.motion(AppMotion.autoCycle);
    final bool showLabels = _app.settings.value.showOverlayLabels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: pages > 1 ? _swipe : null,
            child: AnimatedSwitcher(
              duration: fade,
              switchInCurve: AppMotion.settle,
              switchOutCurve: AppMotion.settle,
              child: KeyedSubtree(
                key: ValueKey<int>(page),
                child: CameraGrid(
                  columns: _app.layout.value.columns,
                  rows: _app.layout.value.rows,
                  tiles: <Widget>[
                    for (final Camera camera in visible)
                      LiveTile(
                        key: ValueKey<String>(camera.id),
                        camera: camera,
                        showLabels: showLabels,
                        onOpen: () {
                          _app.autoCycle.userInteracted();
                          unawaited(
                            openFullscreen(context, camera.id, fromLive: true),
                          );
                        },
                        onProblem: (AppError error) => unawaited(
                          showCameraStatusSheet(
                            context,
                            camera: camera,
                            error: error,
                            onRetry: () => unawaited(_app.live.retry(camera.id)),
                            onEdit: () => widget.onEditCamera(camera),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        PageDots(
          count: pages,
          current: page,
          semanticLabel: l10n.livePageOf(page + 1, pages),
          onNext: () => _app.layout.nextPage(cameraCount: total),
          onPrevious: () => _app.layout.previousPage(cameraCount: total),
          nextLabel: l10n.livePageNext,
          previousLabel: l10n.livePagePrevious,
        ),
      ],
    );
  }
}
