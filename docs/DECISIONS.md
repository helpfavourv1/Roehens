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
9. **Localization config.** `app/l10n.yaml` exists from P0; `generate: true` is switched on in `pubspec.yaml` in batch P6B together with the first ARB files.

## Player engine

Not yet decided. Decided at checkpoint CP1 (after batch P2B) from the spike results, with the license finding, cleartext/ATS findings and the four capability findings recorded here.

## Dependencies and licenses

No third-party runtime dependency has been added yet. Each addition is logged here with version, maintenance status and license class.
