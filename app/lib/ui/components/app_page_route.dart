import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// A screen push: a fade with a short slide in the reading direction, never a
/// platform-default transition. Reduced motion shows the screen at once.
class AppPageRoute<T> extends PageRoute<T> {
  AppPageRoute({
    required this.builder,
    super.settings,
    this.reduceMotion = false,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;
  final bool reduceMotion;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : AppMotion.screenPush;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : AppMotion.screenPop;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) {
      return child;
    }
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.glide,
      reverseCurve: AppMotion.glide,
    );
    final bool rtl = context.isRtl;
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (BuildContext context, Widget? child) {
          final double dx = (1 - curved.value) * AppMotion.pushSlideDistance;
          return Transform.translate(
            offset: Offset(rtl ? -dx : dx, 0),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// How a modal surface arrives.
enum AppModalMotion { slideUp, fade }

/// The route behind sheets and dialogs: a scrim, dismissal by tapping outside
/// or pressing Escape, and the motion from the design tokens.
class AppModalRoute<T> extends PopupRoute<T> {
  AppModalRoute({
    required this.builder,
    required this.scrim,
    required this.motion,
    required this.dismissLabel,
    this.reduceMotion = false,
    this.dismissible = true,
    super.settings,
  });

  final WidgetBuilder builder;
  final Color scrim;
  final AppModalMotion motion;
  final String dismissLabel;
  final bool reduceMotion;
  final bool dismissible;

  @override
  Duration get transitionDuration {
    if (reduceMotion) {
      return Duration.zero;
    }
    return motion == AppModalMotion.slideUp
        ? AppMotion.sheetPresent
        : AppMotion.tileConnect;
  }

  @override
  bool get barrierDismissible => dismissible;

  @override
  Color? get barrierColor => scrim;

  @override
  String? get barrierLabel => dismissLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent _) {
              if (dismissible) {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
        },
        child: FocusScope(autofocus: true, child: builder(context)),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) {
      return child;
    }
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.settle,
      reverseCurve: AppMotion.settle,
    );
    if (motion == AppModalMotion.fade) {
      return FadeTransition(opacity: curved, child: child);
    }
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}
