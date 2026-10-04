import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Weight of an icon. Bold is the default; fill marks selected or active
/// states; duotone is for empty-state hero icons only (specification C4).
enum AppIconWeight { bold, fill, duotone }

/// Semantic icon names. Screens and widgets use these names and never touch an
/// icon package. Each name maps to exactly one Phosphor glyph (docs/ICON_MAP.md).
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

class _Glyphs {
  const _Glyphs(this.bold, this.fill, this.duotone);

  final IconData bold;
  final IconData fill;
  final IconData duotone;
}

/// The only file in the app that imports an icon package.
class AppIcons {
  AppIcons._();

  /// Font families of the weights in use, as registered in the font manifest.
  static const List<String> fontFamilies = <String>[
    'packages/phosphor_flutter/PhosphorBold',
    'packages/phosphor_flutter/PhosphorFill',
    'packages/phosphor_flutter/PhosphorDuotone',
  ];

  static Iterable<AppIconName> get mappedNames => _table.keys;

  static AppIconLayers layers(AppIconName name, AppIconWeight weight) {
    final _Glyphs glyphs = _table[name]!;
    switch (weight) {
      case AppIconWeight.bold:
        return AppIconLayers(primary: glyphs.bold);
      case AppIconWeight.fill:
        return AppIconLayers(primary: glyphs.fill);
      case AppIconWeight.duotone:
        final IconData glyph = glyphs.duotone;
        if (glyph is PhosphorDuotoneIconData) {
          return AppIconLayers(primary: glyph, secondary: glyph.secondary);
        }
        return AppIconLayers(primary: glyph);
    }
  }

  static const Map<AppIconName, _Glyphs> _table = <AppIconName, _Glyphs>{
    // Navigation
    AppIconName.chevronLeft: _Glyphs(
      PhosphorIconsBold.caretLeft,
      PhosphorIconsFill.caretLeft,
      PhosphorIconsDuotone.caretLeft,
    ),
    AppIconName.chevronRight: _Glyphs(
      PhosphorIconsBold.caretRight,
      PhosphorIconsFill.caretRight,
      PhosphorIconsDuotone.caretRight,
    ),
    AppIconName.chevronUp: _Glyphs(
      PhosphorIconsBold.caretUp,
      PhosphorIconsFill.caretUp,
      PhosphorIconsDuotone.caretUp,
    ),
    AppIconName.chevronDown: _Glyphs(
      PhosphorIconsBold.caretDown,
      PhosphorIconsFill.caretDown,
      PhosphorIconsDuotone.caretDown,
    ),
    AppIconName.back: _Glyphs(
      PhosphorIconsBold.arrowLeft,
      PhosphorIconsFill.arrowLeft,
      PhosphorIconsDuotone.arrowLeft,
    ),
    AppIconName.forward: _Glyphs(
      PhosphorIconsBold.arrowRight,
      PhosphorIconsFill.arrowRight,
      PhosphorIconsDuotone.arrowRight,
    ),
    AppIconName.close: _Glyphs(
      PhosphorIconsBold.x,
      PhosphorIconsFill.x,
      PhosphorIconsDuotone.x,
    ),
    AppIconName.menu: _Glyphs(
      PhosphorIconsBold.list,
      PhosphorIconsFill.list,
      PhosphorIconsDuotone.list,
    ),
    AppIconName.more: _Glyphs(
      PhosphorIconsBold.dotsThree,
      PhosphorIconsFill.dotsThree,
      PhosphorIconsDuotone.dotsThree,
    ),
    AppIconName.check: _Glyphs(
      PhosphorIconsBold.check,
      PhosphorIconsFill.check,
      PhosphorIconsDuotone.check,
    ),
    AppIconName.plus: _Glyphs(
      PhosphorIconsBold.plus,
      PhosphorIconsFill.plus,
      PhosphorIconsDuotone.plus,
    ),
    AppIconName.minus: _Glyphs(
      PhosphorIconsBold.minus,
      PhosphorIconsFill.minus,
      PhosphorIconsDuotone.minus,
    ),
    // Camera and viewing
    AppIconName.cameraDome: _Glyphs(
      PhosphorIconsBold.securityCamera,
      PhosphorIconsFill.securityCamera,
      PhosphorIconsDuotone.securityCamera,
    ),
    AppIconName.cameraBullet: _Glyphs(
      PhosphorIconsBold.videoCamera,
      PhosphorIconsFill.videoCamera,
      PhosphorIconsDuotone.videoCamera,
    ),
    AppIconName.cameraPtz: _Glyphs(
      PhosphorIconsBold.arrowsOutCardinal,
      PhosphorIconsFill.arrowsOutCardinal,
      PhosphorIconsDuotone.arrowsOutCardinal,
    ),
    AppIconName.cameraAdd: _Glyphs(
      PhosphorIconsBold.cameraPlus,
      PhosphorIconsFill.cameraPlus,
      PhosphorIconsDuotone.cameraPlus,
    ),
    AppIconName.cameraOff: _Glyphs(
      PhosphorIconsBold.cameraSlash,
      PhosphorIconsFill.cameraSlash,
      PhosphorIconsDuotone.cameraSlash,
    ),
    AppIconName.layoutGrid1: _Glyphs(
      PhosphorIconsBold.square,
      PhosphorIconsFill.square,
      PhosphorIconsDuotone.square,
    ),
    AppIconName.layoutGrid2: _Glyphs(
      PhosphorIconsBold.squareSplitHorizontal,
      PhosphorIconsFill.squareSplitHorizontal,
      PhosphorIconsDuotone.squareSplitHorizontal,
    ),
    AppIconName.layoutGrid4: _Glyphs(
      PhosphorIconsBold.squaresFour,
      PhosphorIconsFill.squaresFour,
      PhosphorIconsDuotone.squaresFour,
    ),
    AppIconName.layoutGrid6: _Glyphs(
      PhosphorIconsBold.columns,
      PhosphorIconsFill.columns,
      PhosphorIconsDuotone.columns,
    ),
    AppIconName.layoutGrid9: _Glyphs(
      PhosphorIconsBold.gridNine,
      PhosphorIconsFill.gridNine,
      PhosphorIconsDuotone.gridNine,
    ),
    AppIconName.layoutGrid12: _Glyphs(
      PhosphorIconsBold.dotsNine,
      PhosphorIconsFill.dotsNine,
      PhosphorIconsDuotone.dotsNine,
    ),
    AppIconName.layoutGrid16: _Glyphs(
      PhosphorIconsBold.gridFour,
      PhosphorIconsFill.gridFour,
      PhosphorIconsDuotone.gridFour,
    ),
    AppIconName.layoutRows: _Glyphs(
      PhosphorIconsBold.rows,
      PhosphorIconsFill.rows,
      PhosphorIconsDuotone.rows,
    ),
    AppIconName.fullscreenEnter: _Glyphs(
      PhosphorIconsBold.cornersOut,
      PhosphorIconsFill.cornersOut,
      PhosphorIconsDuotone.cornersOut,
    ),
    AppIconName.fullscreenExit: _Glyphs(
      PhosphorIconsBold.cornersIn,
      PhosphorIconsFill.cornersIn,
      PhosphorIconsDuotone.cornersIn,
    ),
    AppIconName.snapshot: _Glyphs(
      PhosphorIconsBold.camera,
      PhosphorIconsFill.camera,
      PhosphorIconsDuotone.camera,
    ),
    AppIconName.play: _Glyphs(
      PhosphorIconsBold.play,
      PhosphorIconsFill.play,
      PhosphorIconsDuotone.play,
    ),
    AppIconName.pause: _Glyphs(
      PhosphorIconsBold.pause,
      PhosphorIconsFill.pause,
      PhosphorIconsDuotone.pause,
    ),
    AppIconName.refresh: _Glyphs(
      PhosphorIconsBold.arrowClockwise,
      PhosphorIconsFill.arrowClockwise,
      PhosphorIconsDuotone.arrowClockwise,
    ),
    AppIconName.volumeOn: _Glyphs(
      PhosphorIconsBold.speakerHigh,
      PhosphorIconsFill.speakerHigh,
      PhosphorIconsDuotone.speakerHigh,
    ),
    AppIconName.volumeOff: _Glyphs(
      PhosphorIconsBold.speakerSlash,
      PhosphorIconsFill.speakerSlash,
      PhosphorIconsDuotone.speakerSlash,
    ),
    AppIconName.zoomIn: _Glyphs(
      PhosphorIconsBold.magnifyingGlassPlus,
      PhosphorIconsFill.magnifyingGlassPlus,
      PhosphorIconsDuotone.magnifyingGlassPlus,
    ),
    AppIconName.zoomOut: _Glyphs(
      PhosphorIconsBold.magnifyingGlassMinus,
      PhosphorIconsFill.magnifyingGlassMinus,
      PhosphorIconsDuotone.magnifyingGlassMinus,
    ),
    AppIconName.ptzArrowUp: _Glyphs(
      PhosphorIconsBold.arrowFatLineUp,
      PhosphorIconsFill.arrowFatLineUp,
      PhosphorIconsDuotone.arrowFatLineUp,
    ),
    AppIconName.ptzArrowDown: _Glyphs(
      PhosphorIconsBold.arrowFatLineDown,
      PhosphorIconsFill.arrowFatLineDown,
      PhosphorIconsDuotone.arrowFatLineDown,
    ),
    AppIconName.ptzArrowLeft: _Glyphs(
      PhosphorIconsBold.arrowFatLineLeft,
      PhosphorIconsFill.arrowFatLineLeft,
      PhosphorIconsDuotone.arrowFatLineLeft,
    ),
    AppIconName.ptzArrowRight: _Glyphs(
      PhosphorIconsBold.arrowFatLineRight,
      PhosphorIconsFill.arrowFatLineRight,
      PhosphorIconsDuotone.arrowFatLineRight,
    ),
    AppIconName.ptzHome: _Glyphs(
      PhosphorIconsBold.target,
      PhosphorIconsFill.target,
      PhosphorIconsDuotone.target,
    ),
    AppIconName.home: _Glyphs(
      PhosphorIconsBold.house,
      PhosphorIconsFill.house,
      PhosphorIconsDuotone.house,
    ),
    // Status
    AppIconName.live: _Glyphs(
      PhosphorIconsBold.broadcast,
      PhosphorIconsFill.broadcast,
      PhosphorIconsDuotone.broadcast,
    ),
    AppIconName.wifi: _Glyphs(
      PhosphorIconsBold.wifiHigh,
      PhosphorIconsFill.wifiHigh,
      PhosphorIconsDuotone.wifiHigh,
    ),
    AppIconName.wifiOff: _Glyphs(
      PhosphorIconsBold.wifiSlash,
      PhosphorIconsFill.wifiSlash,
      PhosphorIconsDuotone.wifiSlash,
    ),
    AppIconName.lock: _Glyphs(
      PhosphorIconsBold.lock,
      PhosphorIconsFill.lock,
      PhosphorIconsDuotone.lock,
    ),
    AppIconName.unlock: _Glyphs(
      PhosphorIconsBold.lockOpen,
      PhosphorIconsFill.lockOpen,
      PhosphorIconsDuotone.lockOpen,
    ),
    AppIconName.warning: _Glyphs(
      PhosphorIconsBold.warning,
      PhosphorIconsFill.warning,
      PhosphorIconsDuotone.warning,
    ),
    AppIconName.info: _Glyphs(
      PhosphorIconsBold.info,
      PhosphorIconsFill.info,
      PhosphorIconsDuotone.info,
    ),
    AppIconName.success: _Glyphs(
      PhosphorIconsBold.checkCircle,
      PhosphorIconsFill.checkCircle,
      PhosphorIconsDuotone.checkCircle,
    ),
    AppIconName.failure: _Glyphs(
      PhosphorIconsBold.xCircle,
      PhosphorIconsFill.xCircle,
      PhosphorIconsDuotone.xCircle,
    ),
    AppIconName.clock: _Glyphs(
      PhosphorIconsBold.clock,
      PhosphorIconsFill.clock,
      PhosphorIconsDuotone.clock,
    ),
    AppIconName.signal: _Glyphs(
      PhosphorIconsBold.cellSignalFull,
      PhosphorIconsFill.cellSignalFull,
      PhosphorIconsDuotone.cellSignalFull,
    ),
    // Actions
    AppIconName.search: _Glyphs(
      PhosphorIconsBold.magnifyingGlass,
      PhosphorIconsFill.magnifyingGlass,
      PhosphorIconsDuotone.magnifyingGlass,
    ),
    AppIconName.filter: _Glyphs(
      PhosphorIconsBold.funnel,
      PhosphorIconsFill.funnel,
      PhosphorIconsDuotone.funnel,
    ),
    AppIconName.edit: _Glyphs(
      PhosphorIconsBold.pencilSimple,
      PhosphorIconsFill.pencilSimple,
      PhosphorIconsDuotone.pencilSimple,
    ),
    AppIconName.delete: _Glyphs(
      PhosphorIconsBold.trash,
      PhosphorIconsFill.trash,
      PhosphorIconsDuotone.trash,
    ),
    AppIconName.copy: _Glyphs(
      PhosphorIconsBold.copy,
      PhosphorIconsFill.copy,
      PhosphorIconsDuotone.copy,
    ),
    AppIconName.share: _Glyphs(
      PhosphorIconsBold.shareNetwork,
      PhosphorIconsFill.shareNetwork,
      PhosphorIconsDuotone.shareNetwork,
    ),
    AppIconName.download: _Glyphs(
      PhosphorIconsBold.downloadSimple,
      PhosphorIconsFill.downloadSimple,
      PhosphorIconsDuotone.downloadSimple,
    ),
    AppIconName.upload: _Glyphs(
      PhosphorIconsBold.uploadSimple,
      PhosphorIconsFill.uploadSimple,
      PhosphorIconsDuotone.uploadSimple,
    ),
    AppIconName.importFile: _Glyphs(
      PhosphorIconsBold.fileArrowDown,
      PhosphorIconsFill.fileArrowDown,
      PhosphorIconsDuotone.fileArrowDown,
    ),
    AppIconName.exportFile: _Glyphs(
      PhosphorIconsBold.fileArrowUp,
      PhosphorIconsFill.fileArrowUp,
      PhosphorIconsDuotone.fileArrowUp,
    ),
    AppIconName.scanNetwork: _Glyphs(
      PhosphorIconsBold.scan,
      PhosphorIconsFill.scan,
      PhosphorIconsDuotone.scan,
    ),
    AppIconName.link: _Glyphs(
      PhosphorIconsBold.linkSimple,
      PhosphorIconsFill.linkSimple,
      PhosphorIconsDuotone.linkSimple,
    ),
    AppIconName.undo: _Glyphs(
      PhosphorIconsBold.arrowCounterClockwise,
      PhosphorIconsFill.arrowCounterClockwise,
      PhosphorIconsDuotone.arrowCounterClockwise,
    ),
    AppIconName.show: _Glyphs(
      PhosphorIconsBold.eye,
      PhosphorIconsFill.eye,
      PhosphorIconsDuotone.eye,
    ),
    AppIconName.hide: _Glyphs(
      PhosphorIconsBold.eyeSlash,
      PhosphorIconsFill.eyeSlash,
      PhosphorIconsDuotone.eyeSlash,
    ),
    AppIconName.sliders: _Glyphs(
      PhosphorIconsBold.slidersHorizontal,
      PhosphorIconsFill.slidersHorizontal,
      PhosphorIconsDuotone.slidersHorizontal,
    ),
    // System
    AppIconName.settings: _Glyphs(
      PhosphorIconsBold.gear,
      PhosphorIconsFill.gear,
      PhosphorIconsDuotone.gear,
    ),
    AppIconName.sun: _Glyphs(
      PhosphorIconsBold.sun,
      PhosphorIconsFill.sun,
      PhosphorIconsDuotone.sun,
    ),
    AppIconName.moon: _Glyphs(
      PhosphorIconsBold.moon,
      PhosphorIconsFill.moon,
      PhosphorIconsDuotone.moon,
    ),
    AppIconName.contrast: _Glyphs(
      PhosphorIconsBold.circleHalf,
      PhosphorIconsFill.circleHalf,
      PhosphorIconsDuotone.circleHalf,
    ),
    AppIconName.globe: _Glyphs(
      PhosphorIconsBold.globe,
      PhosphorIconsFill.globe,
      PhosphorIconsDuotone.globe,
    ),
    AppIconName.shield: _Glyphs(
      PhosphorIconsBold.shield,
      PhosphorIconsFill.shield,
      PhosphorIconsDuotone.shield,
    ),
    AppIconName.mail: _Glyphs(
      PhosphorIconsBold.envelopeSimple,
      PhosphorIconsFill.envelopeSimple,
      PhosphorIconsDuotone.envelopeSimple,
    ),
    AppIconName.star: _Glyphs(
      PhosphorIconsBold.star,
      PhosphorIconsFill.star,
      PhosphorIconsDuotone.star,
    ),
    AppIconName.externalLink: _Glyphs(
      PhosphorIconsBold.arrowSquareOut,
      PhosphorIconsFill.arrowSquareOut,
      PhosphorIconsDuotone.arrowSquareOut,
    ),
    AppIconName.help: _Glyphs(
      PhosphorIconsBold.question,
      PhosphorIconsFill.question,
      PhosphorIconsDuotone.question,
    ),
    AppIconName.upgrade: _Glyphs(
      PhosphorIconsBold.diamond,
      PhosphorIconsFill.diamond,
      PhosphorIconsDuotone.diamond,
    ),
    // Help and viewing extras (R1)
    AppIconName.book: _Glyphs(
      PhosphorIconsBold.book,
      PhosphorIconsFill.book,
      PhosphorIconsDuotone.book,
    ),
    AppIconName.route: _Glyphs(
      PhosphorIconsBold.signpost,
      PhosphorIconsFill.signpost,
      PhosphorIconsDuotone.signpost,
    ),
    AppIconName.network: _Glyphs(
      PhosphorIconsBold.network,
      PhosphorIconsFill.network,
      PhosphorIconsDuotone.network,
    ),
    AppIconName.globeNetwork: _Glyphs(
      PhosphorIconsBold.globeHemisphereWest,
      PhosphorIconsFill.globeHemisphereWest,
      PhosphorIconsDuotone.globeHemisphereWest,
    ),
    AppIconName.pip: _Glyphs(
      PhosphorIconsBold.browsers,
      PhosphorIconsFill.browsers,
      PhosphorIconsDuotone.browsers,
    ),
    AppIconName.autoCycle: _Glyphs(
      PhosphorIconsBold.repeat,
      PhosphorIconsFill.repeat,
      PhosphorIconsDuotone.repeat,
    ),
    AppIconName.language: _Glyphs(
      PhosphorIconsBold.translate,
      PhosphorIconsFill.translate,
      PhosphorIconsDuotone.translate,
    ),
    AppIconName.diagnostics: _Glyphs(
      PhosphorIconsBold.pulse,
      PhosphorIconsFill.pulse,
      PhosphorIconsDuotone.pulse,
    ),
    AppIconName.troubleshoot: _Glyphs(
      PhosphorIconsBold.lifebuoy,
      PhosphorIconsFill.lifebuoy,
      PhosphorIconsDuotone.lifebuoy,
    ),
  };
}
