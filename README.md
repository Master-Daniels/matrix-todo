# Matrix Todo

A simple offline-first todo app built with Flutter (Android + iOS + desktop from one codebase).

Tasks with subtasks, lists, reminders, recurrence, and local notifications. Data stays on-device (SQLite).

- App ID: `com.masterdaniels.matrixtodo`
- Current version: `0.0.1+1` (`pubspec.yaml`)
- License: Apache-2.0 (see `LICENSE`)

## Install from GitHub Releases (Android)

No Play Store upload. Each `v*` tag builds signed APKs via GitHub Actions (`.github/workflows/release.yml`).

1. Open the repo's **Releases** page.
2. Download the APK for your ABI — `arm64-v8a` for most modern phones (`armeabi-v7a` for old 32-bit, `x86_64` for emulators).
3. Open the file on the phone, allow "Install unknown apps" when prompted.

APKs are signed with the maintainer's release key (see `android/key.properties`), so they are trusted by Android.

Checksums: each release ships `SHA256SUMS.txt` — verify with `sha256sum -c SHA256SUMS.txt`.

> iOS: no binary is attached (no paid Apple Developer account, so no App Store / TestFlight). Run from source on a Mac (below).

## Run from source

Requirements: Flutter stable (tested with 3.44.4, Dart 3.12.2), Java 17 for Android builds, Xcode on Mac for iOS.

```sh
flutter pub get
flutter analyze
flutter test
flutter run          # debug on attached device / emulator
```

Platform notes:

- Android: `flutter run` works without secrets (debug keys). Release needs `android/key.properties` (below). Notifications need runtime permission on Android 13+; exact alarms fall back to inexact when denied.
- iOS: open `ios/Runner.xcworkspace` once to let Xcode resolve signing with your free Apple ID, then `flutter run`. Bundle ID is `com.masterdaniels.matrixtodo`, display name `Matrix Todo`.
- Windows/Linux/macOS: `flutter run -d windows|linux|macos`.

## Releasing a new version

1. Bump `version: X.Y.Z+N` in `pubspec.yaml` (`X.Y.Z` = versionName, `N` = versionCode/build number, increment `N` every release).
2. Commit, then tag exactly matching the version name:
   ```sh
   git tag v0.0.1
   git push origin main v0.0.1
   ```
   The workflow fails if the tag does not match `pubspec.yaml` (e.g. tag `v0.0.1` requires `version: 0.0.1+...`).
3. GitHub Actions runs `analyze + test + flutter build apk --release --split-per-abi`, then publishes the APKs + `SHA256SUMS.txt` to the GitHub Release.

## Release signing (maintainer)

Local files (git-ignored, never commit):

- `android/app/matrix-todo.jks` — release keystore, alias `matrix`, PKCS12, validity 25 years. **Back it up offline now** (password manager + USB). Losing it means a new app ID for updates.
- `android/key.properties`:
  ```
  storeFile=matrix-todo.jks
  storePassword=<same-as-keyPassword>
  keyAlias=matrix
  keyPassword=<storePassword>
  ```
  (PKCS12 stores ignore a separate key password, so both passwords are identical.)

`android/app/build.gradle.kts` uses this file when present, `KEYSTORE_FILE/KEYSTORE_PASSWORD/KEY_ALIAS/KEY_PASSWORD` env vars on CI, and debug keys otherwise — so contributors can still `flutter run --release` without secrets.

### GitHub Secrets (repo Settings → Secrets and variables → Actions)

Create once from the machine holding the keystore:

```powershell
# PowerShell (Windows)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/matrix-todo.jks")) | Set-Content keystore.b64
# then paste keystore.b64 into KEYSTORE_BASE64
```

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | base64 of `android/app/matrix-todo.jks` |
| `KEYSTORE_PASSWORD` | value of `storePassword` in `android/key.properties` |
| `KEY_ALIAS` | `matrix` |
| `KEY_PASSWORD` | same as `KEYSTORE_PASSWORD` |

To rotate/inspect locally: `keytool -list -v -keystore android/app/matrix-todo.jks`.

## Fonts (OFL attribution)

Bundled offline in `assets/fonts/` (see that folder's `README.md`), used via `pubspec.yaml` `fonts:` block — no runtime fetching:

- Megrim (Sorkin Type Co.), OFL 1.1 — `ofl/megrim`
- Space Mono Regular + Bold (Colophon Foundry / Google Fonts), OFL 1.1 — `ofl/spacemono`
- Space Grotesk Regular + Medium + Bold (Florian Karsten / Google Fonts), OFL 1.1 — `ofl/spacegrotesk`

All under the SIL Open Font License 1.1 (https://openfontlicense.org). Upstream copies: https://github.com/google/fonts/tree/main/ofl (`megrim/OFL.txt`, `spacemono/OFL.txt`, `spacegrotesk/OFL.txt`). Keep copyright notices + OFL text when redistributing the `.ttf` files.

App code itself is Apache-2.0 — font OFL terms apply only to the font files.

## Project layout

- `lib/main.dart` — entry, settings preload + reminder warmup
- `lib/src/data/` — SQLite (`app_database.dart`), models, recurrence
- `lib/src/notifications/` — local notifications + reminder scheduling
- `lib/src/pages/` — home deck, lists, add-task sheet, upcoming, settings/stats
- `lib/src/theme/`, `lib/src/widgets/` — theme, typography, reusable cells
- `android/`, `ios/`, `linux/`, `macos/`, `windows/` — platform shells (IDs/names already branded to Matrix Todo)
