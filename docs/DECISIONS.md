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

## Store services (batch P2F)

1. **Packages.** `google_mobile_ads` 9.1.0 (Apache-2.0), `in_app_purchase` 3.x and `in_app_review` 2.x (BSD-3-Clause), `app_tracking_transparency` 2.x (MIT). All sit behind the contracts in `lib/core/contracts` and are imported only from `lib/platform/store`; the logic around each SDK is tested through a small backend interface, so only a thin wrapper touches the real SDK.
2. **Sample AdMob IDs.** Google's published sample app and banner IDs are used everywhere (Android app `~3347511713`, iOS app `~1458002511`, banner `/6300978111` and `/2934735716`, all read from Google's own plugin repository). The app IDs are in `AndroidManifest.xml` and `Info.plist`, because the SDK crashes at launch without one. `StoreConfig.usesTestAds` stays true until real units are created.
3. **Banner size.** The older `getCurrentOrientationAnchoredAdaptiveBannerAdSize` is kept on purpose (marked with an `ignore` and a comment). Its replacement can return banners up to 15% of the screen height, which could exceed the 100 dp slot and clip the ad.
4. **Tracking and local network strings.** `NSUserTrackingUsageDescription` and `NSLocalNetworkUsageDescription` were added to `Info.plist` in English now, because iOS stops the app when it asks for either without the string. They are localized in batches P7E-P7H.
5. **PurchaseContract.** Gained `failures`, a stream of purchases that failed after starting. A cancelled purchase is not a failure and is silent.

## Files, system and transfer services (batch P2G)

1. **Packages.** `share_plus` 13.x (BSD-3-Clause), `file_picker` 12.x (MIT) and `wakelock_plus` 1.x (BSD-3-Clause), each used only from `lib/platform`. Haptics and orientation use Flutter's own platform calls, so they add no dependency. Compile and test results on Flutter 3.47.6 are read from CI.
2. **Device contracts.** `lib/core/contracts/device_contract.dart` adds `HapticsContract`, `ScreenWakeContract` and `OrientationContract`, so providers in `core` can use these services without importing `platform`. This is one file beyond the specification's list.
3. **File transfer.** `ShareService` and `FilePickerService` are the specified files; `FileTransferService` joins them behind the existing `FileTransferContract`. The share sheet anchors at the screen center so it cannot fail on iPad.
4. **File picker accepts any file type.** Some providers label a `.json` file as plain binary, which a JSON-only filter would hide. The import service checks the content instead.
5. **Two error classes added.** `invalidFile` (a chosen file is not a Roehens camera list, is empty, or exceeds 1 MB) and `transferFailed` (share sheet or picker failed; manual retry). Both have message keys for the localization batch.
6. **Import.** Imported cameras never carry credentials. A camera matches a saved one by id or by protocol, host, port and path. The person picks skip, replace or duplicate; replace keeps the saved camera's id, position and credentials. One bad entry does not stop the rest, and invalid entries are counted for the preview. Limits: 1 MB and 200 cameras.
7. **Flags.** `FlagService` fetches only over https, only when a flags URL is configured, and serves the cache or the defaults otherwise. The URL stays unset until the website is hosted (open item for the owner). Re-check: every six hours, and on resume at most once every five minutes.
8. **Rating prompt policy.** Due when: first launch at least 3 days ago; at least 5 viewing sessions (counted once per app start); no error this session and none in the last 24 hours; at least 120 days since the last prompt; at most 3 prompts in total. All numbers are in `Limits`.
9. **Secure storage 11.x.** `share_plus` 13 and `flutter_secure_storage` 9.2.4 could not be resolved together (their Windows-only dependencies disagree on `win32`). The vault package moved to 11.x. Its Android implementation no longer uses `encryptedSharedPreferences` (deprecated upstream); it now keeps its own keystore-backed encryption, which is the default. The app has no released installs, so no stored data needs migrating. The vault tests and the next device build are the check.

## Providers (batch P3A)

1. **Guard: `dart:ui` allowed in `core`.** It is the engine's own library (it defines `Locale`), not a plugin and not `dart:io`. The layer rule still forbids `dart:io` and plugin imports.
2. **`SafeValueNotifier`.** Every provider extends it, so a storage call that finishes after the provider was disposed cannot throw.
3. **Derived providers.** `ThemeProvider` and `LocaleProvider` follow `SettingsProvider`, so settings stay the one source of truth.
4. **Entitlement.** The cached ad-free answer applies at once; the store's answer replaces it, including a downgrade after a refund. If the store cannot be reached the cache stays. Where billing is unsupported the app stays free and the cache is cleared.
5. **Layouts.** The camera order lives in the active layout; cameras the layout does not know are placed last. The current page is session state and is not saved. Default layout: 4 tiles.
6. **Discovery.** A device found by both ONVIF and the sweep is listed once, with the ONVIF details. The `discovery` kill switch and a refused local-network permission each have their own status. Timeout 20 seconds (D9).
7. **Auto-cycle.** Runs only while enabled, the app is in the foreground and Live or Fullscreen is showing. A touch restarts the wait. The layout's interval overrides the global one.
8. **Languages.** `lib/core/constants/languages.dart` lists the 24 launch languages with native names and right-to-left flags.

## Component library 1 (batch P4A)

1. **Size tokens added** for the controls (switch, chip, badge, segmented control, spinner, input border, focus ring, selection handle). Colors, type, spacing, radius and motion are unchanged.
2. **No `setState`.** The guard bans it, so components keep local state (pressed, focused, concealed) in `ValueNotifier`s.
3. **One tap target.** `AppPressable` gives opacity (or tint) feedback, Enter/Space activation, a focus ring and button semantics. A semantic label replaces the child's own text so it is not read twice.
4. **Text fields without Material.** `AppTextField` uses `EditableText` with in-repo selection handles. The cut/copy/paste menu is the system's own (`SystemContextMenu`), which is already in the person's language; where the system cannot show it, no menu appears. Whether paste works on the test phone is a checkpoint A1 question.
5. **The tokens must sit above the navigator.** Selection handles, menus and toasts are drawn in the overlay, so the app shell (P6A) wraps `AppTokens` around the whole navigator through the app's `builder`, not inside a page.
6. **Test font.** The widget-test font draws every character as a full square, so large-text tests use a tall surface.

## Component library 2 (batch P4B)

1. **Direction is read in one place.** `context.isRtl` (in `lib/utils/context_extensions.dart`) is the only code that compares against `TextDirection.rtl`. The guard still bans the constant everywhere else, so nothing can force a direction.
2. **Modal surfaces share one route.** `AppModalRoute` (in `app_page_route.dart`) serves sheets and dialogs: a scrim, dismissal by tapping outside, Escape or the back gesture, 400 ms slide-up for sheets and 200 ms fade for dialogs, and no motion at all when reduced motion is on. A dialog can be made non-dismissible.
3. **Toasts.** One at a time, drawn in the overlay above the bottom bar (or above the keyboard). The action is a pill; the Undo toast uses the 8-second undo window.
4. **Bottom stack.** `AppScaffold` collapses the embed (ad slot) and the bottom bar together under the keyboard and brings them back when it closes. The bottom bar paints the safe-area inset itself, so its fill reaches the screen edge.
5. **Alphabetical lists.** Use `AppLetterHeader.group`: a plain pinned header stacks under the previous letter in Flutter, and the group form makes the next letter push the previous one away.
6. **Slider.** Announces its current value and the next step up and down. Callers can give a spoken label for a value (for example "4 hours"); the default is the percentage.
7. **Text scale caps.** Bottom bar labels stop growing at 130% (`context.clampedTextScaler`), because the bar has a fixed height.

## Viewer widgets (batch P4C)

1. **Tiles take what they show as parameters.** `CameraTile` gets the video view as a widget, the poster as bytes, and every word already translated. Widgets never import `platform/`, so the shell (P5A) builds the video view from the session's handle; a `VideoSurface` for that lives in `platform/player` and is added with the Live screen.
2. **Narrow tiles (under 120).** The status becomes an icon, and the name plate uses small fixed-size type. The status icon keeps its visual size as its tap area, because a 48 px pill cannot fit in a 97 x 55 tile of a 16-up grid; the tile's own tap is the large target. The screen should let a tap on an errored narrow tile open the status sheet.
3. **Grid.** Tiles are 16:9, share the width equally, and the block is centered in the remaining height. Empty slots are not drawn. If the rows do not fit, the grid scrolls.
4. **Fullscreen controls.** Fade after three seconds, return on a tap on the picture, stay on while a screen reader is on, and any touch (including a drag on the PTZ pad) restarts the wait and reports activity to auto-cycle. Escape closes.
5. **PTZ pad.** Dead zone 15 percent, speed rising to full at the edge, values rounded to 0.1 and sent only when they change by 0.05. Lifting the finger sends stop. Arrow keys move at 80 percent while held. Zoom buttons act while held; a screen-reader activation pulses for 0.4 seconds. Arrows are physical and do not mirror in right-to-left layouts.
6. **`LtrText`** (in `ui/components`) is the one widget for technical values that must stay left-to-right.
