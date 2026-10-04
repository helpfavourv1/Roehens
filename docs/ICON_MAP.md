# Icon map

Each semantic icon (`AppIconName`) maps to exactly one glyph from exactly one source. Phosphor (`phosphor_flutter` 2.1.0, MIT) is the primary source. Tabler is the gap-filler and every Tabler use would carry a reason in the last column.

**Tabler is not used.** Every R1 icon has a suitable Phosphor glyph, so no Tabler package is a dependency. If a later release finds a gap, add the package, log it in `DECISIONS.md`, and record the reason here.

Identifiers were read from the installed package source (1,512 glyphs per weight), never guessed. Weights in use: Bold (default), Fill (selected/active), Duotone (empty-state hero only). Regular, Light and Thin are not used.

Items to judge by eye at Gate 2 on the cheapest device:

- `layoutGrid6` and `layoutGrid12` use the closest available glyphs (`columns`, `dotsNine`), not exact 2x3 and 3x4 grids.
- `pip` uses `browsers` because Phosphor has no picture-in-picture glyph.
- `cameraPtz` uses `arrowsOutCardinal`.

Only `chevronLeft`, `chevronRight`, `back` and `forward` mirror in right-to-left layouts.

| Semantic name | Source | Glyph | Reason (Tabler only) |
|---|---|---|---|
| `chevronLeft` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.caretLeft` | |
| `chevronRight` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.caretRight` | |
| `chevronUp` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.caretUp` | |
| `chevronDown` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.caretDown` | |
| `back` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowLeft` | |
| `forward` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowRight` | |
| `close` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.x` | |
| `menu` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.list` | |
| `more` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.dotsThree` | |
| `check` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.check` | |
| `plus` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.plus` | |
| `minus` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.minus` | |
| `cameraDome` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.securityCamera` | |
| `cameraBullet` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.videoCamera` | |
| `cameraPtz` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowsOutCardinal` | |
| `cameraAdd` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.cameraPlus` | |
| `cameraOff` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.cameraSlash` | |
| `layoutGrid1` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.square` | |
| `layoutGrid2` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.squareSplitHorizontal` | |
| `layoutGrid4` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.squaresFour` | |
| `layoutGrid6` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.columns` | |
| `layoutGrid9` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.gridNine` | |
| `layoutGrid12` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.dotsNine` | |
| `layoutGrid16` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.gridFour` | |
| `layoutRows` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.rows` | |
| `fullscreenEnter` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.cornersOut` | |
| `fullscreenExit` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.cornersIn` | |
| `snapshot` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.camera` | |
| `play` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.play` | |
| `pause` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.pause` | |
| `refresh` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowClockwise` | |
| `volumeOn` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.speakerHigh` | |
| `volumeOff` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.speakerSlash` | |
| `zoomIn` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.magnifyingGlassPlus` | |
| `zoomOut` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.magnifyingGlassMinus` | |
| `ptzArrowUp` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowFatLineUp` | |
| `ptzArrowDown` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowFatLineDown` | |
| `ptzArrowLeft` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowFatLineLeft` | |
| `ptzArrowRight` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowFatLineRight` | |
| `ptzHome` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.target` | |
| `home` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.house` | |
| `live` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.broadcast` | |
| `wifi` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.wifiHigh` | |
| `wifiOff` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.wifiSlash` | |
| `lock` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.lock` | |
| `unlock` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.lockOpen` | |
| `warning` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.warning` | |
| `info` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.info` | |
| `success` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.checkCircle` | |
| `failure` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.xCircle` | |
| `clock` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.clock` | |
| `signal` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.cellSignalFull` | |
| `search` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.magnifyingGlass` | |
| `filter` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.funnel` | |
| `edit` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.pencilSimple` | |
| `delete` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.trash` | |
| `copy` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.copy` | |
| `share` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.shareNetwork` | |
| `download` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.downloadSimple` | |
| `upload` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.uploadSimple` | |
| `importFile` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.fileArrowDown` | |
| `exportFile` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.fileArrowUp` | |
| `scanNetwork` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.scan` | |
| `link` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.linkSimple` | |
| `undo` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowCounterClockwise` | |
| `show` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.eye` | |
| `hide` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.eyeSlash` | |
| `sliders` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.slidersHorizontal` | |
| `settings` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.gear` | |
| `sun` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.sun` | |
| `moon` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.moon` | |
| `contrast` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.circleHalf` | |
| `globe` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.globe` | |
| `shield` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.shield` | |
| `mail` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.envelopeSimple` | |
| `star` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.star` | |
| `externalLink` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.arrowSquareOut` | |
| `help` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.question` | |
| `upgrade` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.diamond` | |
| `book` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.book` | |
| `route` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.signpost` | |
| `network` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.network` | |
| `globeNetwork` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.globeHemisphereWest` | |
| `pip` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.browsers` | |
| `autoCycle` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.repeat` | |
| `language` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.translate` | |
| `diagnostics` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.pulse` | |
| `troubleshoot` | Phosphor | `PhosphorIcons{Bold,Fill,Duotone}.lifebuoy` | |
