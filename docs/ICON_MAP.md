# Icon map

Each semantic icon (`AppIconName`) maps to exactly one glyph from exactly one source. Phosphor Icons (MIT) is the primary source, bundled as three font files (see Source). Tabler is the gap-filler and every Tabler use would carry a reason in the last column.

**Tabler is not used.** Every R1 icon has a suitable Phosphor glyph, so Tabler is not used. If a later release finds a gap, add the package, log it in `DECISIONS.md`, and record the reason here.

Glyph identifiers were read from the upstream source (1,512 glyphs per weight), never guessed. Weights in use: Bold (default), Fill (selected/active), Duotone (empty-state hero only). Regular, Light and Thin are not used.

Items to judge by eye at Gate 2 on the cheapest device:

- `layoutGrid6` and `layoutGrid12` use the closest available glyphs (`columns`, `dotsNine`), not exact 2x3 and 3x4 grids.
- `pip` uses `browsers` because Phosphor has no picture-in-picture glyph.
- `cameraPtz` uses `arrowsOutCardinal`.

Only `chevronLeft`, `chevronRight`, `back` and `forward` mirror in right-to-left layouts.


## Source

The `phosphor_flutter` package (2.1.0) cannot compile with Flutter 3.47 because it extends `IconData`, which is a final class, and upstream `main` has the same code. The package is therefore not a dependency. Its MIT-licensed font files and glyph code points are bundled directly, from the upstream tag `v2.1.0` (`github.com/phosphor-icons/flutter`):

| Asset | SHA-256 (first 16 hex) |
|---|---|
| `assets/fonts/Phosphor-Bold.ttf` | 10a0a1cb4f8156a4 |
| `assets/fonts/Phosphor-Fill.ttf` | a53f5d2630cab5e3 |
| `assets/fonts/Phosphor-Duotone.ttf` | 80e6f0d6fa8ce96a |

The license text is `assets/fonts/LICENSE-phosphor.txt`; `icon_license.dart` registers it with Flutter's `LicenseRegistry`. Code points live only in `lib/ui/icons/app_icons.dart`.

| Semantic name | Source | Phosphor glyph | Reason (Tabler only) |
|---|---|---|---|
| `chevronLeft` | Phosphor | `caretLeft` | |
| `chevronRight` | Phosphor | `caretRight` | |
| `chevronUp` | Phosphor | `caretUp` | |
| `chevronDown` | Phosphor | `caretDown` | |
| `back` | Phosphor | `arrowLeft` | |
| `forward` | Phosphor | `arrowRight` | |
| `close` | Phosphor | `x` | |
| `menu` | Phosphor | `list` | |
| `more` | Phosphor | `dotsThree` | |
| `check` | Phosphor | `check` | |
| `plus` | Phosphor | `plus` | |
| `minus` | Phosphor | `minus` | |
| `cameraDome` | Phosphor | `securityCamera` | |
| `cameraBullet` | Phosphor | `videoCamera` | |
| `cameraPtz` | Phosphor | `arrowsOutCardinal` | |
| `cameraAdd` | Phosphor | `cameraPlus` | |
| `cameraOff` | Phosphor | `cameraSlash` | |
| `layoutGrid1` | Phosphor | `square` | |
| `layoutGrid2` | Phosphor | `squareSplitHorizontal` | |
| `layoutGrid4` | Phosphor | `squaresFour` | |
| `layoutGrid6` | Phosphor | `columns` | |
| `layoutGrid9` | Phosphor | `gridNine` | |
| `layoutGrid12` | Phosphor | `dotsNine` | |
| `layoutGrid16` | Phosphor | `gridFour` | |
| `layoutRows` | Phosphor | `rows` | |
| `fullscreenEnter` | Phosphor | `cornersOut` | |
| `fullscreenExit` | Phosphor | `cornersIn` | |
| `snapshot` | Phosphor | `camera` | |
| `play` | Phosphor | `play` | |
| `pause` | Phosphor | `pause` | |
| `refresh` | Phosphor | `arrowClockwise` | |
| `volumeOn` | Phosphor | `speakerHigh` | |
| `volumeOff` | Phosphor | `speakerSlash` | |
| `zoomIn` | Phosphor | `magnifyingGlassPlus` | |
| `zoomOut` | Phosphor | `magnifyingGlassMinus` | |
| `ptzArrowUp` | Phosphor | `arrowFatLineUp` | |
| `ptzArrowDown` | Phosphor | `arrowFatLineDown` | |
| `ptzArrowLeft` | Phosphor | `arrowFatLineLeft` | |
| `ptzArrowRight` | Phosphor | `arrowFatLineRight` | |
| `ptzHome` | Phosphor | `target` | |
| `home` | Phosphor | `house` | |
| `live` | Phosphor | `broadcast` | |
| `wifi` | Phosphor | `wifiHigh` | |
| `wifiOff` | Phosphor | `wifiSlash` | |
| `lock` | Phosphor | `lock` | |
| `unlock` | Phosphor | `lockOpen` | |
| `warning` | Phosphor | `warning` | |
| `info` | Phosphor | `info` | |
| `success` | Phosphor | `checkCircle` | |
| `failure` | Phosphor | `xCircle` | |
| `clock` | Phosphor | `clock` | |
| `signal` | Phosphor | `cellSignalFull` | |
| `search` | Phosphor | `magnifyingGlass` | |
| `filter` | Phosphor | `funnel` | |
| `edit` | Phosphor | `pencilSimple` | |
| `delete` | Phosphor | `trash` | |
| `copy` | Phosphor | `copy` | |
| `share` | Phosphor | `shareNetwork` | |
| `download` | Phosphor | `downloadSimple` | |
| `upload` | Phosphor | `uploadSimple` | |
| `importFile` | Phosphor | `fileArrowDown` | |
| `exportFile` | Phosphor | `fileArrowUp` | |
| `scanNetwork` | Phosphor | `scan` | |
| `link` | Phosphor | `linkSimple` | |
| `undo` | Phosphor | `arrowCounterClockwise` | |
| `show` | Phosphor | `eye` | |
| `hide` | Phosphor | `eyeSlash` | |
| `sliders` | Phosphor | `slidersHorizontal` | |
| `settings` | Phosphor | `gear` | |
| `sun` | Phosphor | `sun` | |
| `moon` | Phosphor | `moon` | |
| `contrast` | Phosphor | `circleHalf` | |
| `globe` | Phosphor | `globe` | |
| `shield` | Phosphor | `shield` | |
| `mail` | Phosphor | `envelopeSimple` | |
| `star` | Phosphor | `star` | |
| `externalLink` | Phosphor | `arrowSquareOut` | |
| `help` | Phosphor | `question` | |
| `upgrade` | Phosphor | `diamond` | |
| `book` | Phosphor | `book` | |
| `route` | Phosphor | `signpost` | |
| `network` | Phosphor | `network` | |
| `globeNetwork` | Phosphor | `globeHemisphereWest` | |
| `pip` | Phosphor | `browsers` | |
| `autoCycle` | Phosphor | `repeat` | |
| `language` | Phosphor | `translate` | |
| `diagnostics` | Phosphor | `pulse` | |
| `troubleshoot` | Phosphor | `lifebuoy` | |
