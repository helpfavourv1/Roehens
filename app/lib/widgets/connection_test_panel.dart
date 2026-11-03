import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/connection_test_result.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_divider.dart';
import 'package:roehens/ui/components/app_progress.dart';
import 'package:roehens/ui/components/ltr_text.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Every word the panel shows, already translated.
class ConnectionTestLabels {
  const ConnectionTestLabels({
    required this.run,
    required this.runAgain,
    required this.running,
    required this.passed,
    required this.failed,
    required this.stage,
    required this.stageStatus,
    required this.elapsed,
    this.troubleshoot,
  });

  final String run;
  final String runAgain;
  final String running;

  /// Summary when every stage passed.
  final String passed;

  /// Summary when something failed.
  final String failed;
  final String Function(TestStage stage) stage;
  final String Function(StageStatus status) stageStatus;

  /// For example "120 ms".
  final String Function(int millis) elapsed;

  /// The "Open troubleshooter" pill shown after a failure.
  final String? troubleshoot;
}

/// Runs and shows the connection test: one row per stage with an icon, a name
/// and a status word, then a plain-language diagnosis with things to try, and
/// a way into the troubleshooter. The diagnosis text is passed in already
/// translated; the stage details (which may name hosts) are never shown here.
class ConnectionTestPanel extends StatelessWidget {
  const ConnectionTestPanel({
    super.key,
    required this.labels,
    required this.onRun,
    this.result,
    this.isRunning = false,
    this.diagnosis,
    this.suggestions = const <String>[],
    this.onTroubleshoot,
  });

  final ConnectionTestLabels labels;
  final VoidCallback onRun;

  /// Null before the first run.
  final ConnectionTestResult? result;
  final bool isRunning;

  /// Plain-language reason for a failure.
  final String? diagnosis;
  final List<String> suggestions;
  final VoidCallback? onTroubleshoot;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ConnectionTestResult? current = result;
    final bool failed = current != null && !current.passed && !isRunning;
    final bool passed = current != null && current.passed && !isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (current != null)
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < current.stages.length; i++) ...<Widget>[
                  if (i > 0) const AppDivider(),
                  _StageRow(result: current.stages[i], labels: labels),
                ],
              ],
            ),
          ),
        if (passed || failed) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(
                  passed ? AppIconName.success : AppIconName.failure,
                  size: AppSizes.iconRowLeading,
                  color: passed ? colors.success : colors.error,
                  weight: AppIconWeight.fill,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        passed ? labels.passed : labels.failed,
                        style: context.type.title2.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (failed && diagnosis != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpacing.xs,
                          ),
                          child: Text(
                            diagnosis!,
                            style: context.type.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (failed && suggestions.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          for (final String suggestion in suggestions)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppIcon(
                    AppIconName.chevronRight,
                    size: AppSizes.iconChipGlyph,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: context.type.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: isRunning
              ? labels.running
              : current == null
              ? labels.run
              : labels.runAgain,
          onPressed: isRunning ? null : onRun,
          isLoading: isRunning,
          kind: current == null
              ? AppButtonKind.primary
              : AppButtonKind.secondary,
          expand: true,
        ),
        if (failed &&
            onTroubleshoot != null &&
            labels.troubleshoot != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppChip(
              label: labels.troubleshoot!,
              icon: AppIconName.help,
              onTap: onTroubleshoot,
            ),
          ),
        ],
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.result, required this.labels});

  final StageResult result;
  final ConnectionTestLabels labels;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (AppIconName icon, Color color) = switch (result.status) {
      StageStatus.passed => (AppIconName.success, colors.success),
      StageStatus.failed => (AppIconName.failure, colors.error),
      StageStatus.running => (AppIconName.refresh, colors.accent),
      StageStatus.pending => (AppIconName.clock, colors.textTertiary),
      StageStatus.skipped => (AppIconName.minus, colors.textTertiary),
    };
    final String name = labels.stage(result.stage);
    final String status = labels.stageStatus(result.status);
    final int? millis = result.elapsedMillis;
    return Semantics(
      container: true,
      label: <String>[name, status].join(', '),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              if (result.status == StageStatus.running)
                const AppProgress.spinner()
              else
                AppIcon(
                  icon,
                  size: AppSizes.iconRowLeading,
                  color: color,
                  weight: AppIconWeight.fill,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: context.type.callout.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (millis != null &&
                  result.status == StageStatus.passed) ...<Widget>[
                LtrText(
                  labels.elapsed(millis),
                  style: context.type.data.copyWith(color: colors.textTertiary),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                status,
                style: context.type.data.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
