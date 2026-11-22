import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';

/// Shows [child] inside the pieces every component expects: an app host,
/// the design tokens, a reading direction and a text scale.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  Size size = const Size(400, 800),
  AppProviders? providers,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    WidgetsApp(
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (
            BuildContext c,
            Animation<double> a,
            Animation<double> s,
          ) => builder(c),
        );
      },
      builder: (BuildContext context, Widget? child) {
        // The tokens sit above the navigator, so overlays (selection handles,
        // menus, toasts) can read them too.
        return Directionality(
          textDirection: direction,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: AppTokens(
              data: AppTokensData.resolve(brightness: brightness),
              child: providers == null
                  ? child!
                  : AppScope(providers: providers, child: child!),
            ),
          ),
        );
      },
      home: Align(alignment: AlignmentDirectional.topStart, child: child),
    ),
  );
}
