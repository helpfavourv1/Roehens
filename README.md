# Roehens

IP camera viewer for iOS and Android. Every camera on your network, one calm screen.

- Identifier: `com.zdmgold.roehens`
- Dart package: `roehens` (Flutter app in `app/`)
- Release R1 scope: live multi-camera viewer, ONVIF and subnet discovery, PTZ, snapshots, Help and remote-access section, 24 languages, auto-cycle, Android picture-in-picture (engine permitting).

## Repository layout

| Path | Purpose |
|---|---|
| `app/` | Flutter application |
| `tool/` | `guard.sh` (structure and style rules), CI helper scripts |
| `docs/` | Identity, decisions, icon map, visual QA log, runbooks |
| `website/` | Static marketing site (added in P7C) |
| `store_submission/` | Store listing and policy documents (added in P7D) |
| `.github/workflows/` | CI |

## Checks

Every push to `main` runs `.github/workflows/check.yml`: `flutter pub get`, `flutter analyze`, `sh tool/guard.sh` and `flutter test`. It builds nothing and signs nothing. The output of each run is published to the `ci-logs` branch (`latest.log`).

Builds are manual only (`workflow_dispatch`).

## Local guard

```
sh tool/guard.sh            # every batch
sh tool/guard.sh --release  # end gate of a release (also requires l10n_pending.txt to be empty)
```

Secrets never enter this repository. See `docs/IDENTITY.md` for the list of secret names that exist in GitHub.
