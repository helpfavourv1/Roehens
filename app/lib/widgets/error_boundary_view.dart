import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/ui/components/app_error_state.dart';
import 'package:roehens/utils/context_extensions.dart';

/// Shows [child] normally and, when the global error handler reports a fatal
/// error, a full-screen fallback with Retry and Report instead (D5). Retry is
/// expected to clear the error so the app comes back.
class ErrorBoundaryView extends StatelessWidget {
  const ErrorBoundaryView({
    super.key,
    required this.fatal,
    required this.child,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.reportLabel,
    this.onReport,
  });

  /// Latest fatal error, or null while everything is fine.
  final ValueListenable<AppError?> fatal;
  final Widget child;
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? reportLabel;

  /// Gets the error so it can be attached to a feedback mail.
  final ValueChanged<AppError>? onReport;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppError?>(
      valueListenable: fatal,
      builder: (BuildContext context, AppError? error, Widget? _) {
        if (error == null) {
          return child;
        }
        return ColoredBox(
          color: context.colors.bgPrimary,
          child: SafeArea(
            child: AppErrorState(
              title: title,
              message: message,
              primaryLabel: retryLabel,
              onPrimary: onRetry,
              secondaryLabel: onReport == null ? null : reportLabel,
              onSecondary: onReport == null ? null : () => onReport!(error),
            ),
          ),
        );
      },
    );
  }
}
