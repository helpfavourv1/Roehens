# Decisions

Every choice that deviates from, or fills in, the specification is recorded here with its reason.

## Toolchain pins

| Item | Value | Reason |
|---|---|---|
| Flutter | 3.47.6 (stable) | Latest stable at kickoff (2026-10-03). Same version on the owner's phone and in CI |
| Dart | 3.13.5 | Bundled with Flutter 3.47.6 |
| `pubspec.lock` | committed, produced by the `bootstrap` workflow | CI installs with `--enforce-lockfile` once it exists |
| minSdk (Android) | decided after the P2B spike | Depends on the Flutter 3.47 minimum and the chosen player engine |
| iOS deployment target | decided after the P2B spike | Flutter 3.47 raised its own minimum to iOS 15; the player engine may raise it further |

## Process decisions

1. **Build loop.** The build agent writes code in its own environment and pushes batches to `main`. The Flutter SDK cannot be downloaded there, so `flutter pub get`, `flutter analyze`, `tool/guard.sh` and `flutter test` run in GitHub Actions on every push (`check.yml`). This replaces the phone-based loop in spec H1 and H3.
2. **Push-triggered check.** `check.yml` triggers on push to `main`. This overrides spec G3 ("no push trigger") for this one workflow only, at the owner's request. It builds nothing and signs nothing. All build and signing workflows are manual (`workflow_dispatch`).
3. **Reading CI results.** Each run publishes its output to the `ci-logs` branch (`latest.log`) via `tool/ci_publish_log.sh`, because job logs are not downloadable from the agent's environment.
4. **Platform scaffold.** `flutter create` cannot run in the agent's environment, so the manual `bootstrap` workflow generates the `android/` and `ios/` folders and `pubspec.lock` and commits them. Only those folders are copied; `lib/`, `test/` and `pubspec.yaml` stay hand-authored.
5. **Application host.** The app is hosted on `WidgetsApp`, not `MaterialApp`. Flutter 3.47 is splitting Material and Cupertino out of the SDK, with formal deprecation scheduled for the next stable. All visuals already come from the in-repo component library, so nothing depends on them. This refines spec C1.2.
6. **Repository visibility.** Public, as the spec requires. Actions minutes are unlimited on public repositories.
7. **AdMob.** Google's published sample App IDs and sample banner units are used wherever an ID is needed until real units exist, so the app can never crash at launch on a missing or malformed App ID. Real IDs replace them before the first store release.
8. **Lint set.** `flutter_lints` plus five extra rules, with strict-casts, strict-inference and strict-raw-types.
9. **Localization config.** `app/l10n.yaml` is added in batch P6B together with `generate: true` and the first ARB files. It was removed from P0 because Flutter's build runs the localization step whenever the file exists and fails while `generate` is off (found by the first real Android build).

## Player engine (checkpoint CP1)

**Engine: `media_kit` 1.2.6 with `media_kit_video` 2.0.1 and `media_kit_libs_video` 1.0.7, behind `PlayerContract`.** On Android it bundles libmpv from `media-kit/libmpv-android-video-build` release v1.1.7, flavor `default`. On iOS it uses the `ios-universal-video-default` xcframeworks.

**License.** Both default flavors build FFmpeg without GPL (the Android script passes `--disable-gpl`; the Darwin README lists FFmpeg as LGPL-2.1 with GPL and nonfree omitted). The GPL `encodersgpl` flavor is not used and must never be selected. libmpv and FFmpeg are dynamically linked; LGPL notices go on the licenses screen and the build flavor is pinned. `media_kit` itself is MIT.

**Maintenance.** Active (commits through August 2026, libmpv builds updated September 2026). An open issue asks about project status and release plans, so the engine stays behind the contract.

**Device findings (Redmi `25028RN03A`, Android 15 / SDK 35, low-RAM device, debug build, mobile data, 8 streams opened at once):**

| Finding | Result |
|---|---|
| Builds on Flutter 3.47.6 with sqflite, secure storage and shared preferences | yes |
| HTTPS H.264 test video | plays |
| RTSP over TCP, H.265 5 MP (2592x1944) with PCM mu-law audio | plays (live; camera clock matched). Software decoding: hardware HEVC configuration failed on this device. Audio underruns and A/V desync warnings. First frame 15.6 s, then 6.4 s on a second run |
| RTSP over TCP, H.264 720p | plays with hardware decoding (`mediacodec-copy`). First frame 13.1 s on a distant server |
| MJPEG over HTTP (multipart) | **does not work with the stock build**: decode errors on every multipart stream tried |
| Frame access (still image of the playing stream) | yes: `Player.screenshot` returned data for both RTSP streams |
| Stream to file without re-encoding | **no with the stock build**: "Output format not found" |
| Picture-in-picture | **device does not support it** (`lowRam=true`, `pipFeature=false`) |

**Cause of the two failures, confirmed in the build script `buildscripts/flavors/default.sh`:** the default flavor passes `--disable-muxers` and enables no muxer, and it enables the `mjpeg*` demuxers but not `mpjpeg` (the multipart format cameras send over HTTP). It also enables no `udp` protocol, so RTSP over UDP is unavailable in the stock build.

**Decisions.**
1. **MJPEG over HTTP and HTTP snapshots are implemented in Dart** (own HTTP client, multipart parser, Flutter image decoding), not through the player engine. Same behavior on both platforms, no dependency on FFmpeg build flags, and decoded frames are available for later motion detection.
2. **RTSP uses media_kit.** R1 keeps both RTSP transports. TCP works with the stock build. UDP needs a custom libmpv flavor (fork of the Android build scripts, built in CI, LGPL components only) that adds the `udp` protocol; it is built before the R1 end gate. The same custom flavor adds muxers, which R3 (clips) and R4 (recording) require. Nothing is removed from any release.
3. **Picture-in-picture stays in R1 as the owner specified.** The specification gates it on the engine exposing a video surface; media_kit draws into a Flutter texture inside the activity, which picture-in-picture shows, so the surface requirement is met by design. The only available device (Redmi `25028RN03A`: Android 15, low-RAM, no PiP feature) cannot run it, so it cannot be verified on hardware. Plan: build it fully, hide the button at runtime on devices that report no support, and list it as "implemented, not verified on a device" in `QA_MATRIX.md` until a PiP-capable Android phone has run it. Whether to ship it unverified is the owner's decision. (An earlier version of this entry wrongly recorded it as deferred; that was not the owner's call.)
4. **Hardware HEVC.** The 5 MP main stream decodes in software on this device and cannot be shown smoothly. The grid uses substreams by design; fullscreen on a low-end phone may need a lower-resolution stream. Retest with `hwdec=mediacodec-copy` forced and with the camera's substream.
5. **Timings are not conclusive.** The first-frame times were measured with eight parallel connections over mobile data. The target (under 3 s) needs a LAN camera and sequential tests.
6. **Logs are shared.** The player's log callback delivers messages from every player to every tile, so per-tile logs cannot be attributed. The next spike runs one stream at a time.

## Dependencies and licenses

No third-party runtime dependency has been added yet. Each addition is logged here with version, maintenance status and license class.

## Design tokens (batch P1A)

1. **Two light-theme color adjustments.** With the specified values, hint text (`textTertiary`, `#667080`) on input fields (`bgTertiary`) measured 4.34:1 and accent text (`accent`, `#2F6FE0`) on the scaffold measured 4.34:1, both below the 4.5:1 AA threshold the specification requires. Changed to `textTertiary` `#636D7D` (4.54:1 on `bgTertiary`) and `accent` `#2F6CDD` (4.50:1 on `bgPrimary`; `borderFocus` follows the accent). The dark theme needed no change. `token_values_test.dart` enforces these ratios.
2. **No `ThemeExtension`.** `ThemeExtension` belongs to the Material library, which is leaving the SDK (see Process decision 5). Tokens are provided by an `InheritedWidget` (`AppTokens`) and read with `context.tokens`, `context.colors` and `context.type`.
3. **Spacing names.** `xxs`, `xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `xxxl` (the specification's `2xs`, `2xl`, `3xl`), because Dart identifiers cannot start with a digit and the guard flags digits in layout constructors.
4. **Formatters.** `date_formatter.dart` returns an `AgeSpan` (number plus unit) so the widget layer can localize it with plural rules; `intl` is added with the localization batch (P6B).
5. **Token freeze.** Tokens are frozen at the end of this batch (C8.2). Later changes need an entry here.
6. **Lockfile refresh.** The `check` workflow now refreshes `pubspec.lock` when `pubspec.yaml` changed and commits it back, because dependency resolution cannot run in the agent's environment. This replaces `--enforce-lockfile`.

## Icons (batch P1B)

1. **Phosphor fonts bundled, no icon package.** `phosphor_flutter` 2.1.0 (and upstream `main`) fails to compile on Flutter 3.47: it extends `IconData`, now a final class. The package is dropped. The MIT-licensed Bold, Fill and Duotone fonts and their glyph code points from tag `v2.1.0` are bundled as assets (`assets/fonts`), with source checksums in `ICON_MAP.md`. Glyph tables are generated once from upstream and live in `app_icons.dart` as compile-time constants, which release builds need for icon-font tree shaking.
2. **No Tabler.** Phosphor has a suitable glyph for every R1 icon. Tabler is a gap-filler by specification and is not used. A later release that finds a gap adds it with a reason in `ICON_MAP.md`.
3. **Own icon widget.** `AppIcon` is built on the core `Icon` widget and draws the duotone secondary layer itself.
4. **Mirroring.** Every Phosphor glyph is flagged to mirror in right-to-left layouts. `AppIcon` forces left-to-right for all icons except `chevronLeft`, `chevronRight`, `back` and `forward`, so PTZ arrows, zoom and every other icon keep their orientation. `app_icon.dart` is on the guard's list of files allowed to use `TextDirection.ltr`.
5. **R1 names only.** The monitoring and recording icons are added by the batch of the release that needs them.
6. **License.** Phosphor Icons, MIT. The notice is registered through `LicenseRegistry` and appears on the licenses screen.
