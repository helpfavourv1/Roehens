# Handoff: where the build stands and how to continue

Written at the end of batch P4E and the second checkpoint-A1 round. Update this file at the end of every batch (see "Keeping the docs current"). A new agent reads, in this order: this file, `BLUEPRINT.md`, `DECISIONS.md`, `VISUAL_QA.md`, `IDENTITY.md`.

## 1. The three master documents

| File | What it is | How it changes |
|---|---|---|
| `docs/BLUEPRINT.md` | The master specification (merged v2.0, Oct 1 2026): product definition, design system, behavior, screens, repo layout, platform config, the operational loop, and **every batch in dependency order with file lists** (H4 for R1, H4b for R2 to R4), the Amazon Fire fork, the decision log. | Never edited for progress. It is the plan. Change it only when the owner changes scope, and say so in `DECISIONS.md`. |
| `docs/DECISIONS.md` | Every pivot, upgrade and finding, in the order it happened, by batch. Where the build differs from the blueprint, this file wins. | Append a section at the end of each batch. Never rewrite history. |
| `docs/HANDOFF.md` | This file: current state, what is next, what is outstanding, how to work here. | Rewrite the status sections at the end of each batch. |

Precedence (from the blueprint): owner decisions > `DECISIONS.md` > `BLUEPRINT.md` > source documents.

## 2. Access

- **Repository:** `https://github.com/helpfavourv1/Roehens` (public, default branch `main`, owner account `helpfavourv1`).
- **Access token:** the owner supplies it in the conversation or the project instructions. **It is not in the repository and must never be written into any file, commit, comment or doc** (the repo is public; the guard and `tool/static_audit.py` fail on token patterns). It authenticates as `helpfavourv1` and has Contents, Workflows, Actions and Secrets read/write on `Roehens`.
- Clone: `git clone https://helpfavourv1:<TOKEN>@github.com/helpfavourv1/Roehens.git`
- Commit identity: name `helpfavourv1`, email `314438714+helpfavourv1@users.noreply.github.com` (GitHub rejects pushes that expose a private email).
- The owner's support email for the app and privacy page is `stmakarios@gmail.com` (in `IDENTITY.md` and `AppConstants.supportEmail`). It is not a commit identity.
- GitHub Actions secrets already set (values are never read back): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` (alias is lowercase `roehens`), `SPIKE_RTSP_URL`, `SPIKE_MJPEG_URL`, `SPIKE_EXTRA_URLS`. The keystore itself never enters the repo.

## 3. The owner and the working mode

- The owner works **only from an Android phone** (Redmi `25028RN03A`, Android 15, about 3.7 GiB RAM, low-RAM device, no picture-in-picture support). No computer, no iPhone or iPad. The owner downloads test APKs from **Actions, then the run, then Artifacts** (this needs the browser to be signed in to GitHub; the download icon sits next to the digest). Do not build release or draft-release workarounds; the owner declined them.
- Do not lecture. Do not tell the owner to revoke or rotate the token. Do not assume details the owner must give: ask, and do not scatter placeholders.
- "We are not rigid about the blueprint except enterprise-grade production": improve and pivot where needed, but log it in `DECISIONS.md`. Never remove an owner-scoped feature without asking (an earlier slip: picture-in-picture was almost dropped; the owner reversed it).
- The owner says "continue" or "go" to start the next batch. Report after each batch: what landed, what changed from the blueprint, what is needed from the owner. Keep replies short and plain.
- Honesty rule learned the hard way: do not call something working because widget tests pass. Check claims against the real engine (the emulator workflow) or say it is unproven.

## 4. The environment, and how to work in it

**The sandbox cannot run Flutter** (the Flutter download host is blocked) and it resets now and then. **CI is the compiler.** Reachable from the sandbox: `github.com`, `api.github.com`, `raw.githubusercontent.com`, PyPI, npm, Ubuntu mirrors. Not reachable: pub.dev, GitHub artifact storage (so artifact zips cannot be downloaded; screenshots go through the `ci-logs` branch instead). For package research use web search or fetch. If the working copy disappears, re-clone; nothing is lost.

**Loop per batch:** `git pull --rebase`, write files, run `sh tool/guard.sh` and `python3 tool/static_audit.py` locally (both work without Flutter), commit with `<batch>: <purpose>`, push, then `GH_TOKEN=<token> sh tool/ci_wait.sh check <short-sha>` and read the result. Fix and repeat until green. Only then report.

Workflows (all in `.github/workflows/`):

| Workflow | Trigger | Does |
|---|---|---|
| `check.yml` | every push | Refreshes `pubspec.lock`, **runs `dart format` and commits the result back**, `flutter analyze` (infos fail), `tool/guard.sh`, `flutter test`, publishes `latest.log` to branch `ci-logs`. The workflow's own commits do not start another run. Because it commits to `main`, **always `git pull --rebase` before editing**, and wait for the run to finish before the next edit. |
| `full_check.yml` | manual | Everything above plus lockfile comparison, coverage report (`tool/coverage_report.py`), license audit (`tool/license_audit.sh`), `dart format` report, `pub outdated`, `tool/static_audit.py`. Prints `VERDICT: PASS` or `FAIL`. Run before handing a build to the owner. |
| `emulator_check.yml` | manual | Runs `app/integration_test` on an Android 34 emulator with `flutter drive`, takes **screenshots** and publishes them to `ci-logs/screenshots/`. Read them straight after the run (the next workflow replaces the branch): `curl` the contents API with the token, then view the PNG. This is how to see the app without the owner. |
| `android_debug.yml` | manual | Builds a debug APK (`entrypoint` input: `lib/main.dart` or a spike file; `abi` default `android-arm64`). Artifact name `roehens-debug-apk`. |
| `bootstrap.yml` | manual, one time | Generated the `android/` and `ios/` scaffold (done). |

Trigger a manual workflow with a POST to `/actions/workflows/<file>/dispatches` (`{"ref":"main","inputs":{...}}`). Manual-only is a rule: no push, tag or schedule trigger except `check.yml`.

**Pinned toolchain:** Flutter 3.47.6, Dart 3.13.5 (arm64 and CI identical). iOS deployment target 15.0. Android `applicationId` = `namespace` = `com.zdmgold.roehens`; iOS bundle ID the same. `minSdk` currently follows Flutter's default and is to be pinned once in `DECISIONS.md` (batch P7A).

## 5. Architecture in one page

Single Flutter codebase in `app/`. Layers (enforced by `tool/guard.sh` and `tool/static_audit.py`):

- `lib/core/` pure Dart (no `dart:io`, no plugins; `dart:ui` and `xml`, `intl`, `crypto` allowed): `constants/`, `contracts/` (interfaces), `errors/`, `models/`, `providers/` (`ValueNotifier`-based, all extend `SafeValueNotifier`), `services/` (ONVIF codec and parser, URL builder, connection tester, grid planner, reconnect policy, export and import, flag service, review policy, repository).
- `lib/platform/` implements the contracts: `storage/` (sqflite database with migrations, key-value store, secure vault), `player/` (media_kit session, MJPEG session, pool, frame capture), `network/` (subnet scanner, WS-Discovery socket, ONVIF client, probes, discovery and PTZ services, LAN info, permission), `store/` (AdMob, consent, ATT, billing, review: the only place store SDKs may be imported), `files/`, `system/` (haptics, wake lock, orientation, PiP, logger).
- `lib/ui/` the design system: `tokens/` (frozen), `icons/` (one wrapper over bundled Phosphor fonts), `components/` (25 components plus `LtrText`, the text selection toolbar and handles, `AppAnimatedSize`).
- `lib/widgets/` feature widgets (tile, grid, PTZ pad, fullscreen controls, status pill, brand picker, connection test panel, ad slot, and so on). `lib/screens/` does not exist yet.
- `lib/app/app_providers.dart` is the composition root (plain constructors, test overrides via `AppOverrides`). Screens and widgets never import `platform/`.
- Rules that bite: no Material or Cupertino widgets or icons (the app hosts on `WidgetsApp`); **no `setState`** (use `ValueNotifier`); tokens only (no raw `Color(0x`, no numeric spacing literals in `screens/` and `widgets/`); no hard-coded user-facing strings in `screens/` and `widgets/`; direction is read only through `context.isRtl`; `AppTokens` must wrap the whole navigator (overlays read it); private named parameters use `this._x`; every analyzer info fails the build.

## 6. Where the build stands

Verified at commit `b92d976` on `main`: analyze clean, guard clean, `tool/static_audit.py` 0 errors and 0 warnings, **907 tests pass**, line coverage about 90 percent (`full_check` PASS earlier at 881 tests; rerun it before the next hand-over).

| Batch | What | State |
|---|---|---|
| P0 | Scaffold, guard, docs, workflows, platform folders | Done |
| P1A | Design tokens and theme | Done (two light colors darkened for contrast, logged) |
| P1B | Icon wrapper, 88 semantic icons | Done. The `phosphor_flutter` package does not compile on Flutter 3.47, so the MIT fonts (Bold, Fill, Duotone) are bundled and each glyph is a compile-time constant |
| P1C to P1F | Errors, constants, 14 models, 16 contracts, tests | Done |
| P2A | Storage, vault, repository | Done |
| P2B | Player engine (media_kit), pool, planner, spike | Done. Engine confirmed; findings in `DECISIONS.md` (stock libmpv lacks multipart MJPEG, muxers and RTSP over UDP). The MJPEG client is written in Dart |
| P2C to P2E | ONVIF core, network services, profiles, URL builder, connection tester | Done |
| P2F | Store seam adapters | Done (Google test ad IDs; real ones come at release) |
| P2G | Flags, review policy, export and import, share, file picker, haptics, wake, orientation | Done |
| P3A, P3B | Ten providers, ad state, undo, persistence health, composition root; discovery, PTZ and PiP services | Done |
| P4A to P4D | 25 UI components; viewer widgets; setup and system widgets; right-to-left tests | Done |
| P4E | Visual spike (`lib/spike/visual_spike_main.dart`, temporary) | Done |
| A1 | Checkpoint on the owner's phone, two rounds, 37 screenshots | Two rounds of fixes done; **owner's verdict on run #10 is pending** |
| Extras added beyond the plan | `tool/static_audit.py`, `license_audit.sh`, `coverage_report.py`, `ci_wait.sh`, `full_check` and `emulator_check` workflows, automatic formatting, Android backups off, `DiscoveryService`, `PtzService`, `PipService` | Done |

**The current APK** is `android_debug` run #10 (run id `43381171828`, commit `b92d976`), visual spike entry point, awaiting the owner's look. **P5A has not been started.**

Findings from A1 (all fixed, full list in `VISUAL_QA.md` and `DECISIONS.md`): no copy/paste on Android (the system menu is iOS-only; a bare `EditableText` ignores gestures; own selection gestures, handles and toolbar built; handles were hidden because `showSelectionHandles` defaults to off); invisible light-mode status bar icons; 4x4 tile overflow; large-text layout breaks; animations-off layout error in `AnimatedSize` (found only by the emulator).

## 7. What comes next, in dependency order

The complete file lists, with IDs, are in `BLUEPRINT.md` section H4. Remaining R1 batches: **P5A** (main shell, Live, fullscreen, cameras, layout sheet), **P5B** (camera edit, discovery, brand picker, import/export screens), **P5C** (settings, appearance, upgrade, onboarding, rationale, about, licenses, fatal error, language), **PH1 to PH4** (help logic, English help content, help widgets, help screens), **P6A** (app shell, bootstrap, routes, lifecycle, `main.dart`, smoke and navigation tests; checkpoint CP2), **P6B to P6G** (24 languages), **P7A** (Android platform and signing workflow), **P7B** (iOS, Codemagic), **P7C** (brand assets, website), **P7D to P7H** (store docs and localization), **P8** (delete `lib/spike/`, license audit, QA docs, end gate). R2 to R4 are planned in H4b and are **not authored until the previous release is live**.

Notes for P5A and what it needs first:

1. **A `VideoSurface`** in `platform/player` that turns a session's `viewHandle` (a media_kit `VideoController`, or a `ValueListenable<Uint8List?>` for MJPEG) into a widget, exposed to screens through the composition root as a builder, not as a platform type. `CameraTile` already takes the video as a `Widget`.
2. **Getting `AppProviders` to screens**: there is no scope widget yet. Add a small `InheritedWidget` (for example `AppScope.of(context)`).
3. **Strings.** Screens may not contain literal text, so P5A is the first batch that needs ARB keys. `app/l10n.yaml` exists and `l10n_pending.txt` tracks untranslated keys, but nothing generates `AppLocalizations` yet. Decide and prove in CI how it is generated (`flutter gen-l10n` is a Flutter tool, not a code-generation package). Also add `GlobalWidgetsLocalizations.delegate`: the text selection toolbar takes its Cut, Copy, Paste and Select all words from `WidgetsLocalizations`, which covers all 24 launch languages.
4. The app shell must wrap `AppTokens` around the whole navigator through `WidgetsApp.builder`, call `SystemChrome.setEnabledSystemUIMode(edgeToEdge)`, and feed `autoCycle`, `adState`, `flags` and the lifecycle (`AppProviders.onResume` and `onPause`).
5. Gate 2 applies: a screen is "implemented" after analyze, guard and tests, and "done" only after the owner's look at its checkpoint. Use `emulator_check` screenshots to review before bothering the owner.

## 8. Outstanding items

**Needed from the owner** (ask when due; do not guess):
- A verdict on run #10: weight, spacing and clarity against Google Home; whether the plain-circle selection handles read as handles; light-theme warning banner tint.
- Before P7C: the master artwork (1024x1024). Open question from the owner: generating it in code. The agent can only render geometry it can see (via emulator screenshots) and must not draw icon paths blind.
- Before CP1-style real-camera proof: a LAN IP camera, DVR or NVR (the 5 MP H.265 stream decodes in software on the Redmi; first frame took 6 to 16 s over mobile data), or accept those as "unproven".
- Website domain and hosting (owner will connect Cloudflare after the website files exist; the flags URL is unset until then, so kill switches have no effect yet); the privacy, support and flags URLs.
- Real AdMob app IDs and banner units (release only; test IDs are used now). Play Console app and Play App Signing; App Store Connect app, Team ID and API key; Codemagic project; **filing the Apple Multicast Networking entitlement request** (owner action, listed in the blueprint); a stable **reviewer test stream** (blocker for App Store submission only); choice of the one free public-IP lookup service (blueprint H1, not yet chosen); store locale acceptance per store.
- The keystore passwords are in the owner's original message and in GitHub secrets; they were never repeated in any file.

**Technical outstanding or unproven** (also tracked in `DECISIONS.md` and `VISUAL_QA.md`):
- Needs a custom FFmpeg or libmpv build before the R1 end gate: RTSP over UDP; before R3: saving a stream to segment files. MJPEG over HTTP is handled by the Dart client, not the player.
- Not testable here: picture-in-picture (phone does not support it; the Kotlin `pipChanged` callback and `PipService` are untested on a device), anything on iOS (no device; iOS discovery runs sweep-only until Apple grants the entitlement), `PtzService` against a real ONVIF camera, `player_session.dart` (native), the store SDK adapters.
- `flutter_secure_storage` was moved to 11.x (Android storage implementation changed); it builds and its tests pass but has not been exercised on a device.
- `google_mobile_ads` size call is deprecated; a file-level ignore is in place with the reason.
- 22 packages have newer versions (informational, from `pub outdated`).
- Selection highlight and toolbar were judged on the emulator and the owner's phone; handles are circles, not teardrops.
- 310 percent text is only verified by widget tests; 200 percent was checked on a device and the emulator.
- `minSdk` and `targetSdk` are not yet pinned or documented (P7A).

## 9. Keeping the docs current

At the end of every batch: append a `DECISIONS.md` section (what changed from the blueprint and why, findings, anything unproven); update the status table, "next" and "outstanding" sections here; update `VISUAL_QA.md` when a screen is built or reviewed; keep `IDENTITY.md` honest. Commit them with the batch. At every checkpoint run `full_check`, and for anything visual run `emulator_check` and look at the screenshots before handing a build to the owner.
