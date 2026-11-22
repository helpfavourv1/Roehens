import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/support/screen_labels.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_sheet.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/grid_layout_picker.dart';

/// Opens the layout sheet: grid size, camera order and the auto-cycle
/// interval of the active layout.
Future<void> showLayoutSheet(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final AppProviders app = AppScope.of(context);
  return showAppSheet<void>(
    context,
    title: l10n.layoutTitle,
    dismissLabel: l10n.actionClose,
    builder: (BuildContext sheet) {
      // The sheet is drawn in the overlay, so it needs the scope again.
      return AppScope(providers: app, child: const LayoutSheetContent());
    },
  );
}

/// The body of the layout sheet. Everything it shows follows the providers,
/// so a change is visible at once.
class LayoutSheetContent extends StatelessWidget {
  const LayoutSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppProviders app = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[app.layout, app.cameras]),
      builder: (BuildContext context, Widget? _) {
        final List<Camera> cameras = app.cameras.value.cameras;
        final List<String> order = app.layout.orderedIds(cameras);
        final int size = app.layout.value.pageSize;
        final int? interval = app.layout.value.autoCycleSeconds;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: GridLayoutPicker(
                  selected: size,
                  labelFor: l10n.layoutSizeLabel,
                  onSelected: (int next) {
                    unawaited(app.haptics.selection());
                    unawaited(
                      app.layout.setPageSize(next, cameraCount: cameras.length),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Text(
                  l10n.layoutPerPage(size),
                  style: context.type.footnote.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              if (order.length > 1)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: AppSection(
                    title: l10n.layoutOrderSection,
                    children: <Widget>[
                      for (int i = 0; i < order.length; i++)
                        _OrderRow(
                          camera: cameras.firstWhere(
                            (Camera c) => c.id == order[i],
                          ),
                          index: i,
                          last: order.length - 1,
                          onMove: (int from, int to) {
                            final List<String> next = List<String>.of(order);
                            final String moved = next.removeAt(from);
                            next.insert(to, moved);
                            unawaited(app.haptics.selection());
                            unawaited(app.layout.setCameraOrder(next));
                          },
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: AppSection(
                  title: l10n.layoutAutoCycleSection,
                  footer: l10n.layoutAutoCycleHelp,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          AppChip(
                            label: l10n.layoutAutoCycleDefault,
                            selected: interval == null,
                            onTap: () => app.layout.setAutoCycleSeconds(null),
                          ),
                          for (final int seconds in Limits.autoCycleSeconds)
                            AppChip(
                              label: l10n.layoutAutoCycleSeconds(seconds),
                              selected: interval == seconds,
                              onTap: () =>
                                  app.layout.setAutoCycleSeconds(seconds),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.camera,
    required this.index,
    required this.last,
    required this.onMove,
  });

  final Camera camera;
  final int index;
  final int last;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppListRow(
      title: camera.name,
      subtitle: cameraAddress(camera.host, camera.port),
      showChevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: AppIconName.chevronUp,
            semanticLabel: l10n.layoutMoveUp(camera.name),
            onPressed: index == 0 ? null : () => onMove(index, index - 1),
          ),
          AppIconButton(
            icon: AppIconName.chevronDown,
            semanticLabel: l10n.layoutMoveDown(camera.name),
            onPressed: index == last ? null : () => onMove(index, index + 1),
          ),
        ],
      ),
    );
  }
}
