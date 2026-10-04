import 'package:flutter/widgets.dart';

/// Shadows (specification C1.4 and C5). Dark mode has none: depth there is a
/// surface step plus a hairline border. In light mode only floating surfaces
/// (menus, toasts, sheets, dialogs) carry a shadow; cards, rows, tiles and
/// buttons never do.
class AppElevation {
  const AppElevation({required this.pop, required this.sheet});

  /// Menus and toasts.
  final List<BoxShadow> pop;

  /// Sheets and dialogs.
  final List<BoxShadow> sheet;

  static const BoxShadow _shadowPop = BoxShadow(
    color: Color(0x1A10141A),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  static const BoxShadow _shadowSheet = BoxShadow(
    color: Color(0x1F10141A),
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  static const AppElevation dark = AppElevation(
    pop: <BoxShadow>[],
    sheet: <BoxShadow>[],
  );

  static const AppElevation light = AppElevation(
    pop: <BoxShadow>[_shadowPop],
    sheet: <BoxShadow>[_shadowSheet],
  );
}
