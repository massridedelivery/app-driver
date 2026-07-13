# massdrive

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environments

Runtime configuration is injected at build time via `--dart-define-from-file`
(see `lib/core/configs/environment_config.dart`). Config files live in `config/`:

- `config/dev.json` — dev backend (also the compiled-in default, so plain `flutter run` uses dev)
- `config/preprod.json` — pre-prod backend

```sh
# Run against dev
flutter run --dart-define-from-file=config/dev.json

# Run against pre-prod
flutter run --dart-define-from-file=config/preprod.json
```

## Release build (Google Play)

Release builds are signed with the upload keystore configured in
`android/key.properties` (not committed — ask the team for the keystore,
or see https://docs.flutter.dev/deployment/android#sign-the-app).

```sh
# Bump the build number (+N) in pubspec.yaml first — Play rejects duplicate versionCodes.
flutter build appbundle --release --dart-define-from-file=config/preprod.json
# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to Play Console → Testing → Internal testing.

## CI/CD (GitHub Actions)

Two workflows live in `.github/workflows/`:

- **`ci.yml`** — runs on every PR to `main` and on branch pushes: `flutter analyze`
  (errors only for now), `flutter test`, and a release app-bundle build to verify
  it compiles. No secrets needed (falls back to debug signing).
- **`deploy-play.yml`** — runs on push to `main` (or manual dispatch): builds a
  **signed** bundle from `config/preprod.json` and uploads it to the Play
  **internal** testing track. The `versionCode` is set from the workflow run
  number, so uploads never collide.

### Required repository secrets

Set these under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i mass-driver-keystore.jks` output |
| `ANDROID_KEYSTORE_PASSWORD` | keystore/key password (same value — PKCS12) |
| `ANDROID_KEY_ALIAS` | key alias (`mass-drive`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | full JSON of a Play service account with "Release to testing tracks" permission |

### One-time setup before CD works

1. Create the app in Play Console and upload one bundle manually (Play requires
   the first release for a package to go through the UI).
2. Create a Google Cloud service account, grant it access in Play Console
   (Users & permissions), and download its JSON key → `PLAY_SERVICE_ACCOUNT_JSON`.
3. Add the four secrets above.

After that, merging to `main` publishes to internal testing automatically.
