import 'package:flutter/widgets.dart';

/// Weight of an icon. Bold is the default; fill marks selected or active
/// states; duotone is for empty-state hero icons only (specification C4).
enum AppIconWeight { bold, fill, duotone }

/// Semantic icon names. Screens and widgets use these names and never touch a
/// glyph table. Each name maps to exactly one Phosphor glyph (docs/ICON_MAP.md).
enum AppIconName {
  // Navigation
  chevronLeft,
  chevronRight,
  chevronUp,
  chevronDown,
  back,
  forward,
  close,
  menu,
  more,
  check,
  plus,
  minus,
  // Camera and viewing
  cameraDome,
  cameraBullet,
  cameraPtz,
  cameraAdd,
  cameraOff,
  layoutGrid1,
  layoutGrid2,
  layoutGrid4,
  layoutGrid6,
  layoutGrid9,
  layoutGrid12,
  layoutGrid16,
  layoutRows,
  fullscreenEnter,
  fullscreenExit,
  snapshot,
  play,
  pause,
  refresh,
  volumeOn,
  volumeOff,
  zoomIn,
  zoomOut,
  ptzArrowUp,
  ptzArrowDown,
  ptzArrowLeft,
  ptzArrowRight,
  ptzHome,
  home,
  // Status
  live,
  wifi,
  wifiOff,
  lock,
  unlock,
  warning,
  info,
  success,
  failure,
  clock,
  signal,
  // Actions
  search,
  filter,
  edit,
  delete,
  copy,
  share,
  download,
  upload,
  importFile,
  exportFile,
  scanNetwork,
  link,
  undo,
  show,
  hide,
  sliders,
  // System
  settings,
  sun,
  moon,
  contrast,
  globe,
  shield,
  mail,
  star,
  externalLink,
  help,
  upgrade,
  // Help and viewing extras (R1)
  book,
  route,
  network,
  globeNetwork,
  pip,
  autoCycle,
  language,
  diagnostics,
  troubleshoot,
  ;

  /// Only directional icons mirror in right-to-left layouts. Physical-direction
  /// icons (PTZ arrows, zoom) and everything else keep their orientation.
  bool get mirrorsInRtl {
    return switch (this) {
      AppIconName.chevronLeft ||
      AppIconName.chevronRight ||
      AppIconName.back ||
      AppIconName.forward =>
        true,
      _ => false,
    };
  }
}

/// The glyph layers of one icon at one weight. [secondary] is set only for the
/// duotone weight.
class AppIconLayers {
  const AppIconLayers({required this.primary, this.secondary});

  final IconData primary;
  final IconData? secondary;
}

const String _bold = 'PhosphorBold';
const String _fill = 'PhosphorFill';
const String _duotone = 'PhosphorDuotone';

class _Glyphs {
  const _Glyphs({
    required this.bold,
    required this.fill,
    required this.duotone,
    required this.duotoneSecondary,
  });

  final IconData bold;
  final IconData fill;
  final IconData duotone;
  final IconData duotoneSecondary;
}

/// The single place that knows glyph code points. The Phosphor fonts are bundled
/// as app assets (assets/fonts). Every [IconData] here is a compile-time
/// constant, which release builds require to tree-shake the icon fonts.
class AppIcons {
  AppIcons._();

  /// Font families of the weights in use, as registered in the font manifest.
  static const List<String> fontFamilies = <String>[_bold, _fill, _duotone];

  static Iterable<AppIconName> get mappedNames => _table.keys;

  static AppIconLayers layers(AppIconName name, AppIconWeight weight) {
    final _Glyphs glyphs = _table[name]!;
    switch (weight) {
      case AppIconWeight.bold:
        return AppIconLayers(primary: glyphs.bold);
      case AppIconWeight.fill:
        return AppIconLayers(primary: glyphs.fill);
      case AppIconWeight.duotone:
        return AppIconLayers(
          primary: glyphs.duotone,
          secondary: glyphs.duotoneSecondary,
        );
    }
  }

  static const Map<AppIconName, _Glyphs> _table = <AppIconName, _Glyphs>{
    // Navigation
    AppIconName.chevronLeft: _Glyphs(
      bold: IconData(0xe138, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe138, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe139, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe138, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.chevronRight: _Glyphs(
      bold: IconData(0xe13a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe13a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe13b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe13a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.chevronUp: _Glyphs(
      bold: IconData(0xe13c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe13c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe13d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe13c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.chevronDown: _Glyphs(
      bold: IconData(0xe136, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe136, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe137, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe136, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.back: _Glyphs(
      bold: IconData(0xe058, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe058, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe059, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe058, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.forward: _Glyphs(
      bold: IconData(0xe06c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe06c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe06d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe06c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.close: _Glyphs(
      bold: IconData(0xe4f6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4f6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4f7, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4f6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.menu: _Glyphs(
      bold: IconData(0xe2f0, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe2f0, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe2f1, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe2f0, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.more: _Glyphs(
      bold: IconData(0xe1fe, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1fe, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1ff, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1fe, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.check: _Glyphs(
      bold: IconData(0xe182, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe182, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe183, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe182, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.plus: _Glyphs(
      bold: IconData(0xe3d4, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe3d4, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe3d5, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe3d4, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.minus: _Glyphs(
      bold: IconData(0xe32a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe32a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe32b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe32a, fontFamily: _duotone, matchTextDirection: true),
    ),
    // Camera and viewing
    AppIconName.cameraDome: _Glyphs(
      bold: IconData(0xeca4, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xeca4, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xeca5, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xeca4, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.cameraBullet: _Glyphs(
      bold: IconData(0xe4da, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4da, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4db, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4da, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.cameraPtz: _Glyphs(
      bold: IconData(0xe0a4, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe0a4, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe0a5, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe0a4, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.cameraAdd: _Glyphs(
      bold: IconData(0xec58, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xec58, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xec59, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xec58, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.cameraOff: _Glyphs(
      bold: IconData(0xe110, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe110, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe111, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe110, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid1: _Glyphs(
      bold: IconData(0xe45e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe45e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe45f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe45e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid2: _Glyphs(
      bold: IconData(0xe870, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe870, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe871, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe870, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid4: _Glyphs(
      bold: IconData(0xe464, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe464, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe465, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe464, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid6: _Glyphs(
      bold: IconData(0xe546, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe546, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe547, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe546, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid9: _Glyphs(
      bold: IconData(0xec8c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xec8c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xec8d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xec8c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid12: _Glyphs(
      bold: IconData(0xe1fc, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1fc, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1fd, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1fc, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutGrid16: _Glyphs(
      bold: IconData(0xe296, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe296, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe297, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe296, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.layoutRows: _Glyphs(
      bold: IconData(0xe5a2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe5a2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe5a3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe5a2, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.fullscreenEnter: _Glyphs(
      bold: IconData(0xe1d0, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1d0, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1d1, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1d0, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.fullscreenExit: _Glyphs(
      bold: IconData(0xe1ce, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1ce, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1cf, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1ce, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.snapshot: _Glyphs(
      bold: IconData(0xe10e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe10e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe10f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe10e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.play: _Glyphs(
      bold: IconData(0xe3d0, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe3d0, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe3d1, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe3d0, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.pause: _Glyphs(
      bold: IconData(0xe39e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe39e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe39f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe39e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.refresh: _Glyphs(
      bold: IconData(0xe036, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe036, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe037, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe036, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.volumeOn: _Glyphs(
      bold: IconData(0xe44a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe44a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe44b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe44a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.volumeOff: _Glyphs(
      bold: IconData(0xe45a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe45a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe45b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe45a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.zoomIn: _Glyphs(
      bold: IconData(0xe310, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe310, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe311, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe310, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.zoomOut: _Glyphs(
      bold: IconData(0xe30e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe30e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe30f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe30e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.ptzArrowUp: _Glyphs(
      bold: IconData(0xe522, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe522, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe523, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe522, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.ptzArrowDown: _Glyphs(
      bold: IconData(0xe51c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe51c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe51d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe51c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.ptzArrowLeft: _Glyphs(
      bold: IconData(0xe51e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe51e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe51f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe51e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.ptzArrowRight: _Glyphs(
      bold: IconData(0xe520, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe520, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe521, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe520, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.ptzHome: _Glyphs(
      bold: IconData(0xe47c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe47c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe47d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe47c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.home: _Glyphs(
      bold: IconData(0xe2c2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe2c2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe2c3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe2c2, fontFamily: _duotone, matchTextDirection: true),
    ),
    // Status
    AppIconName.live: _Glyphs(
      bold: IconData(0xe0f2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe0f2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe0f3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe0f2, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.wifi: _Glyphs(
      bold: IconData(0xe4ea, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4ea, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4eb, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4ea, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.wifiOff: _Glyphs(
      bold: IconData(0xe4f2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4f2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4f3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4f2, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.lock: _Glyphs(
      bold: IconData(0xe2fa, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe2fa, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe2fb, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe2fa, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.unlock: _Glyphs(
      bold: IconData(0xe306, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe306, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe307, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe306, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.warning: _Glyphs(
      bold: IconData(0xe4e0, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4e0, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4e1, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4e0, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.info: _Glyphs(
      bold: IconData(0xe2ce, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe2ce, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe2cf, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe2ce, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.success: _Glyphs(
      bold: IconData(0xe184, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe184, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe185, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe184, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.failure: _Glyphs(
      bold: IconData(0xe4f8, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4f8, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4f9, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4f8, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.clock: _Glyphs(
      bold: IconData(0xe19a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe19a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe19b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe19a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.signal: _Glyphs(
      bold: IconData(0xe142, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe142, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe143, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe142, fontFamily: _duotone, matchTextDirection: true),
    ),
    // Actions
    AppIconName.search: _Glyphs(
      bold: IconData(0xe30c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe30c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe30d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe30c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.filter: _Glyphs(
      bold: IconData(0xe266, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe266, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe267, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe266, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.edit: _Glyphs(
      bold: IconData(0xe3b4, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe3b4, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe3b5, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe3b4, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.delete: _Glyphs(
      bold: IconData(0xe4a6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4a6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4a7, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4a6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.copy: _Glyphs(
      bold: IconData(0xe1ca, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1ca, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1cb, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1ca, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.share: _Glyphs(
      bold: IconData(0xe408, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe408, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe40b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe408, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.download: _Glyphs(
      bold: IconData(0xe20c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe20c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe20d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe20c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.upload: _Glyphs(
      bold: IconData(0xe4c0, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4c0, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4c1, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4c0, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.importFile: _Glyphs(
      bold: IconData(0xe232, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe232, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe233, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe232, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.exportFile: _Glyphs(
      bold: IconData(0xe61e, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe61e, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe61f, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe61e, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.scanNetwork: _Glyphs(
      bold: IconData(0xebb6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xebb6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xebb7, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xebb6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.link: _Glyphs(
      bold: IconData(0xe2e6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe2e6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe2e7, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe2e6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.undo: _Glyphs(
      bold: IconData(0xe038, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe038, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe039, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe038, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.show: _Glyphs(
      bold: IconData(0xe220, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe220, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe221, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe220, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.hide: _Glyphs(
      bold: IconData(0xe224, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe224, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe225, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe224, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.sliders: _Glyphs(
      bold: IconData(0xe434, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe434, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe435, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe434, fontFamily: _duotone, matchTextDirection: true),
    ),
    // System
    AppIconName.settings: _Glyphs(
      bold: IconData(0xe270, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe270, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe271, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe270, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.sun: _Glyphs(
      bold: IconData(0xe472, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe472, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe473, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe472, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.moon: _Glyphs(
      bold: IconData(0xe330, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe330, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe331, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe330, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.contrast: _Glyphs(
      bold: IconData(0xe18c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe18c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe18d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe18c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.globe: _Glyphs(
      bold: IconData(0xe288, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe288, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe289, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe288, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.shield: _Glyphs(
      bold: IconData(0xe40a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe40a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe40d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe40a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.mail: _Glyphs(
      bold: IconData(0xe218, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe218, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe219, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe218, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.star: _Glyphs(
      bold: IconData(0xe46a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe46a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe46b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe46a, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.externalLink: _Glyphs(
      bold: IconData(0xe5de, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe5de, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe5df, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe5de, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.help: _Glyphs(
      bold: IconData(0xe3e8, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe3e8, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe3eb, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe3e8, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.upgrade: _Glyphs(
      bold: IconData(0xe1ec, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe1ec, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe1ed, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe1ec, fontFamily: _duotone, matchTextDirection: true),
    ),
    // Help and viewing extras (R1)
    AppIconName.book: _Glyphs(
      bold: IconData(0xe0e2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe0e2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe0e3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe0e2, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.route: _Glyphs(
      bold: IconData(0xe89c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe89c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe89d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe89c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.network: _Glyphs(
      bold: IconData(0xedde, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xedde, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xeddf, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xedde, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.globeNetwork: _Glyphs(
      bold: IconData(0xe28c, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe28c, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe28d, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe28c, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.pip: _Glyphs(
      bold: IconData(0xe0f6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe0f6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe0f7, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe0f6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.autoCycle: _Glyphs(
      bold: IconData(0xe3f6, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe3f6, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe3f9, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe3f6, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.language: _Glyphs(
      bold: IconData(0xe4a2, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe4a2, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe4a3, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe4a2, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.diagnostics: _Glyphs(
      bold: IconData(0xe000, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe000, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe001, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe000, fontFamily: _duotone, matchTextDirection: true),
    ),
    AppIconName.troubleshoot: _Glyphs(
      bold: IconData(0xe63a, fontFamily: _bold, matchTextDirection: true),
      fill: IconData(0xe63a, fontFamily: _fill, matchTextDirection: true),
      duotone: IconData(0xe63b, fontFamily: _duotone, matchTextDirection: true),
      duotoneSecondary:
          IconData(0xe63a, fontFamily: _duotone, matchTextDirection: true),
    ),
  };
}
