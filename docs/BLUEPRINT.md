# Roehens: FULL PRODUCT & BUILD SPECIFICATION

> **The master blueprint.** This is the plan the project was started from, copied word for word from the owner's merged specification v2.0 (Oct 1, 2026). It is not edited for progress. Where the build deliberately differs, `DECISIONS.md` records it and wins. Current state and next steps are in `HANDOFF.md`. One wording change: in Part F the credential pattern is described in words so that this document does not trip the secret scan.

IP camera viewer for iOS and Android (Google Play)

Merged specification v2.0 · Oct 1, 2026 (supersedes the Sep 30, 2026 draft)

IP camera viewer for iOS and Android (Google Play). Amazon Fire is a separate repo cloned from this one after Release R1 ships (Part J).

## Source documents and precedence

| # | Source | Role |
|---|---|---|
| 1 | Full Product & Build Specification (Sep 30) | Base text: architecture, process, data, screens, batches |
| 2 | Premium Application Blueprint, Enterprise Production Standard | Finish-quality bar (values V1-V10, Forbidden, Required). Applied in Part C and C8 |
| 3 | `1_Product_name.txt` | Concrete values: name, account, identifier, repo, entitlement decision, test streams, icon plan, artwork |
| 4 | Updated Scope Proposal | Scope additions (Help, monitoring tiers, 24 languages, restored features) and decisions H1-H12 |
| 5 | Owner answers, Oct 1, 2026 | Working mode, release staging, defaults. Recorded in Part K |

Precedence: owner decisions (Part K) > this document > source documents. On visual finish the Premium Blueprint governs, except where C8.9 records an explicit exception. Where a source document cited a rule that it does not actually contain, this document states the rule on its own authority (Part K, K4).

## Release map (what ships when)

| Release | Contents | Ships |
|---|---|---|
| **R1** (first shipped release) | The live viewer (A2) + Help and remote-access section + 24 languages + auto-cycle + Android picture-in-picture (engine-gated) + in-app language picker | First |
| **R2** | Tier 1 monitoring: health monitor, in-app alerts, on-device motion detection with zone masks, event logs, snapshot archive, Activity tab (timeline, search, filter) | After R1 is live and stable |
| **R3** | Tier 2: recording schedules, pre/post-event clips, clip export | After R2 |
| **R4** | Tier 3: local video recording (foreground only), playback, storage manager | After R3 |

R2 to R4 are fully specified so the data model, seams and flags leave room for them. **No R2-R4 file is authored until the previous release is live** (rule 7 below).

## Owner working mode

The owner works from a phone (Termux + proot Ubuntu). `flutter analyze` and the guard run after every batch. Manual CI runs happen only at the checkpoints in H5. Git uses HTTPS with a personal access token (H1).

## Governing principles

Architecture and process rules are this document's own: single Flutter codebase, `core/` vs `platform/` layering, store-dependent code behind interfaces, manual-only CI, graceful third-party failure, minimum permissions, identity tracking, analyze-gated batches. Finish-quality rules come from the Premium Blueprint (Part C, C8). Where this document is more specific than the Blueprint, this document wins.

**Agent rules of engagement**
1. At kickoff, check current stable Flutter/Dart, current package versions, current store requirements. Choose and pin exact versions in `pubspec.yaml`, `pubspec.lock`, GitHub Actions and Codemagic (all identical). Record every choice in `docs/DECISIONS.md`.
2. Version and package choices below are candidates, not mandates. Verify maintenance status, iOS/Android support and license for each before use. Log the license class.
3. No code-generation packages (no `build_runner`, `freezed`, `json_serializable`, `drift` codegen). Models are hand-written so `flutter analyze` is the only gate needed in the phone-based loop.
4. No `TODO`, `FIXME`, `UnimplementedError`, or placeholder screens in any batch that is pushed.
5. Never use the word "just" in generated docs or comments without a defined behavior behind it.
6. **Secrets never enter the repo.** No passwords, tokens, keystores, or stream URLs containing credentials in any file, commit, comment or doc. Spike streams arrive as CI secrets (Part B). Documents record host class and codec only.
7. **Current release only.** Author only the files of the release being built. Later releases are planned in H4b; they are not scaffolded, stubbed or pre-wired.
8. **Cite rules by their current identifier.** Store and platform rules are cited by the number in force today and checked against the live source before use (Apple's background-services rule is Guideline 2.5.4 today, not the old 2.16 number).

---

## PART A: PRODUCT DEFINITION

### A1. Identity

| Field | Value |
|---|---|
| Product name | `Roehens` |
| Identifier (iOS bundle ID, Android applicationId, Android namespace) | `com.zdmgold.roehens` |
| Account segment | `zdmgold` (identifier only). The GitHub owner is a different account: `helpfavourv1` |
| Dart package / project folder / repo name | `roehens` / `Roehens` / `Roehens` |
| Category | Utilities (fallback: Lifestyle) |
| Tagline | Every camera on your network, one calm screen. |
| Platforms | iOS (current toolchain minimum, recorded in `docs/DECISIONS.md`); Android with one `minSdk` value recorded once in `docs/DECISIONS.md` after the P2B spike (working value API 23, Android 6.0; lowered only if the pinned Flutter and the chosen engine both support it) |
| Default theme | **Dark** (follows system on first launch; user override persisted) |
| Languages | 24 (D14), including 4 right-to-left |
| Cost floor | Zero monthly |

Default theme is a product decision: video is the hero and dark surfaces make streams look better. The light theme is fully designed, not derived.

### A2. Scope by release

**R1 (first shipped release).** In: multi-camera grid, fullscreen viewer, digital zoom, PTZ, snapshots (share sheet), ONVIF and subnet discovery, guided add-camera flow with brand profile database, connection tester with plain-language diagnosis, local camera storage with secure credentials, camera list export/import (credentials stripped), dark/light/system theme, ads + ad-free purchase, onboarding with local-network rationale, kill-switch flags, **Help and remote-access section** (hub, ten articles, remote-access wizard, troubleshooter, network diagnostics), **24 languages with an in-app language picker**, **auto-cycle**, **Android picture-in-picture** (only if the P2B spike proves the engine exposes a video surface; otherwise it moves to a later release and is logged).

**R2 (Tier 1, monitoring).** Camera health monitor, in-app alerts with best-effort local notifications, on-device motion detection on decoding tiles, per-camera sensitivity and zone masks, motion and offline/online event logs, motion-triggered snapshots, snapshot archive, Activity tab with timeline and search/filter.

**R3 (Tier 2).** Recording schedules, pre/post-event clips, clip and snapshot export.

**R4 (Tier 3).** Local video recording in segments, playback, storage manager with budget screen and auto-evict.

**Out of every release:** background recording, background alerts, audio-only mode, remote push notifications, accounts, sync, cloud upload, cloud relay, two-way audio, home-screen widgets, Wear/TV, iOS picture-in-picture. Each has a recorded reason in Part K. Anything else on the Scope Proposal's rejected list stays rejected.

**Foreground-only truth (all releases).** Detection, alerts and recording run only while Roehens is open and on screen. Roehens works as a wall monitor: a phone or tablet left open, plugged in, screen awake. Onboarding, Help and both store listings say this plainly and promise nothing about background behavior.

**Remote access.** No relay or tunnel is built in. Users reach cameras away from home through their own VPN, DDNS, static IP with port forward, or a third-party relay. The app accepts hostnames and custom ports. The Help section teaches how to build each path (D10). The store listing says this plainly.

### A3. Capability matrix (final)

| Capability | Included | Release | Notes |
|---|---|---|---|
| Camera CRUD, search/filter, undo delete | yes | R1 | in-memory filter; 8-second undo (Undo is a pill, never bare text) |
| Credential vault | yes | R1 | Keychain / Keystore only; never in DB or exports |
| Playback: RTSP (TCP + UDP), MJPEG over HTTP, HTTP snapshot polling | yes | R1 | engine chosen in spike (D3) |
| Grid (1/2/4/6/9/12/16), paging, substream/mainstream switching | yes | R1 | |
| Fullscreen, immersive, digital zoom 1-4x, mute | yes | R1 | camera audio playback only, no microphone |
| ONVIF discovery, device info, profiles, stream URI, PTZ | yes | R1 | |
| Subnet sweep discovery | yes | R1 | always present on iOS; WS-Discovery is added only if Apple grants the entitlement |
| Brand profile database (bundled JSON) | yes | R1 | |
| Connection tester | yes | R1 | |
| Snapshot to share sheet | yes | R1 | no storage permission |
| Import/export camera list | yes | R1 | stripped of credentials |
| Keep screen awake while viewing | yes | R1 | |
| Ads (adaptive banner, home only) | yes | R1 | consent + ATT; slot spec in C8.4 |
| Ad-free purchase | yes | R1 | one-time non-consumable |
| Remote kill-switch flags | yes | R1 | static JSON on the marketing site |
| Rating prompt | yes | R1 | frequency-capped, never after an error |
| Feedback (mail, optional diagnostics attach) | yes | R1 | |
| Legal surface (privacy, terms, licenses) | yes | R1 | |
| Help: hub, 10 articles, remote-access wizard, troubleshooter, network diagnostics | yes | R1 | content only, no backend; public-IP lookup is user-triggered and disclosed (D10) |
| 24 languages, 4 RTL, in-app language picker | yes | R1 | machine-translated (D14) |
| Auto-cycle | yes | R1 | local timer; Settings toggle plus per-layout interval |
| Picture-in-picture | Android only | R1 | gated on the P2B spike; iOS deferred (Part K) |
| Camera health monitor | yes | R2 | foreground only |
| Alerts: in-app banner + best-effort local notification | yes | R2 | `POST_NOTIFICATIONS` is requested only when the user turns alerts on |
| Motion detection (on-device, decoding tiles only) | yes | R2 | foreground only |
| Zone masks, per-camera sensitivity | yes | R2 | |
| Event logs (motion, offline/online) | yes | R2 | |
| Snapshot archive / gallery | yes | R2 | app sandbox, no storage permission |
| Activity tab: timeline, search/filter | yes | R2 | |
| Recording schedules | yes | R3 | |
| Pre/post-event clips, clip export | yes | R3 | engine-gated (D3) |
| Local video recording (segmented) | yes | R4 | foreground only |
| Recording playback | yes | R4 | |
| Storage manager (budget screen, auto-evict) | yes | R4 | |
| Background recording, background alerts, audio-only, push, accounts, sync, cloud | **no** | none | no permission, no dead code |

### A4. Store-dependent seams (this is what makes the Amazon clone cheap)

Everything that differs by store lives only in `lib/platform/store/` and is reached through contracts in `lib/core/contracts/`. The seam files are: `store_config.dart`, `admob_service.dart`, `consent_service.dart`, `att_service.dart`, `billing_service.dart`, `review_service.dart`. No other file may import `google_mobile_ads`, `in_app_purchase`, `in_app_review`, or reference a store name. `tool/guard.sh` enforces this.

No new seam is needed for R2-R4: they run foreground-only (Part K, H7), so no store-dependent background service exists.

---

## PART B: IDENTITY / ACCOUNT TRACKING (living: `docs/IDENTITY.md`)

| Field | Value | Status |
|---|---|---|
| Product name | Roehens | ✅ |
| Identifier | `com.zdmgold.roehens` (immutable after first release) | ✅ |
| GitHub repo (public) | `https://github.com/helpfavourv1/Roehens.git` (owner `helpfavourv1`). Owner confirms it is empty: no README, no license, no `.gitignore` | ⬜ confirm empty |
| GitHub access token | Fine-grained token scoped to `Roehens` only: Contents read/write and Workflows read/write (Workflows is required to push `.github/workflows/*`). Stored in the phone's git credential helper. Never committed, never pasted into docs | ⬜ |
| Flutter arm64 gate (`flutter doctor`, `flutter analyze` on a blank app, both pass) | owner marked "to be reverified" | ⬜ |
| Apple Multicast Networking entitlement | **Request: yes, file now.** Fallback identifier while denied or pending: `subnet_sweep_only` (D4) | ⬜ file request |
| Spike test streams | GitHub secrets `SPIKE_RTSP_URL`, `SPIKE_MJPEG_URL`. Values are held by the owner and are not written in the repo. RTSP: H.265/HEVC Main, 2592x1944, 25 fps, PCM mu-law audio. MJPEG: `multipart/x-mixed-replace`. Both re-verified reachable at build time (first step of `android_debug.yml`) | ⬜ add secrets |
| Reviewer test stream (Apple 2.1) | **Deferred.** The spike streams are build-phase only. A stable stream the owner controls is a release blocker for App Store submission, not a start condition | ⬜ before submission |
| Public-IP lookup service (R1, H1) | one free service with usable terms, chosen at kickoff, recorded in `docs/DECISIONS.md`; disclosed in privacy policy, Play Data safety and Apple privacy label | ⬜ |
| Play Console app + Play App Signing enrolled | | ⬜ |
| Android upload keystore (base64 in GitHub secret) + key alias | | ⬜ |
| GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | | ⬜ |
| App Store Connect app | | ⬜ |
| Apple Team ID | | ⬜ |
| App Store Connect API key ID / issuer ID / private key (Codemagic env) | | ⬜ |
| AdMob app + banner unit: Android, iOS | | ⬜ |
| IAP product ID (ad-free) | `com.zdmgold.roehens.adfree` (non-consumable) | ⬜ |
| Play in-app product configured | | ⬜ |
| Static hosting project + account ID | | ⬜ |
| Codemagic project | | ⬜ |
| Privacy policy URL / Support URL / Flags JSON URL | | ⬜ |
| Owner artwork (one master, derived layers; C1.8, P7C) | due before P7C | ⬜ |
| Cheapest Android test device (model, Android version, RAM) | owner records here; used for Gate 2 (C8.5) and the 4-stream test | ⬜ |
| iPhone/iPad test device | owner records here, or states none (then iOS visual checks are limited to TestFlight screenshots from a borrowed device) | ⬜ |
| Reference-tier apps for Gate 2 | Apple Home (iOS), Google Home (Android), proposed default | ✅ |
| Play Console Foreground Service declaration | **Not required**: no foreground service in any release (H7) | ✅ n/a |
| Store listing locales (24) accepted by each store | verify each locale per store before localized listing work (P7E-P7H) | ⬜ |

The reverse-DNS identifier is immutable after first release. Check this table before every dashboard action.

---

## PART C: DESIGN SYSTEM (premium, license-clean)

### C1. Non-negotiable look-and-feel rules

1. **No Material icons, no Cupertino icons, ever.** `pubspec.yaml` sets `uses-material-design: false` so any accidental `Icons.*` renders as an obvious missing glyph in testing. `tool/guard.sh` fails the batch on `Icons.` or `CupertinoIcons`.
2. **No stock Material or Cupertino components in UI code.** Forbidden by guard: `ElevatedButton`, `TextButton`, `OutlinedButton`, `FloatingActionButton`, `AppBar`, `BottomNavigationBar`, `NavigationBar`, `Card`, `ListTile`, `Switch`, `Checkbox`, `Radio`, `Chip`, `SnackBar`, `AlertDialog`, `Drawer`, `DropdownButton`, `InkWell`, `InkResponse`, `CupertinoButton`, `CupertinoSwitch`, `MaterialPageRoute`, `CupertinoPageRoute`. `MaterialApp` is allowed only as an invisible host (localization, navigator, overlay, text selection), with all visuals supplied by the in-repo component library in `lib/ui/components/`. A user must not be able to name the widget library (Blueprint V1).
3. **No ripple, no ink splash, no scale.** `splashFactory: NoSplash`, `highlightColor` transparent. Press feedback is an opacity change (cards, tiles, buttons, chips) or a `bgTertiary` tint (rows). See C6.
4. **Depth.** No shadows in dark mode: depth is surface step plus hairline border. In light mode cards, rows, tiles and buttons never carry a shadow; only floating surfaces (sheets, dialogs, menus, toasts) use the two shadow tokens in C5.
5. **Fonts: system fonts by default.** The four typography roles (C3) are realized with weight, size, tracking and the platform monospace face. One free-licensed font (OFL, Apache-2.0 or MIT) may be bundled as an asset for the Latin Display role only, and only if Gate 2 shows the system display weight is insufficient; the license is logged in `docs/DECISIONS.md` and its notice reaches `LicenseRegistry`. Never bundle fonts for non-Latin scripts: those always use system fonts. No remote fonts anywhere, in the app or on the website. Tabular figures for all numbers that change (timestamps, bitrates, resolution).
6. **Icons: Phosphor (primary) and Tabler (gap-filler only),** both permissively licensed, both direct dependencies in `pubspec.yaml` (never transitive, so their fonts bundle), reached only through one in-repo wrapper (C4). No custom-drawn or AI-authored icon paths: the agent cannot see what it draws, so it does not draw.
7. **Scroll physics: `ClampingScrollPhysics` everywhere,** overscroll indicator disabled. No bounce, no spring anywhere. Screens are fixed layouts: chrome and primary actions are structurally fixed, only content lists scroll, and only when their content overflows.
8. **Launcher icon and splash mark are supplied by the owner** as one master image (designed outside the agent loop, since the agent cannot judge artwork). The agent only wires it: `tool/make_brand_assets.dart` resizes and composites the supplied master into the required sizes and layers (P7C). It draws nothing.
9. **Camera brand names appear as text only.** No brand logos, no trademarks used as visual assets. Third-party relay or service names in Help are text only, with no endorsement.
10. Every color, size, radius, spacing value, duration and curve in widget code comes from a token. Raw `Color(0x...)` outside `lib/ui/tokens/` fails the guard, as do raw numeric spacing/size literals and `Curves.` outside the token files (guard heuristics, F).
11. **Every tappable element is visibly tappable:** a card, a filled pill, or a bordered row. No bare text as a control: Retry, Edit, Undo and Add are pills or chips. No bare icon outside a card or a 40x40 chip. Primary actions are filled; outlined means secondary.
12. **Empty boxes are bugs.** A slot with nothing to show does not exist: zero height, no border, no shadow. No skeleton loaders (content either exists, or the slot is absent, or a status pill says why not).
13. **Brand appears once per screen**, and chrome lives in the nav bar, never in a floating hero (C8.7).
14. **One component per job.** One card, one row, one chip, one button. Screens never restyle or reimplement them.
15. **No SVG `<filter>`** in any asset or in the website: the renderer skips it silently and the shadow never appears.
16. **Right-to-left and long text are first-class.** Directional padding and alignment only. IPs, ports, URLs and RTSP paths always render left-to-right, including inside right-to-left layouts.

### C2. Color tokens (final values; contrast checked against the surface each is used on)

| Token | Dark | Light | Usage |
|---|---|---|---|
| `bgPrimary` | `#0A0C0F` | `#F4F6F9` | scaffold |
| `bgSecondary` | `#11141A` | `#FFFFFF` | cards, list groups |
| `bgTertiary` | `#171B22` | `#ECEFF3` | inputs, disabled, row press tint |
| `bgElevated` | `#1D222B` | `#FFFFFF` | sheets, dialogs, menus |
| `videoBackdrop` | `#050608` | `#050608` | behind every video surface, both themes |
| `borderSubtle` | `#232933` | `#DCE1E8` | hairlines (0.5dp), dividers |
| `borderStrong` | `#323A46` | `#C6CDD7` | inputs at rest, chips |
| `borderFocus` | `#5B9DFF` | `#2F6FE0` | focused input |
| `accent` | `#5B9DFF` | `#2F6FE0` | primary action, active nav, selection |
| `accentDim` | `#3F7FE0` | `#2258BA` | pressed state |
| `accentWash` | `#5B9DFF` at 14% | `#2F6FE0` at 10% | selected row, active chip fill |
| `textPrimary` | `#EDF0F4` | `#10141A` | headlines, body |
| `textSecondary` | `#A4ADBA` | `#465060` | subtitles |
| `textTertiary` | `#7C8695` | `#667080` | hints, timestamps, disabled (>= 4.5:1 on `bgSecondary`) |
| `textOnAccent` | `#061224` | `#FFFFFF` | label on accent fill |
| `error` | `#FF6B6B` | `#D13636` | failures, destructive |
| `warning` | `#F5B84A` | `#9A5B00` | connecting, attention |
| `success` | `#4ADE80` | `#17803D` | live, saved |
| `streamLive` | = `success` | = `success` | live pill |
| `streamConnecting` | = `warning` | = `warning` | reconnecting pill |
| `streamError` | = `error` | = `error` | error pill |
| `streamOffline` | = `textTertiary` | = `textTertiary` | offline pill |
| `scrim` | `#000000` at 56% | `#10141A` at 40% | behind sheets |
| `overlayOnVideo` | `#000000` at 48% | same | tile label plates (text on it is always `#FFFFFF`) |

Rule: status is never color alone; every status pill pairs color with an icon and a text label.

### C3. Typography (system font; sizes in logical px; scales with system text size up to 310%, tile overlays clamped to 130%)

| Style | Size | Weight | Line height | Notes |
|---|---|---|---|---|
| Display | 34 | 700 | 1.10 | onboarding, empty hero |
| Headline | 28 | 600 | 1.20 | |
| Title1 | 22 | 600 | 1.30 | screen titles |
| Title2 | 17 | 600 | 1.30 | section titles, camera names |
| Body | 15 | 400 | 1.45 | default reading |
| Callout | 15 | 500 | 1.40 | buttons, row titles |
| Footnote | 13 | 400 | 1.40 | |
| Caption | 12 | 400 | 1.30 | |
| Data | 12 | 500 | 1.30 | tabular figures, letter-spacing +0.2, timestamps/bitrate/resolution |
| Overline | 11 | 600 | 1.20 | uppercase, tracking +0.8, section headers |

Body is 15 (not 17) for control-panel density; Title2 stays 17. This is a product decision, not a Blueprint rule.

**Typography roles** (Blueprint: four distinct roles, never interchangeable)

| Role | Styles | Used for |
|---|---|---|
| Display (brand) | Display, Headline | wordmark, onboarding, hero numerals. The only role that may use a bundled Latin face (C1.5) |
| Chrome | Title1, Title2, Callout, Overline | nav bar titles, tab labels, buttons, chips, pills, section headers, the tagline |
| Body | Body, Footnote, Caption, Data | reading text, row subtitles, help articles, timestamps and figures |
| Monospace | Mono | URLs, IPs, ports, RTSP paths, diagnostics output, copyable values, code blocks. Always left-to-right |

Buttons and the tagline are Chrome, never Body.

**Script-aware line height.** Thai, Devanagari (Hindi), Bengali, Arabic, Persian, Urdu, Hebrew, Vietnamese and CJK need different line boxes than Latin. `typography_tokens.dart` multiplies every line height above by a per-script factor: Latin, Cyrillic 1.00 · Hebrew 1.05 · Vietnamese 1.10 · CJK 1.10 · Arabic, Persian, Urdu 1.20 · Devanagari, Bengali 1.20 · Thai 1.25. Factors are tuned at Gate 2 on the cheapest device with real strings. Overline's uppercase transform applies only to cased scripts.

### C4. Icon system (third-party, permissive, single wrapper)

**Sources**
- **Phosphor** (`phosphor_flutter`, MIT): primary source for every icon it covers. Provides regular, bold, fill and duotone weights.
- **Tabler Icons** (MIT): gap-filler only, used when Phosphor has no suitable glyph. Several Flutter packages exist (for example `tabler_icons`, `flutter_tabler_icons`); the agent verifies which one is actively maintained, supports the pinned Flutter, and carries a compatible license, then records the choice in `docs/DECISIONS.md`.
- Each semantic icon maps to exactly one glyph from exactly one source. Every Tabler use needs a one-line reason in `docs/ICON_MAP.md` ("no Phosphor equivalent for X").

**One wrapper, nothing else imports an icon package**
- `lib/ui/icons/app_icons.dart` is the only file allowed to import an icon package. It defines the semantic enum `AppIconName` (for example `cameraDome`, `layoutGrid4`, `ptzArrowUp`) and maps each name to a glyph.
- `lib/ui/icons/app_icon.dart` is the widget: `AppIcon(AppIconName.x, size:, color: token, weight:, semanticLabel:)`. Screens and widgets never touch the packages.
- `tool/guard.sh` fails a batch if any other file imports an icon package, or uses `Icons.` / `CupertinoIcons`.

**Weight and style rules (one visual language)**
- Default: Phosphor **Bold**. At 24 px, Phosphor Regular draws about 1.5 px strokes and Bold about 2.25 px, which satisfies the Blueprint's 2.0-2.25 stroke rule and matches the visual mass of 15-17 px text. Selected/active states (bottom bar, chips): Fill. Empty-state hero icons only: Duotone with the `accent` secondary tone. Regular, Light and Thin are not used.
- Tabler's default 2 px stroke sits within tolerance of Phosphor Bold. A Tabler glyph beside Phosphor ones is checked once at Gate 2 on the cheapest device; if the mismatch shows, replace the Tabler glyph or adjust its stroke. The outcome is logged in `docs/ICON_MAP.md`.
- Sizes by role (fixed): nav bar 24 · row leading 24 · row trailing 20 · chip 16 · bottom bar 24 · PTZ arrows 28 · empty-state hero 48. Semantic label required on every non-decorative use.

**No guessing glyph names**
The agent resolves each glyph identifier by searching the installed package source (for example `grep -ri "<keyword>" ~/.pub-cache/hosted/pub.dev/phosphor_flutter-*/lib`) and records the exact identifier in `docs/ICON_MAP.md`. A wrong identifier fails `flutter analyze`, so the existing gate catches mistakes without anyone needing to see the icon.

**Semantic inventory (about 90 names across R1-R4)**
- Navigation: chevrons, back, close, menu, more, check, plus, minus
- Camera and viewing: camera dome/bullet/PTZ, grid layouts (1, 2x2, 3x3, 4x4, rows), fullscreen enter/exit, snapshot, play, pause, refresh, volume on/off, zoom in/out, PTZ arrows, home position
- Status: live, wifi, wifi off, lock, unlock, warning, info, success, failure, clock, signal
- Actions: search, filter, edit, delete, copy, share, download, upload, import, export, scan network, link, undo, show/hide, sliders
- System: settings, sun, moon, contrast, globe, shield, mail, star, external link, help, upgrade/diamond
- Help and monitoring (R1-R4): help, book, route, network, globe-network, bell, bell-off, motion, mask, timeline, gallery, record, stop, storage, schedule, clip, pip, auto-cycle, language, trash
- The final list (about 90 names) lives in `docs/ICON_MAP.md`.

**Checks**
- Registry test: every `AppIconName` has a mapping, no accidental duplicates, all glyphs resolve.
- Font bundle test: `test/ui/icons/icon_font_bundle_test.dart` asserts that the font family of every weight in use (Bold, Fill, Duotone, and Tabler) is present in the font manifest. Missing fonts render as tofu boxes and the analyzer does not catch it.
- Bundle size: icon fonts ship per weight. Measure the APK/IPA size increase in the P2B spike build; if it is large, restrict to the weights actually used where the package allows.
- Licensing: both sets are MIT. Notices reach the in-app licenses screen through Flutter's `LicenseRegistry`. Log versions and licenses in `docs/DECISIONS.md`.

### C5. Spacing, shape, elevation, size

| Token set | Values |
|---|---|
| Spacing (4px grid) | 2xs 2 · xs 4 · sm 8 · md 16 · lg 24 · xl 32 · 2xl 48 · 3xl 64 |
| Radius | xs 4 · sm 8 · md 12 · lg 16 · xl 20 · pill 999 |
| Card | `bgSecondary` fill, radius lg, 0.5dp `borderSubtle`, no shadow in either theme, no ripple, opacity press feedback |
| Button | radius md, min height 48, no shadow |
| Input | radius md, `bgTertiary` fill, `borderStrong` at rest, `borderFocus` when focused |
| Sheet | top radius xl only |
| Dialog | radius lg |
| Video tile | radius md (the one recorded radius exception, C8.9), 0.5dp `borderSubtle`, `videoBackdrop` fill |
| Grid gutter | 4 (phone) · 8 (tablet) |
| Shadows (light mode, floating surfaces only) | `shadowPop` (menus, toasts): x0 y4 blur12 `#10141A` 10% · `shadowSheet` (sheets, dialogs): x0 y8 blur24 `#10141A` 12%. Dark mode: none. Cards, rows, tiles, buttons: never |
| Touch target | 48x48 hit area minimum everywhere; icon buttons draw a 40x40 chip inside the 48x48 hit area |
| Icon sizes | nav bar 24 · row leading 24 · row trailing 20 · chip 16 · bottom bar 24 · PTZ arrows 28 · empty-state hero 48 |
| Nav bar | 56 · Bottom bar 64 + safe area |
| PTZ pad | 176 diameter (tablet 208) |

### C6. Motion (no springs; reduce motion honored)

| Interaction | Duration | Easing |
|---|---|---|
| Screen push | 350ms | `glide`, fade + 20px slide |
| Screen pop | 280ms | `glide` |
| Sheet present | 400ms | `settle` |
| Press feedback | 120ms | `settle`; opacity to 0.72 (cards, tiles, buttons, chips) or `bgTertiary` tint (rows). No scale |
| Tile connect (poster to live) | 200ms | `settle` crossfade |
| Ad slot insert / collapse | 200ms | `settle` size animation |
| Controls auto-hide (fullscreen) | 200ms fade after 3s idle | linear |
| Auto-cycle transition | 200ms | `settle` crossfade |
| Theme toggle | 200ms | linear cross-fade |
| Live pulse | 1600ms loop, opacity 100% to 45% | linear |
| Reduce Motion | 0ms | instant; pulse becomes static; auto-cycle switches without a fade |

Curves are defined once in `motion_tokens.dart`: `glide = Cubic(0.70, 0.00, 0.20, 1.00)`, `settle = Cubic(0.12, 0.90, 0.28, 1.00)`. Framework `Curves.*` never appear elsewhere (framework-standard curves read as boilerplate). Values are tuned at Gate 2.

Haptics: light impact on primary actions, selection tick on layout change, success/warning on snapshot and errors. Through `HapticFeedback` (no dependency).

### C7. Accessibility

Semantics label on every interactive element and every tile (name + status + resolution). Logical reading order verified. Contrast >= 4.5:1 for text. 48dp touch targets. Reduce Motion honored. Text scaling to 310% with layouts that reflow (no clipped buttons). External keyboard: tab order, Enter/Space activate, Esc closes sheets and leaves fullscreen. Tablet and landscape layouts are first-class.
Right-to-left: Arabic, Persian, Urdu and Hebrew mirror layout from locale, not manual flipping. Directional icons (chevrons, back, forward) mirror; physical-direction icons (PTZ arrows, zoom) do not. IP, port, URL and path fields are forced left-to-right. The RTL widget test covers all four languages and includes an IP/URL field.

---

### C8. Premium Blueprint compliance (finish rules)

The Premium Application Blueprint is a quality bar, not a widget list. This section turns it into rules the guard, the tests and the checkpoints can enforce.

**C8.1 Values and where they are enforced**

| Value | Enforced by |
|---|---|
| V1 Belongs to the tier, not the framework | C1.2, C1.3; component library in `lib/ui/components/` |
| V2 Obviously interactive | C1.11 |
| V3 Icon and type weight balanced | C4 (Bold icons, sizes by role); Gate 2 |
| V4 Brand once per screen | C8.7 |
| V5 Space is intentional | C8.7 per-screen spacing decisions; tokens only |
| V6 Empty boxes are bugs | C1.12; C8.4 |
| V7 If it can drift, it will drift | C1.7 fixed layouts; no sliver tricks for fixed elements |
| V8 Cheapest device is the target | Part B device record; Gate 2; D9 |
| V9 Two gates | C8.5 |
| V10 Prototype uncertain visuals in isolation | C8.6; batch P4E |

**C8.2 Design tokens are frozen.** Tokens (C2, C3, C5, C6) are frozen at the end of batch P1A, before any widget is written. Any later change needs a `docs/DECISIONS.md` entry and a re-check of every screen that uses the token.

**C8.3 Component library.** Built before any screen (P4A, P4B). Seven components are the finish: Card (`app_card`), Row (`app_list_row`), Chip (`app_chip`), Primary button (`app_button`), Icon button (`app_icon_button`: 40x40 chip inside a 48x48 hit area), Section header (`app_section`), Empty state (`app_empty_state`). A screen that needs one uses it. A screen that implements its own version has a bug, and the guard fails `BoxDecoration(` and `DecoratedBox(` inside `lib/screens/`.

**C8.4 Third-party embed spec: the banner ad slot** (defined before integration, per the Blueprint)
- Reserved height: the height the SDK returns for the anchored adaptive banner, capped at 100dp. Nothing is reserved while the ad is absent.
- Gap above: `sm` (8). Gap below: `sm` (8). One hairline `borderSubtle` border on the top edge. Identical on every screen that shows it (Live only).
- The slot collapses to zero (gap, border, background and height all gone, nothing drawn) when: not yet loaded, init or load failed, consent unresolved, ad-free entitlement active, kill switch `ads` on, the keyboard is visible, or the screen is not Live.
- Insertion and collapse animate over 200ms (`settle`); the grid reflows once, never jumps.
- While the keyboard is up, the whole bottom stack (ad slot, its gaps and border) collapses with the bottom bar and returns when the keyboard closes. Content above never re-expands past its keyboard-open size.

**C8.5 Verification: two gates, both mandatory**
- **Gate 1 (code):** `flutter analyze` clean, `tool/guard.sh` passes, tests pass, commit. Every batch.
- **Gate 2 (visual):** screenshot on the cheapest supported device (Part B) compared with the reference-tier app (Apple Home on iOS, Google Home on Android) for weight, spacing and clarity. If it does not match, iterate. Results go in `docs/VISUAL_QA.md`.
- A screen is *implemented* after Gate 1 and *done* only after Gate 2. Because manual builds happen only at the checkpoints in H5, Gate 2 runs at each checkpoint for every screen built since the previous one. A screen that has not passed Gate 2 is listed in `docs/VISUAL_QA.md` as open and blocks the end gate.

**C8.6 Isolated visual prototypes** (batch P4E, `lib/spike/visual_spike_main.dart`, removed in P8). Built and viewed on the cheapest device before any screen: icon weight beside text (Bold vs a Tabler glyph), the video tile with status pill (icon-only at small widths), the PTZ pad, a sticky letter-header list, the ad slot insert/collapse, bottom-bar collapse under the keyboard, and the nav bar mirrored in Arabic.

**C8.7 Shape of every screen**
1. Nav bar: back or brand on the left, title in the Chrome face, actions on the right as 40x40 chips.
2. Primary content.
3. Secondary actions as cards or rows, placed consistently.
4. Bottom embed (Live only: the ad slot, C8.4).
- Brand: the wordmark appears only in the Live nav bar (left) and on onboarding page 1. Never twice on a screen, never as a floating hero. A hero or empty-state block never takes more than one third of the screen height.
- Section headers: Overline (small, uppercase where the script has case, letter-spaced, `textTertiary`). Lists use two-line rows (primary label, secondary line). Alphabetical lists (brand picker) use sticky letter headers, verified on device; search fields scroll away with content.
- Spacing is chosen per section from the spacing tokens; uniform spacing between unrelated elements is a defect.
- Safe area protects both top and bottom edges by default. The only exception is fullscreen immersive video, which restores insets when controls show.

**C8.8 Distribution rules.** Every permission maps to a capability in A3. Listing titles are search-optimized, not brand-first (candidate: "Roehens: IP Camera Viewer", checked against each store's length limit; secondary keywords RTSP, ONVIF, CCTV, DVR in the subtitle or short description). Pricing language matches what the build does. Tested on the cheapest target device. No remote fonts or assets: everything is bundled.

**C8.9 Recorded exceptions to the Blueprint**
- Video tile radius is `md` (12), not the card radius `lg` (16): tiles pack at 4dp gutters. This is the only radius exception.
- System fonts realize the four roles instead of four custom families (C1.5), for license cleanliness and 24-language coverage.
- Shadows exist only on floating surfaces in light mode (C5), a narrowing of the Blueprint's shadow spec, not a breach.

---

## PART D: SYSTEM BEHAVIOR

### D1. Data model (immutable, `copyWith`, `toJson`, `fromJson`, `==`/`hashCode`)

- **Camera:** id (uuid v4, generated in-repo), name, protocol (`rtsp`/`mjpeg`/`httpSnapshot`), host, port, mainPath, subPath, transport (`tcp`/`udp`/`auto`), brandId?, modelHint?, onvifEnabled, onvifPort?, username (stored in vault, not DB), sortIndex, createdAt, updatedAt.
- **StreamProfile:** kind (`main`/`sub`), path, codecHint, resolutionHint.
- **CameraBrandProfile:** id, displayName, defaultPorts, mainPathTemplates, subPathTemplates, mjpegTemplates, snapshotTemplates, notes, verified flag.
- **GridLayout:** id, columns, rows, pageSize, order of camera ids, autoCycleSeconds?.
- **AppSettings:** themeMode, localeCode?, defaultTransport, gridSubstreamDefault, keepAwake, showOverlayLabels, hapticsEnabled, autoCycleEnabled, autoCycleSeconds, schemaVersion (R2 adds alertsEnabled).
- **DiscoveryResult:** host, port, source (`onvif`/`sweep`), name?, model?, scopes, xaddrs.
- **PtzCommand:** pan, tilt, zoom (normalized -1..1), speed, kind (`continuous`/`stop`/`home`/`preset`).
- **ConnectionTestResult:** stage results (dns, tcp, auth, describe, first-frame), classified `AppError?`, suggestions list.
- **Entitlement:** `free` | `adFree`, source, verifiedAt.
- **RemoteFlags:** schemaVersion, killSwitches map (`discovery`, `ptz`, `ads`, `snapshots`, `helpContent`, `pip`; R2 adds `motionDetection`, R4 adds `recording`; unknown keys are ignored), minSupportedVersion, message?.
- **OnboardingState:** completedVersion, localNetworkRationaleSeen, attPromptShown.
- **PlayerState:** idle, connecting, buffering, playing, reconnecting, error(AppError), stopped.
- **R1 additions:** HelpArticle (id, title key, steps), HelpStep (id, text key, copyable values, optional target), TroubleshootNode (id, question key, edges), DiagnosticsReport (per-check results).
- **R2 additions:** HealthEvent (cameraId, kind `offline`/`online`, at), MotionEvent (cameraId, at, score, snapshotId?), SnapshotEntry (id, cameraId, at, path, bytes), ZoneMask (cameraId, grid, excluded cells), DetectionSettings (cameraId, enabled, sensitivity `low`/`medium`/`high`, maskId?, cooldownSeconds), alert preferences in AppSettings.
- **R3 additions:** Schedule (cameraId, weekly windows), ClipEntry (id, eventId, path, preSeconds, postSeconds, bytes).
- **R4 additions:** Recording (id, cameraId, startedAt, endedAt?), Segment (id, recordingId, startedAt, durationMs, path, bytes), RetentionBudget (mode `hours`/`gigabytes`, value).

### D2. Persistence

- SQLite (`sqflite` candidate) with `user_version` migrations: `m001_initial_schema` creates `cameras`, `stream_profiles`, `grid_layouts`. Settings in key-value (`shared_preferences`), each with `schemaVersion`. Credentials only in the vault (`flutter_secure_storage` candidate) keyed by camera id.
- Migration rules: run on open, transactional; downgrade = refuse to open, keep data, show "update the app" screen; corruption = quarantine DB file, start clean, show `persistence_warning_banner` with export-what-you-can guidance.
- Every storage call wrapped in try/catch with an in-memory fallback and a visible warning banner. No silent data loss.
- Later releases add migrations by release: `m002_events_snapshots` (R2), `m003_schedules_clips` (R3), `m004_recordings` (R4). Each follows the migration rules above.
- Files (snapshots, clips, segments) live in the app support directory, never shared storage, and are excluded from device backups (Android `data_extraction_rules.xml`, iOS backup-exclusion flag). "Delete all local data" removes cameras, settings, vault entries, events, snapshots, clips and recordings.

### D3. Player engine, reconnect, resource rules

- Engine behind `PlayerContract`. Candidates: `media_kit` (libmpv/FFmpeg), `flutter_vlc_player`, native ExoPlayer/AVFoundation bridges. **Selection criteria, all mandatory:** plays H.264 and H.265 RTSP over TCP and UDP on iOS and Android; MJPEG; low-latency options; digest and basic auth; works on the chosen minSdk (A1); and a license the app can ship (see D8). **Scored, not mandatory** (a failure defers the dependent feature, not the engine): frame access (R2), stream-to-file (R3, R4), picture-in-picture surface (R1). The decision and all findings are recorded in `docs/DECISIONS.md` after the spike.
- **Spike (P2B, checkpoint CP1):** one manual CI run per platform to prove the engine builds; the Android phone plays the spike streams (RTSP H.265 over TCP, and MJPEG); iOS proves compile and link, with playback proven at first TestFlight. The same spike records findings on: decoded-frame access (needed for R2 detection), saving an incoming stream to segment files without re-encoding (R3, R4), a video surface for Android picture-in-picture (R1), and cleartext/ATS behavior for the plain-HTTP MJPEG stream.
- Reconnect: exponential backoff 1s, 2s, 4s, 8s, 15s cap, jitter +-20%, reset after 30s of healthy playback; give up to a manual "Retry" state after 10 attempts; pause backoff while app is backgrounded.
- Concurrency: `GridPlanner` decides which tiles decode. Default budgets: phone 4 concurrent decoders, tablet 8. Non-decoding tiles show a poster (last frame, dimmed, with age label) refreshed by snapshot polling every 5s if the camera supports HTTP snapshot, else static.
- Grid uses substream; fullscreen switches to mainstream after a 400ms settle; switching back on exit.
- Lifecycle: on app pause dispose all players (the one exemption is the session kept alive for Android picture-in-picture, D15); on resume rebuild only visible tiles staggered 150ms apart. Dispose is deterministic; a `PlayerPool` owns all sessions.
- Thermal/memory pressure: on a platform low-memory signal, drop to poster mode for non-focused tiles.
- Detection interplay (R2): motion detection samples only tiles that are already decoding and never requests an extra decoder. `detection_scheduler.dart` follows `GridPlanner`: when a tile drops to poster mode it stops being monitored for motion, and the Detection settings screen says so.

### D4. Discovery

- **Android:** WS-Discovery multicast (239.255.255.250:3702) with a `WifiManager.MulticastLock` acquired through a small Kotlin method channel; plus subnet sweep fallback.
- **iOS:** multicast requires Apple's Multicast Networking entitlement, which the owner requests from Apple now. The subnet sweep is always present on iOS (TCP connect to 80, 554, 8000, 8080, 8554 across the /24, concurrency 48, timeout 400ms, then ONVIF probe on hits). Compile-time flag `--dart-define=IOS_DISCOVERY_MODE=subnet_sweep_only` is the default and the fallback while the entitlement is denied or pending; only when Apple grants it is the build made with `IOS_DISCOVERY_MODE=ws_discovery`, which adds WS-Discovery next to the sweep and includes `Runner.entitlements` (P7B-09). The flag is set in `codemagic.yaml`.
- Discovery results are unauthenticated until the user supplies credentials; the ONVIF client then fetches device info, profiles, and stream URIs.
- Kill switch `discovery` disables the feature remotely.

### D5. Error taxonomy (every class has a treatment)

| Class | Example | Retriable | Treatment |
|---|---|---|---|
| `networkUnreachable` | host down, wrong Wi-Fi, timeout | yes (backoff) | tile: "Can't reach camera" + Retry; edit screen: suggests checking network |
| `authFailed` | 401/403 | no | tile: "Check username or password" + Edit |
| `pathNotFound` | RTSP 404, wrong path | no | suggest brand profile paths; open brand picker |
| `unsupportedMedia` | codec unsupported | no | explain; suggest substream/MJPEG |
| `localNetworkDenied` | iOS permission off | no | rationale screen + open Settings |
| `streamDropped` | Wi-Fi blip | yes (auto) | tile "Reconnecting"; no dialog |
| `resourcePressure` | too many streams | degrade | poster mode; one-time toast |
| `storageFailure` | DB/vault error | depends | persistent warning banner |
| `flagDisabled` | kill switch on | no | inline notice with server message |
| `purchaseFailed` | billing error | retry manual | inline message on upgrade screen; restore always available |
| `fatal` | unhandled | no | full-screen fallback with Retry and Report (mail) |
| `detectionUnavailable` | engine cannot supply frames, or kill switch (R2) | no | Detection settings explains why; no alert noise |
| `recordingFailed` | segment write fails (R4) | depends | recording stops cleanly; inline notice on the recording indicator |
| `storageFull` | free space below the safety floor (R4) | degrade | evict oldest segments, then pause recording with a visible notice |

`ErrorMapper` converts platform exceptions and player events to `AppError` with class, user message key (localized), diagnostic detail (never shown by default, attachable to feedback mail), and retriable flag. Global handlers (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`) route into the same path.

Presentation rule: a status is never color alone and never bare text. Tiles show a status pill (icon + label). Below 120dp tile width the pill is icon-only with a semantic label, and a tap opens a sheet with the full message and Retry/Edit pills.

### D6. Ads, consent, purchase

- One adaptive banner on the home screen only. No interstitials, no rewarded.
- Order at first launch: onboarding -> local-network rationale -> (iOS) ATT prompt -> UMP consent where required -> ad init. Ads never load before consent resolution.
- `AdContract` failure pattern: any init/load failure collapses the slot to zero height silently and logs locally; the app never crashes or blocks on it. The slot follows the embed spec in C8.4 (no empty placeholder, collapses under the keyboard, on ad-free purchase, on kill switch, and on every non-Live screen).
- Purchase: one-time non-consumable ad-free unlock. Upgrade screen is never a modal gate; reachable from Settings only. Restore always visible. Entitlement lives in `subscription_provider`; ad slot reads it. Kill switch `ads` hides banners remotely.

### D7. Remote flags

`website/config/flags.json` fetched on launch (timeout 4s), cached, stale-while-revalidate, and re-checked every 6 hours and on resume while the app is open (so a kill switch can reach a running session). Failure = use cache = use defaults (everything enabled). It contains no user data and no identifiers. The request is disclosed in the privacy policy.

Kill switches: `discovery`, `ptz`, `ads`, `snapshots`, `helpContent`, `pip` (R1); `motionDetection` (R2); `recording` (R4). Behavior on an active recording (H12): the switch may interrupt it. The current segment is closed at once so it stays playable, no data is deleted, new recording does not start, and a notice shows the server message. A switched-off detection or recording feature shows `flagDisabled` inline.

### D8. Dependencies and licenses

Policy: allow MIT, BSD, Apache-2.0, ISC, MPL-2.0 (file-level). Disallow GPL and AGPL. LGPL only for dynamically linked player libraries with documented compliance in `docs/DECISIONS.md` and the in-app licenses screen. `tool/license_audit.sh` (P8) lists every transitive dependency and license from `pubspec.lock` and fails on a disallowed class.

Candidate packages (verify each): `media_kit` + platform libs, `sqflite`, `shared_preferences`, `flutter_secure_storage`, `path_provider`, `share_plus`, `file_picker`, `url_launcher`, `package_info_plus`, `connectivity_plus`, `wakelock_plus`, `google_mobile_ads`, `in_app_purchase`, `in_app_review`, `xml`, `intl`, `flutter_localizations`, `phosphor_flutter`, one Tabler package (verify; both direct dependencies in `pubspec.yaml`, never transitive); R2 adds `flutter_local_notifications` (verify); no frame-diff or recording package (hand-written on the engine); dev: `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`, `image` (brand asset tool).

**Highest license risk: the player engine's native libraries.** Some prebuilt mpv/FFmpeg distributions are GPL-licensed or LGPL with obligations. The agent must verify the exact library build shipped on iOS and Android before adopting the engine, and reject any GPL build.

### D9. Performance targets

| Metric | Target |
|---|---|
| Launch to interactive | < 2s |
| UI frame rate | 60fps minimum (120 on ProMotion) while 4 streams play |
| First frame, single LAN stream | < 3s |
| Grid switch 4 to 9 | < 500ms visible transition, no dropped frames |
| DB reads | < 50ms |
| Discovery (sweep of a /24) | < 8s to first result, < 20s complete |
| Memory | ceiling recorded after first device test; app must not be killed with 4 streams in a 30-minute run on a 3GB device |
| Thermal | 4-stream, 30-minute run causes no OS thermal warning on a mid-range phone |
| Help content (R1) | article opens in < 300ms from cold; Help adds no startup cost |
| Detection CPU (R2) | each monitored tile adds at most 5% of one core at 2 fps on a mid-range phone; per-device ceiling recorded after first device test |
| Detection latency (R2) | motion to in-app alert < 3s |
| Storage write (R3, R4) | sustained write at 1.5x the camera bitrate per recording camera without dropped segments |
| Battery and thermal under recording (R4) | drain with 4 cameras recorded after first device test; on thermal pressure, monitored and recorded cameras step down before the OS warns |

### D10. Help, remote-access setup and diagnostics (R1; content only, no backend, no new permissions)

**Screens (5):** Help hub (four cards: Same Wi-Fi, Away from home, Troubleshoot, Diagnostics) · Help article · Remote-access wizard · Troubleshooter · Network diagnostics. Entry points: Settings > Help, Camera edit (when the connection test fails: "Open troubleshooter" pill), Onboarding last page.

**Articles (full set, 10):** LAN setup · VPN (WireGuard, Tailscale, OpenVPN) · DDNS + port forward · Static IP + port forward · Third-party relay (names as text only, no endorsement, no links) · CGNAT · Port selection · Port security · Codecs and bandwidth · Brand-specific router notes (brand names as text only).

**Content model.** Language-neutral `assets/help/help_structure.json` (article ids, step ids, copyable values, decision-tree edges, in-app targets) plus one `assets/help/strings/help_<locale>.json` per language (all visible text). A step may carry copyable values (rendered in the Mono role, left-to-right), a callout, and an in-app target button. **Targets are in-app destinations or the phone's own Settings only. Help contains no outbound web links.** `help_parity_test` fails if any locale lacks any id.

**Remote-access wizard.** One path at a time (VPN, DDNS + port forward, static IP + port forward, third-party relay). Each step has a "Test this step" button that runs the connection tester inline and shows the plain-language result.

**Troubleshooter.** A decision tree stored in `help_structure.json`, evaluated by `troubleshooter_engine.dart` (pure Dart). Example: works on Wi-Fi but not on cellular, then ISP CGNAT? then try VPN.

**Network diagnostics (user-triggered, each check on its own button):** local IP and gateway (read from the phone), LAN reachability (connection tester), public hostname resolution, public host:port reachability from the phone (run on cellular), and the **public-IP lookup** (H1: kept, with disclosure). The lookup is a single tap-to-run request to the one service recorded in `docs/DECISIONS.md`. It never runs automatically, sends no camera or user data, and is disclosed in the privacy policy, Play Data safety and the Apple privacy label alongside the flags fetch. Kill switch `helpContent` hides the wizard and diagnostics.

### D11. Monitoring (R2, Tier 1; foreground only)

- **Health monitor.** Reachability probe per camera every 60s while the app is open (reuses the connection tester's TCP and describe stages). Offline after 2 consecutive failures; recovered after 1 success. Writes a `HealthEvent` on each transition. Runs only in the foreground.
- **Motion detection.** Runs on the decoded substream of tiles that are already decoding (never adds a decoder). Frame source: downscaled luma samples at 2 fps from the player engine (`FrameSampleContract`). Hand-written differencing (no package): compare against a rolling background on a coarse grid, apply the zone mask, trigger when the changed-area fraction exceeds the camera's sensitivity threshold, then a per-camera cooldown (default 30s). Sensitivity: Low / Medium / High per camera. If the engine cannot expose frames (P2B finding), cameras that support HTTP snapshots fall back to snapshot polling at 1 frame per 2s; otherwise motion detection is deferred and logged.
- **Coverage, stated plainly.** Only cameras currently on screen and decoding are monitored for motion (phone budget 4, tablet 8). The health monitor covers all cameras. The app says so on the Detection settings screen and in onboarding.
- **Zone masks.** Per-camera mask drawn on a coarse grid (`zone_mask_editor_screen`) to exclude trees, roads, sky.
- **Alerts.** In-app banner (`in_app_alert_banner`) with optional sound/haptic, always. A best-effort local notification is added only if the user turns alerts on, which triggers the OS permission prompt after an in-app rationale. Because detection stops when the app leaves the screen, no copy ever promises alerts while the app is closed. Alert text: the Android prompt and iOS prompt both fire only from the "Turn on alerts" button.
- **Motion-triggered snapshot, event log, snapshot archive.** A motion event captures one snapshot via `frame_capture_service`, writes a `MotionEvent` and a `SnapshotEntry`. Archive lives in the app sandbox (no storage permission), capped by count and size (default 500 snapshots or 500 MB, user-adjustable), oldest evicted first, excluded from device backups.
- **Activity tab** (timeline + search/filter): events and snapshots merged by time; filter by camera, event type, date range.
- **Honesty rule.** Listings, onboarding and Help use the wording in `docs/MONITORING_WORDING.md`: "while Roehens is open".

### D12. Clips (R3, Tier 2)

- **Schedules.** Per-camera weekly windows in which detection is active (outside a window, detection is off).
- **Ring buffer: on disk** (decision H6). A rolling set of short segment files (about 2s each) per monitored camera, deleted continuously. Chosen over RAM because RAM is the scarce resource on a 3GB device and a crash would lose a RAM buffer. It reuses the R4 segment writer.
- **Clip.** On a motion event, pre-event (default 5s) and post-event (default 10s) segments are joined into one clip without re-encoding. Clips attach to the event and play in a simple clip viewer on the timeline. Export through the share sheet.
- **Engine gate.** R3 requires the engine to save an incoming stream to segment files without re-encoding (proved in P2B). If it cannot, R3 and R4 stay deferred and Part K records why.

### D13. Local recording (R4, Tier 3; foreground only)

- Recording is **segmented**: one file is never the only record. Default segment 5 minutes; segments are the unit of retention. Segments are written by saving the camera's already-encoded stream (no re-encode), not by Android's MediaRecorder, which records the phone's own camera and microphone.
- **Foreground only on both platforms** (H7). Recording stops when the app leaves the screen; no foreground service, no background mode, no Play Console declaration.
- **Retention is user-chosen only** (H8). Nothing records until the user sets a retention budget in hours or GB on the storage budget screen. A fixed safety floor always applies: when free device space falls below 1 GB, the oldest segments are deleted first, then recording pauses with a visible notice.
- **Budget screen with live math.** The user sees "X hours of history" or "Y GB", not minutes, computed from each camera's measured bitrate. Reference table: 8 Mbps = 3.6 GB/hour; 4 Mbps = 1.8; 2 Mbps = 0.9; 1 Mbps = 0.45; 0.5 Mbps = 0.23.
- **Playback** scrubs across segments (`recording_playback_screen`). **Storage manager** shows per-camera usage, free space, and a delete control (`storage_manager_screen`).
- Files live in the app support directory, excluded from backups. "Delete all local data" removes recordings, clips, snapshots and events (D2).
- Kill switch `recording`: see D7.

### D14. Localization (R1: 24 languages)

| # | Language | Locale tag (ARB suffix) | RTL |
|---|---|---|---|
| 1 | English (template) | `en` | no |
| 2 | Mandarin Chinese, Simplified | `zh_Hans` | no |
| 3 | Spanish, Latin America | `es_419` | no |
| 4 | Arabic | `ar` | **yes** |
| 5 | French | `fr` | no |
| 6 | Portuguese, Brazil | `pt_BR` | no |
| 7 | Russian | `ru` | no |
| 8 | Hindi | `hi` | no |
| 9 | Bengali | `bn` | no |
| 10 | Japanese | `ja` | no |
| 11 | German | `de` | no |
| 12 | Urdu | `ur` | **yes** |
| 13 | Indonesian | `id` | no |
| 14 | Vietnamese | `vi` | no |
| 15 | Turkish | `tr` | no |
| 16 | Persian | `fa` | **yes** |
| 17 | Italian | `it` | no |
| 18 | Korean | `ko` | no |
| 19 | Thai | `th` | no |
| 20 | Polish | `pl` | no |
| 21 | Ukrainian | `uk` | no |
| 22 | Dutch | `nl` | no |
| 23 | Hebrew | `he` | **yes** |
| 24 | Filipino | `fil` | no |

- **Source of translations:** machine-generated by the agent (H9). Technical terms (RTSP, ONVIF, PTZ, HEVC) stay in Latin script. Native-speaker review is recommended before store listing but is not a build gate. The privacy policy and Terms are English-authoritative, with machine-translated convenience copies marked as such.
- **Mechanics.** ARB files `lib/l10n/app_<tag>.arb`, English is the template. `l10n_pending.txt` lists keys that exist in `app_en.arb` but are not yet translated. `test/l10n/arb_parity_test.dart` requires every non-English file to have every key of `app_en.arb` except keys listed in `l10n_pending.txt`, requires placeholders to match, and the guard fails any end-gate batch (`sh tool/guard.sh --release`) while `l10n_pending.txt` is non-empty. `tool/arb_merge.dart` merges a small additions file into an ARB and clears the key from the pending list, so later releases translate by emitting small additions files, not whole ARBs.
- **When strings are translated.** R1: all 24 languages are complete before R1's end gate. R2-R4: new English strings are added in the feature batches and listed in `l10n_pending.txt`; the release's final batch (`T1L`, `T2L`, `T3L`) translates all of them.
- **Numbers and dates** use `intl`. Technical values (IP, port, resolution, bitrate) always use Western digits and left-to-right order. UI numbers follow the locale.
- **Text expansion.** Layouts are checked with German, Russian, Filipino and Thai strings at 130% and 310% text scale; no clipped buttons.
- **Fonts.** System fonts only for all non-Latin scripts (C1.5). Urdu renders in the platform's Arabic-script face (typically Naskh, not Nastaliq): accepted.
- **Store listings and iOS permission strings** are localized separately (P7E-P7H): each locale needs a listing and an `InfoPlist.strings`. Per-app language on Android 13+ uses `locales_config.xml`.

### D15. Auto-cycle and picture-in-picture (R1)

- **Auto-cycle.** `auto_cycle_provider` (ValueNotifier) runs a local timer. Interval choices 5, 10, 15, 30, 60s. In the grid it advances pages; in fullscreen it advances cameras. A Settings toggle sets the default; `GridLayout.autoCycleSeconds` overrides it per layout. It pauses on any touch for one interval and stops when the app leaves the screen. Reduce Motion: switches without a fade.
- **Picture-in-picture (Android only).** `PipContract` (Android implementation enters PiP through a Kotlin method on `MainActivity`, 16:9). Entered from a button in Fullscreen. Requires the engine to expose a video surface (P2B finding). On entering PiP the one active session stays alive and all others are disposed; closing PiP disposes it. This is the single exemption to the "on pause dispose all players" rule. Kill switch `pip`. On iOS the contract is a no-op and the button is hidden.

---

## PART E: SCREENS

Skeleton loaders do not exist (C1.12). Reads are under 50ms, so a screen shows its chrome and nothing in the content slot until data arrives.

| Screen | Purpose and content | States handled | Release |
|---|---|---|---|
| Main shell | Bottom bar: Live, Cameras, Settings (R2 adds Activity). Hosts the banner ad slot above the bar on Live only (C8.4). Bar collapses under the keyboard | offline, kill-switch notice | R1 |
| Live (home) | Grid of tiles; layout picker; page dots when paged; add-camera entry; auto-cycle control | empty (first run CTA), partial failure (tiles show their own status pill), permission denied | R1 |
| Fullscreen | Immersive video, digital zoom, PTZ pad, mute, snapshot, quality toggle, camera switcher swipe, picture-in-picture button (Android) | connecting, reconnecting, error with retry pill, controls hidden/shown | R1 |
| Cameras | Sortable list, search, swipe/long-press to edit or delete with undo pill, per-camera status | empty, no results, persistence warning | R1 |
| Layout sheet | Choose 1/2/4/6/9/12/16, reorder, per-layout auto-cycle interval | | R1 |
| Camera edit | Name, protocol, host, port, credentials (show/hide), paths, transport, ONVIF toggle, brand picker, connection test, "Open troubleshooter" pill on failure | validation errors inline, test in progress/success/failure with diagnosis | R1 |
| Discovery | Scan progress, result rows, tap to prefill edit | scanning, none found (with tips), permission denied, kill switch | R1 |
| Brand picker | Search brands (scrolls away), alphabetical list with sticky letter headers, choose model hint, prefill paths | empty search | R1 |
| Import/Export | Export list (stripped), import from file with preview and conflict handling (skip/replace/duplicate) | invalid file, partial import | R1 |
| Settings | Appearance, language, layout defaults, auto-cycle, transport, keep awake, haptics, help, upgrade/restore, import/export, feedback, rate, privacy, terms, licenses, delete all local data, about | | R1 |
| Appearance | System/Light/Dark preview cards | | R1 |
| Language | 24 languages shown by native name, searchable; follows system by default | | R1 |
| Upgrade | Ad-free benefits, price from store, buy, restore | loading, unavailable, failed, already owned | R1 |
| Onboarding | 3 pages: what it does; LAN-only and foreground-only truth; get started | resumable | R1 |
| Local-network rationale | Explains why access is requested before the OS prompt; denied-forever recovery with Settings deep link | | R1 |
| Help hub | Four cards: Same Wi-Fi, Away from home, Troubleshoot, Diagnostics | kill-switch (`helpContent`) | R1 |
| Help article | Title, steps, callouts, copyable values (Mono), in-app target buttons | article missing for locale (falls back to English) | R1 |
| Remote-access wizard | One path at a time; each step has "Test this step" | test running/passed/failed | R1 |
| Troubleshooter | Decision tree with back and restart | | R1 |
| Network diagnostics | Local IP, gateway, LAN reachability, hostname resolution, host:port reachability, public-IP lookup (each on its own button) | running, failed, offline, kill switch | R1 |
| About / Licenses | Version, build, open-source licenses via Flutter `LicenseRegistry` rendered in own UI | | R1 |
| Fatal error | Full-screen fallback: Retry, Report | | R1 |
| Activity | Segmented: Timeline \| Snapshots. Search and filter (camera, type, date range). Event rows, snapshot thumbnails, snapshot viewer | empty, no results, storage warning | R2 |
| Detection settings | Per-camera detection toggle, sensitivity, zone-mask entry; alerts toggle with in-app rationale; coverage note | notification permission denied, kill switch | R2 |
| Zone mask editor | Draw and clear excluded zones on a camera frame | no frame available | R2 |
| Schedules | Weekly windows per camera when detection is active | | R3 |
| Recording playback | Pick camera and day, scrub across segments | no recordings, gap in timeline, segment missing | R4 |
| Storage manager | Budget screen with live math (hours or GB), per-camera usage, free space, delete | storage low, recording paused | R4 |

Navigation: cold start goes to onboarding if `completedVersion` < current major, else Live. Back from Fullscreen returns to the same grid position. No incoming deep links in any release; Help buttons only open in-app destinations or the phone's own Settings.

---

## PART F: REPOSITORY LAYOUT

```
Roehens/
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                 shell, bootstrap, routes, lifecycle
│   │   ├── core/
│   │   │   ├── constants/  contracts/  errors/  models/  providers/  services/
│   │   │   └── services/detection/            (R2)
│   │   ├── platform/
│   │   │   ├── storage/  player/  network/  store/  files/  system/
│   │   │   └── recording/                     (R3-R4)
│   │   ├── ui/
│   │   │   ├── tokens/  icons/  components/
│   │   ├── widgets/             feature widgets
│   │   │   └── help/
│   │   ├── screens/
│   │   │   └── help/
│   │   ├── spike/               temporary entrypoints (removed in P8)
│   │   ├── utils/
│   │   └── l10n/                ARB files (24)
│   ├── assets/  (profiles/, branding/, help/)
│   ├── android/  ios/  test/
│   ├── pubspec.yaml  analysis_options.yaml  l10n.yaml
│   ├── flutter_launcher_icons.yaml  flutter_native_splash.yaml
├── tool/                        guard.sh, make_brand_assets.dart, license_audit.sh, arb_merge.dart
├── docs/                        IDENTITY, DECISIONS, ICON_MAP, VISUAL_QA, signing, runbooks
├── website/                     static marketing site (no Flutter Web, no remote fonts)
├── store_submission/            play/, ios/, localized/, shared docs
├── l10n_pending.txt
├── .github/workflows/
├── codemagic.yaml
└── README.md
```

Layer rules: `core/` has no `dart:io`, no plugin imports (pure-Dart packages like `xml` and `intl` are allowed). `platform/` implements contracts. `ui/` imports only `tokens` and Flutter. `widgets/` and `screens/` never import `platform/` directly; they receive services through providers wired in `app_providers.dart`.

`tool/guard.sh` fails a batch on: `Icons.` / `CupertinoIcons`; forbidden stock components (C1.2); raw `Color(0x` outside `lib/ui/tokens/`; `Curves.` outside `lib/ui/tokens/motion_tokens.dart`; `BoxDecoration(` or `DecoratedBox(` inside `lib/screens/`; numeric literals in `EdgeInsets`, `SizedBox` and `BorderRadius` inside `lib/screens` and `lib/widgets` (heuristic); `EdgeInsets.only(left`/`right`, `Alignment.centerLeft`/`centerRight` and `TextDirection.rtl` anywhere in `lib/`, and `TextDirection.ltr` outside the IP/URL/Mono widgets (RTL safety); `setState(` anywhere in `lib/`; `TODO`/`FIXME`/`UnimplementedError`; imports of store SDKs outside `lib/platform/store/`; `dart:io` or plugin imports inside `lib/core/` (except allowed pure-Dart packages); hardcoded user-facing string literals in `lib/screens` and `lib/widgets` (heuristic); `uses-material-design: true`; any import of an icon package outside `lib/ui/icons/app_icons.dart`; `<filter` in any `.svg`, `.html` or `.css` under `app/assets` and `website/`; any credential-like string, or an RTSP URL with a user name and password embedded in it, in tracked files; and, with `--release`, a non-empty `l10n_pending.txt`.

---

## PART G: ANDROID AND iOS PLATFORM CONFIGURATION

### G1. Android

- `applicationId` = `namespace` = `com.zdmgold.roehens`; minSdk = the single value recorded in `docs/DECISIONS.md` after the P2B spike (A1); targetSdk = current Play requirement (verify); Java 17; R8 minify on release with keep rules for the player engine; ABI: AAB (Play splits) and APK (universal, for sideload testing).
- Permissions (each traces to A3). R1: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (discovery only), AD_ID (merged from the ads SDK, declared in Data safety). `WAKE_LOCK` comes from the wake-lock plugin. R2 adds `POST_NOTIFICATIONS`, requested at runtime only when the user turns alerts on. **In no release:** storage, camera, mic, or foreground-service permissions (foreground-only decision, H7). No Play Console Foreground Service declaration is needed.
- `allowBackup="false"` plus `data_extraction_rules.xml` so cached camera data never enters device backups.
- Correction to earlier guidance: Android's cleartext policy governs platform HTTP stacks, not the raw sockets used by RTSP, `dart:io`, or native FFmpeg/mpv. A `network_security_config.xml` is required only if the chosen engine's HTTP path uses the platform stack; the spike decides. Android network security config cannot express private IP ranges anyway, so if needed it lists cleartext for local domains and the user's IPs cannot be enumerated; in that case enable `usesCleartextTraffic="true"` and document it. Data safety must state cleartext local traffic.
- Signing: keystore stored as base64 GitHub secret; workflow decodes it, writes `key.properties`, builds, and deletes it. Play App Signing enrolled; the keystore is the upload key.
- `MulticastLockChannel.kt`: acquire/release `WifiManager.MulticastLock` on demand.

### G2. iOS

- Deployment target = highest of the toolchain minimum and the player engine minimum; Bundle ID = A1; Swift AppDelegate; no background modes; Info.plist strings specific and localized per language (`InfoPlist.strings`, P7E-P7H).
- `NSLocalNetworkUsageDescription`: "to find cameras on your home network and stream their video".
- `NSBonjourServices`: only the service types actually browsed (verify; ONVIF discovery by sweep needs none).
- ATS: `NSAllowsLocalNetworking = true` only; never `NSAllowsArbitraryLoads`. Needed only if the engine uses `URLSession`/AVFoundation for HTTP; verify in the spike.
- `NSUserTrackingUsageDescription` (ATT), prompted after onboarding, not at first launch.
- R2 notifications: iOS has no Info.plist key for notification permission. An in-app rationale appears first, then `requestAuthorization` runs only from the "Turn on alerts" button. `AppDelegate.swift` sets a foreground presentation delegate. No background modes in any release.
- `PrivacyInfo.xcprivacy`: declares required-reason APIs actually used (UserDefaults, file timestamp, disk space, system boot time as flagged by dependencies) and tracking domains for the ad SDK; verify against every dependency's manifest.
- Multicast entitlement file `Runner.entitlements` is added only if Apple grants it (conditional file, P7B-09); until then the build uses `IOS_DISCOVERY_MODE=subnet_sweep_only` (D4).
- Signing via Codemagic automatic signing with the App Store Connect API key. Bundle ID, team, and deployment target are set with documented commands in `docs/IOS_PROJECT_SETTINGS.md`, never by hand-editing `project.pbxproj`.

### G3. CI/CD (manual only)

- Manual only. GitHub Actions uses `workflow_dispatch` only. Codemagic has no `workflow_dispatch`: its yaml has no `triggering:` block at all, so builds start only from the Codemagic UI or API. No `push:` trigger, no tag trigger, ever.
- Android: one job, AAB + APK, `--obfuscate --split-debug-info=symbols`, symbols uploaded as an artifact.
- iOS: Codemagic builds the IPA and sends to TestFlight; `submit_to_app_store: false` until the intentional release.
- CI runs happen only at the checkpoints in H5 (CP1 after P2B, A1 after P4E, CP2 after P6A, CP3 after P7B, CP4 after P8, and each later release's end gate). All are manual.

### G4. Store rejection map

| Policy | Mitigation |
|---|---|
| Apple local network | Specific string, rationale screen first, recovery path when denied |
| Apple 2.1 (reviewers must be able to test) | `store_submission/ios/REVIEW_NOTES.md` gives a hosted test stream and steps; app is fully usable with it. The stream is deferred and is a release blocker (Part B) |
| Apple 5.1.1 / 5.1.2 | Accurate privacy label (ad identifiers, diagnostics if enabled); live policy URL |
| Apple 3.1.1 | StoreKit only; restore visible; product exists before submission |
| ATT | Description string; prompt after onboarding |
| Apple 2.3.7 / marketing | Listing describes a viewer, never claims to secure premises or prevent crime |
| Play Data safety | Declares ad ID, no data shared beyond ads, flags fetch disclosed; camera credentials never leave the device |
| Play Ads | Banner only; ads disclosed |
| Play Payments | Play Billing only |
| Play foreground services / restricted permissions | none used in any release (foreground-only, H7) |
| Content rights | Brand names text-only, no logos; icons are permissively licensed (MIT) and brand artwork is owner-supplied |
| Data subject rights | No account, no server data; in-app "delete all local data" action in Settings (also wipes events, snapshots, clips and recordings once they exist) |
| Apple 2.5.4 (background services; formerly numbered 2.16) | No background modes, no silent audio, no background tasks. Detection, alerts and recording run only while the app is open; listings and onboarding say so |
| Apple 5.1.1 / notifications (R2) | In-app rationale before the system prompt; notifications are local only; no promise of alerts while the app is closed |
| Play Data safety, Help (R1) | The public-IP lookup is user-triggered; disclose that the device IP address is sent to the lookup service |
| Listing honesty (R2-R4) | Wording per `docs/MONITORING_WORDING.md` and `docs/RECORDING_WORDING.md`: "while Roehens is open". Never claims to secure premises, prevent crime, or alert when closed |
| Localized listings (R1) | All 24 listings carry the same honesty wording; locale acceptance is verified per store before submission |

---

## PART H: THE OPERATIONAL LOOP

### H1. One-time environment (Termux + proot Ubuntu)

Documented once before P0 and never repeated per batch:
1. Termux packages: `git`, `openssh`, `proot-distro`.
2. `proot-distro install ubuntu`; log in; install `curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk`.
3. Install Flutter (pinned version) into the Ubuntu home. **Verify Flutter's Linux arm64 SDK is currently available.** If it is not, this gate cannot run on-device and the loop must switch to a cloud dev environment before P0; do not start until `flutter doctor` and `flutter analyze` work. Owner status: to be reverified (Part B).
4. Git over HTTPS: `git config --global user.name/email` and `git config --global credential.helper store`. Create the fine-grained token (Part B) and enter it as the password at the first push. The token lives only in the phone's credential store.
5. `flutter --disable-analytics`, `flutter precache` (Android only; iOS cannot build in proot).

### H2. Preconditions (human, on web)
Empty public repo, no README/license/ignore, at `https://github.com/helpfavourv1/Roehens.git` (supplied). The token (Part B) exists. The agent does not start P0 until the owner confirms the repo is empty and the Flutter gate has passed.

### H3. Per-batch loop (agent emits exactly these groups, then waits)

```
# 1. place files (one block per file, in batch order)
# 2. resolve + gates
cd ~/Roehens/app && flutter pub get && flutter analyze
cd ~/Roehens && sh tool/guard.sh
cd ~/Roehens/app && flutter test        # from the first batch that has tests
# 3. commit
cd ~/Roehens && git add . && git commit -m "<batch-id>: <purpose>"
# 4. push
git push origin main
```

Hard rules: zero analyzer errors, guard passes, tests pass, before commit. Failure = agent gets output verbatim and re-issues only the affected files. Push rejected = `git pull --rebase` then push. A batch is smaller than 15 files unless it is mechanical (translation files). The last batch of each release also runs `sh tool/guard.sh --release`.

First batch also runs: `git init && git branch -M main && git remote add origin <url>` and, before any `pub get`, commits `.gitignore`. It also runs `flutter create --org com.zdmgold --project-name roehens --platforms=ios,android app` and commits the scaffold as part of P0.

> **Note added at handoff (not part of the original text).** The build moved from this phone-and-Termux loop to an agent sandbox that pushes to GitHub with the owner's token and reads CI results through the API. The gates are the same; see `HANDOFF.md` section 4 and `DECISIONS.md` (P0 and P4E sections).

### H4. Batch plan, Release R1 (44 batches, 395 files, dependency order)

Each ID is `<batch>-<nn>`; batch commit message is `<batch>: <purpose>`.

**P0: repo scaffold and guardrails (12)**
- P0-01 `.gitignore`
- P0-02 `README.md`
- P0-03 `app/pubspec.yaml` (pinned SDK, only dependencies needed so far, `uses-material-design: false`, asset declarations)
- P0-04 `app/analysis_options.yaml` (flutter_lints + strict-casts/inference/raw-types)
- P0-05 `app/l10n.yaml`
- P0-06 `tool/guard.sh` (all rules in Part F; `--release` flag)
- P0-07 `docs/IDENTITY.md`
- P0-08 `docs/DECISIONS.md` (version pins, license log, engine decision placeholder-free skeleton)
- P0-09 `docs/ICON_MAP.md` (semantic name to glyph and source table; filled in P1B)
- P0-10 `app/lib/main.dart` (compile-clean stub, replaced in P6A)
- P0-11 `docs/VISUAL_QA.md` (Gate 2 log: reference apps, cheapest device, per-screen checklist, open items)
- P0-12 `l10n_pending.txt` (empty; keys awaiting translation)

**P1A: tokens and theme (13)**
- P1A-01 `lib/ui/tokens/color_tokens.dart` · -02 `typography_tokens.dart` · -03 `spacing_tokens.dart` · -04 `radius_tokens.dart` · -05 `motion_tokens.dart` · -06 `elevation_tokens.dart` · -07 `size_tokens.dart`
- P1A-08 `lib/ui/tokens/app_tokens.dart` (ThemeExtension exposing all tokens)
- P1A-09 `lib/ui/tokens/app_theme.dart` (light/dark builders; NoSplash; ClampingScrollPhysics; no default Material visuals)
- P1A-10 `lib/utils/context_extensions.dart` · -11 `date_formatter.dart` · -12 `number_formatter.dart` (bitrate, resolution, age labels) · -13 `async_utils.dart` (debounce, timeout helpers)

**P1B: icon wrapper (4)**
- P1B-01 `lib/ui/icons/app_icons.dart` (semantic `AppIconName` enum mapped to Phosphor/Tabler glyphs; the only icon-package import in the app)
- P1B-02 `lib/ui/icons/app_icon.dart` (widget: size tokens, color tokens, weight, semantics)
- P1B-03 `test/ui/icons/icon_registry_test.dart`
- P1B-04 `test/ui/icons/icon_font_bundle_test.dart` (fonts for every weight in use are in the font manifest)
- Also updates `pubspec.yaml` (adds the icon packages) and fills `docs/ICON_MAP.md` with the exact glyph identifiers.

**P1C: errors and constants (8)**
- P1C-01 `lib/core/errors/error_class.dart` · -02 `app_error.dart` · -03 `result.dart` · -04 `error_mapper.dart` · -05 `global_error_handler.dart`
- P1C-06 `lib/core/constants/app_constants.dart` · -07 `storage_keys.dart` · -08 `limits.dart`

**P1D: domain models (14)**
- P1D-01 `stream_protocol.dart` · -02 `stream_profile.dart` · -03 `camera.dart` · -04 `camera_brand_profile.dart` · -05 `grid_layout.dart` · -06 `app_settings.dart` · -07 `discovery_result.dart` · -08 `ptz_command.dart` · -09 `connection_test_result.dart` · -10 `entitlement.dart` · -11 `remote_flags.dart` · -12 `onboarding_state.dart` · -13 `camera_export_bundle.dart` · -14 `player_state.dart` (all under `lib/core/models/`)

**P1E: model tests and first contracts (11)**
- P1E-01 `test/core/models/camera_test.dart` · -02 `app_settings_test.dart` · -03 `grid_layout_test.dart` · -04 `test/core/errors/error_mapper_test.dart`
- P1E-05 `lib/core/contracts/logger_contract.dart` · -06 `clock_contract.dart` · -07 `storage_contract.dart` · -08 `secure_vault_contract.dart` · -09 `player_contract.dart` · -10 `snapshot_contract.dart` · -11 `discovery_contract.dart`

**P1F: remaining contracts (9)**
- P1F-01 `ptz_contract.dart` · -02 `ad_contract.dart` · -03 `consent_contract.dart` · -04 `purchase_contract.dart` · -05 `review_contract.dart` · -06 `flags_contract.dart` · -07 `file_transfer_contract.dart` · -08 `permission_contract.dart` · -09 `pip_contract.dart` (Android picture-in-picture; iOS no-op)

**P2A: storage, vault, repository (11)**
- P2A-01 `lib/platform/storage/migrations/migration.dart` · -02 `migration_registry.dart` · -03 `m001_initial_schema.dart`
- P2A-04 `lib/platform/storage/database_service.dart` · -05 `key_value_store.dart` · -06 `secure_vault_service.dart`
- P2A-07 `lib/platform/system/logger_service.dart` (local ring buffer, no upload)
- P2A-08 `lib/core/services/camera_repository.dart`
- P2A-09 `test/support/fakes.dart` · -10 `test/core/services/camera_repository_test.dart` · -11 `test/platform/storage/migration_registry_test.dart`

**P2B: player engine, pool, planning, spike (12)**
- P2B-01 `lib/core/services/reconnect_policy.dart` · -02 `grid_planner.dart`
- P2B-03 `lib/platform/player/player_session.dart` · -04 `media_player_service.dart` · -05 `player_pool.dart` · -06 `frame_capture_service.dart`
- P2B-07 `test/core/services/reconnect_policy_test.dart` · -08 `grid_planner_test.dart` · -09 `test/platform/player/player_pool_test.dart`
- P2B-10 `lib/spike/player_spike_main.dart` (temporary entrypoint; stream URLs come from `--dart-define` values fed by CI secrets and are never committed; removed in P8)
- P2B-11 `.github/workflows/android_debug.yml` (manual; input `entrypoint`: a spike file or `lib/main.dart`; first step probes the spike streams; builds a debug APK; kept after P8 as the Android debug workflow)
- P2B-12 `codemagic.yaml` (workflow `ios_compile_check` only: iOS compile/link with no codesign, entrypoint variable, no `triggering:` block; extended in P7B)
- **Spike gate (checkpoint CP1):** run both manual workflows once; record in `docs/DECISIONS.md`: the engine decision, the license finding, cleartext/ATS findings, and the four capability findings (decoded-frame access, stream-to-file without re-encode, picture-in-picture surface, minSdk). The streams used are described by codec only, never by URL. Do not continue until the engine is chosen. A failed capability defers its dependent feature (PiP in R1, detection in R2, clips/recording in R3/R4) and is logged in Part K.

**P2C: pure ONVIF core, fixtures, tests (12)**
- P2C-01 `lib/core/services/ws_discovery_codec.dart` · -02 `onvif_message_builder.dart` · -03 `onvif_response_parser.dart` · -04 `ptz_math.dart`
- P2C-05 `test/fixtures/onvif/probe_match.xml` · -06 `device_information.xml` · -07 `get_profiles.xml` · -08 `stream_uri.xml`
- P2C-09 `test/core/services/ws_discovery_codec_test.dart` · -10 `onvif_message_builder_test.dart` · -11 `onvif_response_parser_test.dart` · -12 `ptz_math_test.dart`

**P2D: network platform services (7)**
- P2D-01 `lib/platform/network/ws_discovery_socket.dart` · -02 `multicast_lock_channel.dart` · -03 `subnet_scanner.dart` · -04 `onvif_client.dart` (SOAP, digest and WS-Security auth, timeouts) · -05 `http_probe.dart` · -06 `lan_info.dart` · -07 `local_network_permission_service.dart`

**P2E: profiles, URL building, tester (10)**
- P2E-01 `app/assets/profiles/camera_profiles.json` (schema versioned; verified flag per entry; brand names text only)
- P2E-02 `lib/core/services/profile_catalog.dart` · -03 `url_builder.dart` · -04 `rtsp_url_normalizer.dart` · -05 `connection_tester.dart` · -06 `diagnostics_service.dart` (assembles optional feedback attachment; opt-in)
- P2E-07 `test/core/services/url_builder_test.dart` · -08 `profile_catalog_test.dart` · -09 `connection_tester_test.dart` · -10 `rtsp_url_normalizer_test.dart`

**P2F: store seam adapters (6)** (the exact set the Amazon clone edits)
- P2F-01 `lib/platform/store/store_config.dart` · -02 `admob_service.dart` · -03 `consent_service.dart` · -04 `att_service.dart` · -05 `billing_service.dart` · -06 `review_service.dart`

**P2G: files, system, transfer services (11)**
- P2G-01 `lib/core/services/flag_service.dart` · -02 `review_prompt_policy.dart` · -03 `camera_export_service.dart` · -04 `camera_import_service.dart`
- P2G-05 `lib/platform/files/share_service.dart` · -06 `file_picker_service.dart`
- P2G-07 `lib/platform/system/haptics_service.dart` · -08 `screen_wake_service.dart` · -09 `orientation_service.dart`
- P2G-10 `test/core/services/camera_export_service_test.dart` · -11 `review_prompt_policy_test.dart`

**P3A: core providers (10)**
- P3A-01..10 `lib/core/providers/`: `theme_provider`, `subscription_provider`, `cameras_provider`, `layout_provider`, `discovery_provider`, `settings_provider`, `locale_provider`, `flags_provider`, `onboarding_provider`, `auto_cycle_provider` (all `ValueNotifier`-based)

**P3B: remaining providers, composition root, provider tests (7)**
- P3B-01 `ad_state_provider.dart` · -02 `undo_provider.dart` · -03 `persistence_health_provider.dart`
- P3B-04 `lib/app/app_providers.dart` (composition root: plain constructors, no DI package)
- P3B-05 `test/core/providers/cameras_provider_test.dart` · -06 `subscription_provider_test.dart` · -07 `settings_provider_test.dart`

**P4A: component library 1 (13)** (`lib/ui/components/`)
- P4A-01 `app_pressable` · -02 `app_button` (primary filled / secondary bordered / tinted / destructive filled; no text-only variant) · -03 `app_icon_button` (40x40 chip inside a 48x48 hit area) · -04 `app_text_field` · -05 `app_switch` · -06 `app_segmented_control` · -07 `app_list_row` · -08 `app_section` · -09 `app_divider` · -10 `app_chip` · -11 `app_badge` · -12 `app_progress` · -13 `app_card` (secondary-surface fill, hairline border, radius lg, no elevation, opacity press)

**P4B: component library 2 (12)**
- P4B-01 `app_scaffold` · -02 `app_nav_bar` · -03 `app_sheet` · -04 `app_dialog` · -05 `app_toast` (with undo action) · -06 `app_banner` · -07 `app_letter_header` (sticky letter header) · -08 `app_empty_state` · -09 `app_error_state` · -10 `app_page_route` · -11 `app_slider` · -12 `app_bottom_bar`

**P4C: viewer widgets (9)** (`lib/widgets/`)
- P4C-01 `stream_status_pill` · -02 `camera_tile` · -03 `camera_tile_overlay` · -04 `camera_grid` · -05 `grid_layout_picker` · -06 `fullscreen_controls` · -07 `ptz_pad` · -08 `ptz_speed_control` · -09 `snapshot_flash`

**P4D: setup and system widgets, widget tests (13)**
- P4D-01 `discovery_result_row` · -02 `camera_list_row` · -03 `brand_picker` · -04 `connection_test_panel` · -05 `banner_ad_slot` (embed spec C8.4; collapses to zero) · -06 `pro_badge` · -07 `permission_rationale_view` · -08 `onboarding_page` · -09 `persistence_warning_banner` · -10 `error_boundary_view`
- P4D-11 `test/widgets/camera_tile_test.dart` · -12 `app_button_test.dart` · -13 `rtl_layout_test.dart`

**P4E: visual spike (1)** (Gate 2 for the component library, before any screen)
- P4E-01 `lib/spike/visual_spike_main.dart` (temporary entrypoint; removed in P8): component gallery, tile with status pill at three widths, PTZ pad, sticky letter-header list, ad-slot insert/collapse mock, bottom-bar collapse under the keyboard, Arabic-mirrored nav bar. Built with `android_debug.yml` (entrypoint input). Checkpoint A1 in H5.

**P5A: primary screens (5)** (`lib/screens/`)
- P5A-01 `main_shell` · -02 `home_screen` · -03 `fullscreen_screen` · -04 `cameras_screen` · -05 `layout_sheet`

**P5B: camera setup screens (4)**
- P5B-01 `camera_edit_screen` · -02 `discovery_screen` · -03 `brand_picker_screen` · -04 `import_export_screen`

**P5C: settings and lifecycle screens (9)**
- P5C-01 `settings_screen` · -02 `appearance_screen` · -03 `upgrade_screen` · -04 `onboarding_screen` · -05 `local_network_rationale_screen` · -06 `about_screen` · -07 `licenses_screen` · -08 `fatal_error_screen` · -09 `language_screen` (24 languages by native name, searchable). Settings rows added in R1: Help, Language, Auto-cycle

**PH1: help logic and diagnostics (10)**
- PH1-01 `lib/core/models/help_article.dart` · -02 `help_step.dart` · -03 `troubleshoot_node.dart`
- PH1-04 `lib/core/services/help_catalog.dart` · -05 `troubleshooter_engine.dart`
- PH1-06 `lib/platform/network/network_diagnostics_service.dart` · -07 `public_ip_lookup.dart` (user-triggered only; D10)
- PH1-08 `lib/core/providers/help_provider.dart`
- PH1-09 `test/core/services/help_catalog_test.dart` · -10 `troubleshooter_engine_test.dart`

**PH2: help content, English (3)**
- PH2-01 `app/assets/help/help_structure.json` (10 articles, wizard paths, decision tree, in-app targets) · -02 `app/assets/help/strings/help_en.json` · -03 `test/assets/help_content_test.dart` (every id resolves, no outbound links)
- Also updates `pubspec.yaml` asset declarations.

**PH3: help widgets (7)** (`lib/widgets/help/`)
- PH3-01 `help_step_card` · -02 `help_callout` · -03 `help_code_block` (Mono, left-to-right) · -04 `help_deep_link_button` (in-app targets only) · -05 `help_test_button` · -06 `help_choice_card` · -07 `test/widgets/help_step_card_test.dart`

**PH4: help screens (5)** (`lib/screens/help/`)
- PH4-01 `help_hub_screen` · -02 `help_article_screen` · -03 `remote_access_wizard_screen` · -04 `troubleshooter_screen` · -05 `network_diagnostics_screen`

**P6A: app shell (7)**
- P6A-01 `lib/app/app.dart` · -02 `bootstrap.dart` · -03 `routes.dart` · -04 `lifecycle_observer.dart` · -05 `lib/main.dart` (replaces P0 stub) · -06 `test/app/smoke_test.dart` · -07 `test/app/navigation_test.dart`

**P6B: localization core (14)**
- P6B-01..06 `lib/l10n/app_en.arb` (template), `app_es_419.arb`, `app_fr.arb`, `app_de.arb`, `app_pt_BR.arb`, `app_ar.arb` (RTL verified)
- P6B-07..11 `app/assets/help/strings/help_es_419.json`, `help_fr.json`, `help_de.json`, `help_pt_BR.json`, `help_ar.json`
- P6B-12 `test/l10n/arb_parity_test.dart` (every key in every file except keys in `l10n_pending.txt`; placeholders match) · -13 `test/assets/help_parity_test.dart` · -14 `tool/arb_merge.dart`

**P6C: languages 2 (8, translation)**
- P6C-01..04 `app_zh_Hans.arb`, `app_ru.arb`, `app_hi.arb`, `app_bn.arb` · P6C-05..08 matching `help_<tag>.json`

**P6D: languages 3 (8, translation)**
- P6D-01..04 `app_ja.arb`, `app_ur.arb` (RTL), `app_id.arb`, `app_vi.arb` · P6D-05..08 matching `help_<tag>.json`

**P6E: languages 4 (8, translation)**
- P6E-01..04 `app_tr.arb`, `app_fa.arb` (RTL), `app_it.arb`, `app_ko.arb` · P6E-05..08 matching `help_<tag>.json`

**P6F: languages 5 (8, translation)**
- P6F-01..04 `app_th.arb`, `app_pl.arb`, `app_uk.arb`, `app_nl.arb` · P6F-05..08 matching `help_<tag>.json`

**P6G: languages 6 and RTL test (5, translation)**
- P6G-01..02 `app_he.arb` (RTL), `app_fil.arb` · P6G-03..04 matching `help_he.json`, `help_fil.json`
- P6G-05 `test/l10n/rtl_directionality_test.dart` (Arabic, Persian, Urdu, Hebrew; mirrored chevrons; IP/URL field stays left-to-right)
- Launch languages are these 24. Store listing text and iOS permission strings are localized in P7E-P7H.

**P7A: Android platform and CI (14)**
- P7A-01 `android/app/build.gradle` (minSdk from DECISIONS; `resourceConfigurations` for the 24 locales) · -02 `android/build.gradle` · -03 `android/settings.gradle` · -04 `android/gradle.properties`
- P7A-05 `android/app/src/main/AndroidManifest.xml` · -06 `src/debug/AndroidManifest.xml` · -07 `MainActivity.kt` · -08 `MulticastLockChannel.kt`
- P7A-09 `res/xml/data_extraction_rules.xml` · -10 `android/app/proguard-rules.pro` · -11 `res/xml/network_security_config.xml` (conditional on spike result)
- P7A-12 `.github/workflows/build_and_deploy.yml` (manual; AAB + APK; keystore decode/cleanup)
- P7A-13 `docs/ANDROID_SIGNING.md`
- P7A-14 `android/app/src/main/res/xml/locales_config.xml` (24 locales, per-app language on Android 13+; verify legacy tags such as `he`, `id`)

**P7B: iOS platform and CI (8, +1 conditional)**
- P7B-01 `ios/Podfile` · -02 `ios/Runner/Info.plist` (incl. `CFBundleLocalizations` for the 24 languages) · -03 `ios/Runner/PrivacyInfo.xcprivacy` · -04 `ios/ExportOptions.plist` · -05 `ios/Runner/AppDelegate.swift` · -06 `codemagic.yaml` (final: keeps `ios_compile_check`, adds `ios_testflight`; no `triggering:` block; sets `IOS_DISCOVERY_MODE`) · -07 `docs/IOS_SIGNING.md` · -08 `docs/IOS_PROJECT_SETTINGS.md`
- P7B-09 (conditional) `ios/Runner/Runner.entitlements` if Apple grants Multicast Networking

**P7C: brand assets and website (10)**
- P7C-01 `tool/make_brand_assets.dart` (resizes/composites supplied masters; draws nothing) · -02 `app/assets/branding/icon_master.png` (OWNER-SUPPLIED, 1024x1024) · -03 `app/assets/branding/splash_mark.png` (derived from the master by the tool unless the owner supplies it) · -04 `app/flutter_launcher_icons.yaml` · -05 `app/flutter_native_splash.yaml`
- P7C-06 `website/index.html` · -07 `privacy.html` · -08 `support.html` · -09 `style.css` (system font stack; no remote fonts, no external requests) · -10 `config/flags.json`
- Icon and splash: owner-supplied artwork on a dark graphite background; no blank white launch flash; adaptive Android icon with a monochrome layer. If the owner cannot supply artwork by P7C, that batch pauses rather than being filled with agent-drawn art.
- Derivation rules for the single owner master: the iOS icon is flattened onto an opaque background (iOS forbids transparency); the Android adaptive foreground scales the subject into the safe zone (inner 66% of the 108dp canvas); the splash foreground and the monochrome layer use the subject's alpha. This needs a master with a transparent background. If the master is full-bleed, the owner supplies the monochrome and splash foreground separately; the tool cannot extract a subject from an opaque square.

**P7D: store submission docs (8)**
- P7D-01 `store_submission/play/ASO_METADATA.md` · -02 `play/DATA_SAFETY.md` · -03 `ios/ASO_METADATA.md` · -04 `ios/PRIVACY_LABEL.md` · -05 `ios/REVIEW_NOTES.md` (skeleton only; the reviewer stream is deferred and is a release blocker, Part B) · -06 `SCREENSHOT_STRATEGY.md` · -07 `DATA_BACKING.md` · -08 `docs/RELEASE_RUNBOOK.md`
- `REVIEW_NOTES.md` fields: Protocol: RTSP · Transport: TCP · Credentials: as issued by the stream host, if any · Steps: Add camera, Manual, fill the fields above, Save, tap the tile. Values stay blank until the reviewer stream exists.

**P7E: store localization 1 (12, translation)**
- P7E-01..06 `store_submission/localized/<tag>.md` for `es_419`, `fr`, `de`, `pt_BR`, `ar`, `zh_Hans` (title, subtitle, short and full description, keywords, wording rules from D11/D13) · P7E-07..12 `app/ios/Runner/<tag>.lproj/InfoPlist.strings` (`NSLocalNetworkUsageDescription`, `NSUserTrackingUsageDescription`) for the same six

**P7F: store localization 2 (12, translation)**
- Same two files per locale for `ru`, `hi`, `bn`, `ja`, `ur`, `id`

**P7G: store localization 3 (12, translation)**
- Same two files per locale for `vi`, `tr`, `fa`, `it`, `ko`, `th`

**P7H: store localization 4 (10, translation)**
- Same two files per locale for `pl`, `uk`, `nl`, `he`, `fil`
- English listing text lives in P7D. Before this group, verify each store accepts each locale (Part B).

**P8: hardening and release readiness (3, plus deletions)**
- Delete `lib/spike/` (both spike entrypoints). Keep `.github/workflows/android_debug.yml`.
- P8-01 `tool/license_audit.sh` · -02 `docs/QA_MATRIX.md` (device/OS matrix: 2 low-end Android, 1 tablet, current iPhone, older supported iPhone, iPad) · -03 `docs/TEST_CAMERAS.md` (camera and brand compatibility log)

**End gate:** after P8 pushes clean, tag nothing, trigger nothing automatically. The developer runs the Android workflow manually (download the APK, sideload, test), then the Codemagic iOS workflow manually (TestFlight). Fix rounds are committed as `fix-<n>: ...` batches and re-triggered manually. R1 ships only when: the Gate 2 open list in `docs/VISUAL_QA.md` is empty, `l10n_pending.txt` is empty, and (before App Store submission) the reviewer stream exists.

### H5. Checkpoints: when CI is triggered by hand

The owner triggers workflows from the GitHub and Codemagic web pages on the phone. `flutter analyze` and the guard run after every batch regardless. If a workflow does not exist yet at a checkpoint, the loop continues on analyze alone until the next one.

| Checkpoint | After | GitHub Actions (`android_debug.yml`) | Codemagic | Gate 2 on |
|---|---|---|---|---|
| **CP1** player check | P2B | debug APK of the player spike | `ios_compile_check` (compile and link, no codesign) | engine, PiP surface, stream-to-file, frame access |
| **A1** component check (Android only, extra) | P4E | debug APK of the visual spike | none | component library, C8.6 prototypes |
| **CP2** screens done | P6A | debug APK of `lib/main.dart` (English) | `ios_compile_check` | every R1 screen built so far |
| **CP3** iPhone settings done | P7B | debug APK | `ios_testflight` (IPA to TestFlight) | iOS look, Arabic RTL, long-text languages |
| **CP4** end gate | P8 | `build_and_deploy.yml` (AAB + APK) | `ios_testflight` | all remaining screens; open items in `docs/VISUAL_QA.md` must be zero |

Each later release (R2, R3, R4) ends with its own end gate that repeats CP4 and a Gate 2 pass on its new screens. Android-only debug builds between checkpoints are allowed whenever the owner wants a visual check; they are free on a public repo.

### H4b. Later releases (planned; not authored until the previous release is live)

Same loop as H3. Strings added in these batches go in `app_en.arb` and in `l10n_pending.txt`; each release's last batch translates them (D14).

**R2 (Tier 1, monitoring)**

**T1A: data layer (10)**
- T1A-01 `lib/core/models/health_event.dart` · -02 `motion_event.dart` · -03 `snapshot_entry.dart` · -04 `zone_mask.dart` · -05 `detection_settings.dart`
- T1A-06 `lib/platform/storage/migrations/m002_events_snapshots.dart` (tables: health_events, motion_events, snapshots, zone_masks, detection_settings; registered in `migration_registry.dart`)
- T1A-07 `lib/core/contracts/notification_contract.dart` · -08 `frame_sample_contract.dart` · -09 `archive_storage_contract.dart`
- T1A-10 `test/core/models/event_models_test.dart`
- Also edits: `error_class.dart` (+`detectionUnavailable`), `app_settings.dart` (alerts fields; settings `schemaVersion` bump), `remote_flags.dart` (+`motionDetection`).

**T1B: detection and event logic, pure Dart (13)**
- T1B-01 `lib/core/services/detection/frame_differ.dart` · -02 `motion_detector.dart` · -03 `zone_mask_math.dart` · -04 `detection_scheduler.dart`
- T1B-05 `lib/core/services/health_monitor_policy.dart` · -06 `event_repository.dart` · -07 `event_query.dart` · -08 `snapshot_archive_policy.dart`
- T1B-09 `test/core/services/detection/frame_differ_test.dart` · -10 `motion_detector_test.dart` · -11 `zone_mask_math_test.dart` · -12 `test/core/services/health_monitor_policy_test.dart` · -13 `event_query_test.dart`

**T1C: platform services (8)**
- T1C-01 `lib/platform/system/local_notification_service.dart` · -02 `notification_permission_service.dart`
- T1C-03 `lib/platform/player/frame_sampler_service.dart` · -04 `lib/platform/network/health_probe_service.dart` · -05 `lib/platform/files/snapshot_archive_storage.dart` (sandbox directory, backup-excluded)
- T1C-06 `lib/core/services/monitoring_coordinator.dart` (foreground lifecycle only)
- T1C-07 `test/core/services/monitoring_coordinator_test.dart` · -08 `test/platform/files/snapshot_archive_storage_test.dart`
- Also edits: `AndroidManifest.xml` (`POST_NOTIFICATIONS`), `AppDelegate.swift` (foreground notification presentation), `pubspec.yaml` (notification package).

**T1D: providers and widgets (12)**
- T1D-01 `lib/core/providers/monitoring_provider.dart` · -02 `events_provider.dart` · -03 `snapshot_archive_provider.dart` · -04 `detection_settings_provider.dart`
- T1D-05 `lib/widgets/event_row.dart` · -06 `timeline_filter_bar.dart` · -07 `snapshot_thumb.dart` · -08 `mask_canvas.dart` · -09 `sensitivity_control.dart` · -10 `in_app_alert_banner.dart`
- T1D-11 `test/widgets/event_row_test.dart` · -12 `mask_canvas_test.dart`

**T1E: screens (4)**
- T1E-01 `lib/screens/activity_screen.dart` · -02 `detection_settings_screen.dart` · -03 `zone_mask_editor_screen.dart` · -04 `snapshot_viewer_screen.dart`
- Also edits: `main_shell.dart`, `app_bottom_bar.dart`, `routes.dart` (Activity tab), `settings_screen.dart`, `camera_edit_screen.dart` (detection entry).

**T1F: wording and store docs (2)**
- T1F-01 `docs/MONITORING_WORDING.md` · -02 `docs/R2_RELEASE_CHECKLIST.md`
- Also edits: `DATA_SAFETY.md`, `PRIVACY_LABEL.md`, ASO files, `website/privacy.html`.

**T1L: translations (23, translation)** `l10n_additions/r2/<tag>.json` for the 23 non-English locales, merged with `tool/arb_merge.dart`. R2 end gate (CP4 pattern).

**R3 (Tier 2, clips)**

**T2A: data layer (4)**
- T2A-01 `lib/core/models/schedule.dart` · -02 `clip_entry.dart` · -03 `lib/platform/storage/migrations/m003_schedules_clips.dart` · -04 `lib/core/contracts/clip_buffer_contract.dart`

**T2B: core logic (5)**
- T2B-01 `lib/core/services/schedule_evaluator.dart` · -02 `clip_planner.dart` · -03 `ring_buffer_policy.dart` · -04 `test/core/services/schedule_evaluator_test.dart` · -05 `clip_planner_test.dart`

**T2C: platform (3)**
- T2C-01 `lib/platform/recording/segment_writer.dart` (shared with R4) · -02 `ring_buffer_service.dart` · -03 `clip_exporter.dart`

**T2D: provider, widgets, screen (5)**
- T2D-01 `lib/core/providers/schedules_provider.dart` · -02 `lib/widgets/schedule_row.dart` · -03 `clip_player_view.dart` · -04 `lib/screens/schedules_screen.dart` · -05 `test/widgets/schedule_row_test.dart`

**T2L: translations (23, translation)** `l10n_additions/r3/<tag>.json`. R3 end gate.

**R4 (Tier 3, local recording, foreground only)**

**T3A: data layer (6)**
- T3A-01 `lib/core/models/recording.dart` · -02 `segment.dart` · -03 `retention_budget.dart` · -04 `lib/platform/storage/migrations/m004_recordings.dart` · -05 `lib/core/contracts/recording_contract.dart` · -06 `test/core/models/recording_models_test.dart`
- Also edits: `error_class.dart` (+`recordingFailed`, `storageFull`), `remote_flags.dart` (+`recording`).

**T3B: core logic (7)**
- T3B-01 `lib/core/services/storage_budget_calculator.dart` · -02 `retention_policy.dart` · -03 `recording_coordinator.dart` · -04 `playback_timeline.dart`
- T3B-05 `test/core/services/storage_budget_calculator_test.dart` · -06 `retention_policy_test.dart` · -07 `playback_timeline_test.dart`

**T3C: platform (4)**
- T3C-01 `lib/platform/recording/recording_service.dart` · -02 `segment_file_store.dart` · -03 `storage_inspector.dart` · -04 `test/platform/recording/segment_file_store_test.dart`

**T3D: providers and widgets (5)**
- T3D-01 `lib/core/providers/recordings_provider.dart` · -02 `storage_provider.dart` · -03 `lib/widgets/segment_scrubber.dart` · -04 `storage_budget_slider.dart` · -05 `recording_indicator.dart`

**T3E: screens (2)**
- T3E-01 `lib/screens/recording_playback_screen.dart` · -02 `storage_manager_screen.dart`

**T3F: wording (1)**
- T3F-01 `docs/RECORDING_WORDING.md` ("records while the app is open" on both platforms)

**T3L: translations (23, translation)** `l10n_additions/r4/<tag>.json`. R4 end gate.

### H6. Totals and effort

| Release | Batches | Files | of which translation files |
|---|---|---|---|
| R1 | 44 | 395 | 92 |
| R2 | 7 | 72 | 23 |
| R3 | 5 | 40 | 23 |
| R4 | 7 | 48 | 23 |
| **All** | **63** | **555** | **161** |

Hand-authored files: 394. Counts exclude edits to existing files and one conditional file (`Runner.entitlements`). The Scope Proposal estimated 44-48 batches; the 24-language scope (ARB, help strings, store text and iOS permission strings per language) and per-release translation batches account for most of the difference.

Estimated effort (my judgment, not a measurement): R1 about 65-100 prompts including fix rounds; R2-R4 about 28-45 more. Highest fix-round risk: P2B (player, and the capability findings that gate R2-R4), P2D (network), P7A/P7B (platform config), T1C (frame sampler), T2C/T3C (stream-to-file segments).

---

## PART I: BEFORE CODE STARTS

- [x] Name, account, identifier chosen: Roehens, `zdmgold`, `com.zdmgold.roehens` (immutable after release)
- [x] Repo URL supplied: `https://github.com/helpfavourv1/Roehens.git` (owner confirms it is empty)
- [ ] Fine-grained GitHub token created (Contents + Workflows read/write, Roehens only)
- [ ] Flutter Linux arm64 works in the proot Ubuntu (`flutter doctor`, `flutter analyze` on a blank app). Owner status: to be reverified
- [x] Apple Multicast entitlement: request now; ship `subnet_sweep_only` until granted. [ ] Request actually filed
- [ ] Spike streams added as GitHub secrets and verified reachable at build time (reviewer stream is separate and deferred)
- [x] Reviewer test stream: deferred, **release blocker for App Store submission**, not a start condition
- [x] Batch plan H4/H4b approved by the owner (Oct 1): R1 first, R2-R4 only after the previous release is live
- [x] Checkpoint plan H5 approved (replaces the single spike exception)
- [x] Icon plan confirmed: Phosphor primary, Tabler gap-filler only, single wrapper; no custom-drawn icons
- [x] Fonts: system fonts by default; free-licensed bundled fonts allowed only under C1.5
- [x] Owner commits to one master artwork image (1024x1024 PNG, transparent background recommended), from which the splash foreground, adaptive foreground and monochrome layers are derived; due before P7C. [ ] Delivered
- [ ] Cheapest Android test device and iPhone/iPad test device recorded in Part B
- [x] Public-IP lookup kept with disclosure (H1); [ ] service chosen
- [x] Translation approach: machine-generated, English-authoritative legal text (D14)
- [ ] Before submission: reviewer stream live, store locales verified, `l10n_pending.txt` empty

---

## PART J: AMAZON FIRE FORK (after v1 ships)

**Trigger:** Release R1 is live on Play and the App Store, the main repo is at a stable tagged commit, and Amazon's developer account and AdMob Amazon entry are ready.

### J1. Fork procedure

1. On the web, create an empty repo `Roehens-fire` (public).
2. In Termux: `git clone <main-repo-url> Roehens-fire`, `cd Roehens-fire`, `git remote rename origin upstream`, `git remote add origin <fire-repo-url>`, `git push -u origin main`. Keep `upstream` to pull shared fixes with `git fetch upstream` and cherry-pick.
3. Create a branch `fire-conversion`, make the changes below in batches `F1`..`F5` with the same analyze + guard + test loop, merge to `main`, then run the Fire APK workflow manually.
4. Identity: new `docs/IDENTITY.md` with Amazon entries (applicationId `com.zdmgold.roehens.fire`, Amazon Developer Console app, separate AdMob app + banner unit, Fire test devices).

### J2. Files to DELETE (14)

- `ios/` (whole folder), `codemagic.yaml`
- `store_submission/ios/` (whole folder)
- `docs/IOS_SIGNING.md`, `docs/IOS_PROJECT_SETTINGS.md`
- `lib/platform/store/att_service.dart` and its use in bootstrap (Fire has no ATT)
- `website/` (the Fire app reuses the main site's privacy, support, and flags URLs)
- `lib/spike/` if still present; `tool/make_brand_assets.dart` only if not reused (keep if reusing icon pipeline)
- iOS-only lines in `pubspec.yaml`, `README.md`, `docs/RELEASE_RUNBOOK.md`

### J3. Files to MODIFY (14)

| File | Change |
|---|---|
| `app/pubspec.yaml` | name/description; remove `in_app_purchase` and `in_app_review`; keep or replace ads SDK per J5; re-lock versions |
| `app/android/app/build.gradle` | `applicationId` -> `com.zdmgold.roehens.fire` (leave `namespace` and Kotlin package unchanged so no source moves); universal APK only (no per-ABI splits; Amazon takes one APK) |
| `app/android/app/src/main/AndroidManifest.xml` | replace AdMob app ID meta-data; remove billing permission if present after dependency removal; keep only permissions that trace to the capability matrix |
| `lib/platform/store/store_config.dart` | `storeName = amazon`, `iapSupported = false`, Amazon listing URL, new ad unit IDs |
| `lib/platform/store/billing_service.dart` | replace with `NoBillingService` implementing `PurchaseContract`: always returns `unavailable`, no store imports |
| `lib/platform/store/review_service.dart` | replace with a link-out to the Amazon listing (`url_launcher`); no Play In-App Review |
| `lib/platform/store/admob_service.dart` | keep if AdMob passes the Fire hardware test (J5); otherwise replace with Amazon Publisher Services adapter implementing `AdContract` |
| `lib/platform/store/consent_service.dart` | keep if UMP works on Fire OS; otherwise replace with a simple in-app consent dialog implementing `ConsentContract` |
| `lib/screens/settings_screen.dart` | hide Upgrade and Restore rows when `StoreConfig.iapSupported == false` |
| `lib/screens/upgrade_screen.dart` | unreachable on Fire; retain file but remove route entry (or delete route + file) |
| `lib/screens/about_screen.dart` | store name and rate link come from `StoreConfig` (no string change if already config-driven) |
| `lib/l10n/*.arb` | store-specific strings (rate label); mark ad-free strings unused; keep ARB parity test green |
| `.github/workflows/build_and_deploy.yml` | drop AAB and the keystore-for-Play assumptions; build one universal release APK, obfuscated; artifact name `roehens-fire-apk` |
| `README.md`, `docs/IDENTITY.md`, `docs/RELEASE_RUNBOOK.md` | Amazon identifiers and release steps |

Nothing else changes. `core/`, `ui/`, `widgets/`, providers and most screens stay byte-identical, which is why the store seam (A4) exists. `subscription_provider` stays: it holds `free` permanently when billing is unavailable.

### J4. Files to ADD (8)

- `store_submission/amazon/LISTING.md` (title, descriptions, keywords; states "ads-supported, no in-app purchases", LAN-only, no cloud)
- `store_submission/amazon/ADS_AND_PRIVACY_DISCLOSURE.md`
- `store_submission/amazon/ASSETS_SPEC.md` (icon sizes, landscape tablet screenshots, promo image)
- `store_submission/amazon/TEST_DEVICES.md` (Fire OS 7 and 8 tablets tested)
- `store_submission/amazon/REVIEW_NOTES.md` (test stream and steps)
- `tool/fire_guard.sh` (fails if `com.google.android.gms`, `com.android.vending`, or Play-only plugins appear in `pubspec.lock` or the merged manifest, except accepted ads SDK items)
- `test/store/store_config_test.dart` (asserts `iapSupported == false`, `storeName == 'amazon'`)
- `docs/FIRE_CONVERSION_LOG.md` (what was changed and verified)

### J5. Fire-specific verification (real hardware, no shortcuts)

1. Ads: run the AdMob banner on a real Fire tablet on Fire OS 7 and 8. If fill or init fails, switch `admob_service.dart` to the Amazon Publisher Services adapter (the contract makes this a one-file change).
2. Consent: verify the consent flow works without Google Play services; otherwise use the in-app dialog.
3. Player: verify RTSP H.264 and H.265 decode on Fire hardware decoders; low-end Fire tablets may need the `low-memory` decoder budget (2 concurrent).
4. Storage: verify the secure vault works on Fire OS (Keystore-backed; confirm).
5. Discovery: verify multicast lock and the sweep fallback.
6. Size and install: universal APK installs on both ABIs; confirm size against Amazon limits.
7. Run `tool/fire_guard.sh` and the guard suite, then the Fire APK workflow manually; install with the Amazon Appstore's testing flow and on-device.

### J6. Ongoing sync

Shared fixes are made in the main repo first, then pulled with `git fetch upstream && git cherry-pick <sha>`. Conflicts should only occur in the files listed in J3. If a shared fix touches a J3 file, re-verify J5 before shipping

### J7. Later releases on Fire (R2-R4)

Part J covers R1. R2-R4 are built in the main repo first and cherry-picked (J6). There is no foreground service in any release, so Amazon's foreground-service policy does not apply. Each of the following is re-verified on real Fire hardware before that release ships on Fire: R2 notification permission behavior and the frame sampler on Fire decoders; R3 stream-to-file segments; R4 recording storage path and free-space floor; Android picture-in-picture availability on Fire OS. Help content and the 24 languages sync unchanged.

---

## PART K: DECISION LOG

### K1. Decisions from the Updated Scope Proposal (H1-H12)

| # | Decision | Resolution here |
|---|---|---|
| H1 | Public-IP lookup in diagnostics | Kept, user-triggered, disclosed (D10, Part B) |
| H2 | Relay path article | Included; service names as text only (D10) |
| H3 | Article depth | Full set of 10 (D10) |
| H4 | Zone masking | Included in R2 (owner: use recommendation) |
| H5 | iOS background alerts | Not promised: alerts only while the app is open (A2, D11) |
| H6 | Ring buffer location | Disk, rolling short segments (D12); delegated to the agent |
| H7 | Android background recording | Out. Foreground-only on both platforms; no foreground service, no Play Console declaration |
| H8 | Default retention | User-chosen only; nothing records until a budget is set; free-space floor always applies (D13) |
| H9 | Translation source and store metadata | Machine translation; localized store metadata for all 24 (D14, P7E-P7H) |
| H10 | Audio-only mode | Foreground-only could not deliver its purpose (hearing a camera with the screen off), so it is **deferred**, not built. Revisit only if background support is ever approved |
| H11 | Picture-in-picture on iOS | Android only in R1. iOS PiP would need the engine to draw into a special video layer and normally a background-audio setting, which collides with "no background modes". Deferred; listings say Android only; delegated to the agent |
| H12 | Kill switch during recording | Allowed to interrupt. It closes the current segment at once so it stays playable, never deletes data, and shows a notice. Flags are re-checked every 6 hours and on resume while the app is open (D7) |

### K2. Rejected or deferred (considered against the pain point)

Home-screen widgets, watch/TV companions, two-way audio, LAN device sync, notes/tags/groups/favorites, QR-code import, custom tile ordering, bandwidth/bitrate/fps overlays, timestamp overlay, privacy blur mode, local usage stats, snapshot to clipboard, volume boost, sleep timer, home-screen quick actions, encrypted export bundle: rejected (polish track, or contradicts scope). Added by this document: background recording (rejected, H7), background alerts (rejected, H5/H7), audio-only mode (deferred, H10), iOS picture-in-picture (deferred, H11), remote push notifications (rejected: no backend).

### K3. Owner answers, Oct 1, 2026

Release plan: ship R1 first. Test builds: analyze after every batch, manual CI at the H5 checkpoints. Reviewer stream: deferred (spike streams are build-phase only). Cheapest device and reference app: follow platform practice (C8.5, Part B). Artwork: one master, derived. GitHub: HTTPS with a token. Batch plan: approved as detailed. Fonts: system plus free-licensed. All suggested fixes: applied. Remaining questions answered "use recommendations": zone masking yes, detection limited to on-screen cameras, best-effort system notifications, extra Android-only checkpoint builds, artwork and device details recorded by the owner in Part B.

### K4. Corrections made to the source documents

1. The Sep 30 spec attributed rules to the Enterprise Production Blueprint that the uploaded Blueprint does not contain (light-first default, Body 17, scroll physics). They are now stated as this document's own product decisions.
2. Apple's background-services rule is cited by its current number, Guideline 2.5.4. The Scope Proposal used 2.16, the number from Apple's earliest guidelines.
3. Recording is by saving the camera's encoded stream, not Android MediaRecorder (which records the phone's own camera and microphone). The "camera" foreground-service type is for the phone's own camera and is not used.
4. iOS has no Info.plist key for notification permission. The Scope Proposal's "notification permission string" does not exist; an in-app rationale precedes the system prompt.
5. Codemagic has no `workflow_dispatch`. "Manual only" means the yaml has no `triggering:` block.
6. Android minSdk was stated as API 21 and as Android 6+. It is one recorded value now (A1).
7. The Settings screen had no language selector; the 24-language scope needed one (`language_screen`).
8. Spike stream URLs with credentials are not hardcoded in a public repo: they come from CI secrets. The spec's hardcoded-URL spike entrypoint now reads `--dart-define` values.
9. 16-up grid tiles cannot hold "message + Retry"; below 120dp tile width the status pill is icon-only and a tap opens a sheet with the message and Retry/Edit pills.
10. Skeleton loaders, scale-on-press, per-screen card styling, text-only controls, and the `app_skeleton` component were removed to meet the Blueprint.
11. "Delete all local data" covers events, snapshots, clips and recordings once they exist. Snapshots and recordings are excluded from device backups.
12. The Scope Proposal's single `m002` migration is split by release: `m002` (R2), `m003` (R3), `m004` (R4).

### K5. Assumptions to confirm if wrong

Release 1 ("Phase 1") is the full live viewer plus Help plus 24 languages plus auto-cycle plus Android PiP, not Tier 1. Moving a feature between releases only changes which batches run first; no data-model change is needed because R2-R4 batches are independent of R1 except through `migration_registry.dart`, `remote_flags.dart`, `error_class.dart` and `app_settings.dart`.
