# Identity and account tracking

Living document. The identifier is immutable after the first release. No passwords, tokens, keystores or stream URLs are ever recorded here; only names and statuses.

| Field | Value | Status |
|---|---|---|
| Product name | Roehens | done |
| Identifier (iOS bundle ID, Android applicationId, Android namespace) | `com.zdmgold.roehens` | done |
| Account segment | `zdmgold` (identifier only) | done |
| GitHub owner / repo | `helpfavourv1` / `Roehens`, public, default branch `main` | done |
| GitHub access | Fine-grained token scoped to `Roehens` (Contents, Workflows, Actions, Secrets read/write). Held by the owner and the build agent; not recorded here | done |
| Commit identity | `helpfavourv1` / `314438714+helpfavourv1@users.noreply.github.com` | done |
| Support email | stmakarios@gmail.com | done |
| Flutter toolchain gate | Flutter 3.47.6, Dart 3.13.5, `flutter analyze` clean on a blank app, verified on the owner's phone (Linux arm64, proot Ubuntu) | done |
| Android upload keystore | Generated; PKCS12; alias `roehens` (lowercase); valid until 2054-02-18; SHA-256 `3C:24:73:8E:42:56:22:A0:A1:70:6F:F8:37:CD:88:80:22:32:BA:D8:A2:C2:80:63:5A:42:D5:E6:A2:89:21:D1` | done |
| GitHub secrets (signing) | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | set in GitHub (2026-10-03) |
| GitHub secrets (spike streams) | `SPIKE_RTSP_URL`, `SPIKE_MJPEG_URL`. Values held by the owner. RTSP: H.265/HEVC Main, 2592x1944, 25 fps, PCM mu-law audio. MJPEG: `multipart/x-mixed-replace` | needed before checkpoint CP1 |
| Cheapest Android test device | Model code `25028RN03A`, Android 15, about 3.7 GiB RAM | done |
| iPhone/iPad test device | none stated yet | open |
| AdMob | Google's published sample (test) App IDs and banner units until real units exist. Android sample IDs confirmed against Google's documentation; iOS sample IDs to be confirmed against Google's live page in batch P2F | in progress |
| IAP product ID (ad-free) | `com.zdmgold.roehens.adfree` (non-consumable) | not yet created in a store |
| Apple Multicast Networking entitlement | Request to be filed by the owner; build flag `IOS_DISCOVERY_MODE=subnet_sweep_only` until granted | open |
| Public-IP lookup service | Chosen at batch PH1 and recorded in `DECISIONS.md` | open |
| Play Console app, Play App Signing | Not needed until release | open |
| App Store Connect app, Apple Team ID, API key | Not needed until the iOS checkpoint | open |
| Static hosting (Cloudflare) | Owner connects the repo after the website files exist (P7C) and supplies the URLs | open |
| Codemagic project | Created before the first iOS checkpoint | open |
| Privacy policy URL / Support URL / Flags JSON URL | After hosting is connected | open |
| Owner artwork (one master) | Due before P7C | open |
| Reviewer test stream (Apple 2.1) | Deferred. Release blocker for App Store submission | open |
