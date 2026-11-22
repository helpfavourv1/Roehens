import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';

/// Hands the composition root to every screen below it.
///
/// Screens read services and providers with `AppScope.of(context)` and never
/// import `platform/`. The shell (batch P6A) places one scope above the
/// navigator, next to the design tokens.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.providers, required super.child});

  final AppProviders providers;

  /// The nearest scope's providers. A missing scope is a programming error.
  static AppProviders of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context.');
    return scope!.providers;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return providers != oldWidget.providers;
  }
}
