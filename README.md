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

## Local setup

`.env` is required for any build. It's a pubspec asset (holds the Directions
API key) but is gitignored, so it's absent on a fresh checkout — without it the
asset bundle fails to build (`Failed to bundle asset files`). Create it before
building; an empty file is enough for analyze/test/build (the key falls back to
`''`), and a real key is only needed for live Directions API calls:

```sh
touch .env
```

CI does the same in its `Create placeholder .env` step.

## Environments

Runtime configuration is injected at build time via `--dart-define-from-file`
(see `lib/core/configs/environment_config.dart`). Config files live in `config/`:

- `config/dev.json` — dev backend (also the compiled-in default, so plain `flutter run` uses dev)
- `config/preprod.json` — pre-prod backend
- `config/mass_dev.json` — app identity + Firebase/Omise keys (shared; layered on top of the backend file)

Pass both the backend file and `mass_dev.json` — the second file supplies the
Firebase config that `lib/firebase_options.dart` reads, so Firebase won't
initialize without it.

```sh
# Run against dev
flutter run --dart-define-from-file=config/dev.json --dart-define-from-file=config/mass_dev.json

# Run against pre-prod
flutter run --dart-define-from-file=config/preprod.json --dart-define-from-file=config/mass_dev.json
```

## Release build (Google Play)

Release builds are signed with the upload keystore configured in
`android/key.properties` (not committed — ask the team for the keystore,
or see https://docs.flutter.dev/deployment/android#sign-the-app).

```sh
# Bump the build number (+N) in pubspec.yaml first — Play rejects duplicate versionCodes.
flutter build appbundle --release --dart-define-from-file=config/preprod.json --dart-define-from-file=config/mass_dev.json
# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to Play Console → Testing → Internal testing.

## CI/CD (GitHub Actions)

Two workflows live in `.github/workflows/`: `ci.yml` verifies every change, and
`deploy-play.yml` ships to Play once a change reaches `main`.

### When each runs (flow)

```
feature branch ──push──▶ [ci.yml]  analyze · test · build release AAB (verify)
     │
     ▼ PR + merge
  develop ──────push──▶ [ci.yml]  (same checks)
     │
     ▼ PR to main ────▶ [ci.yml]  (same checks — the merge gate)
     │
     ▼ merge to main
   main ─────push─────▶ [deploy-play.yml]  build SIGNED AAB ─▶ Play internal track
```

| Git event | Workflow | What happens |
| --- | --- | --- |
| Push to any non-`main` branch (feature, `develop`) | `ci.yml` | `flutter analyze` → `flutter test` → release AAB build (verify) |
| PR targeting `main` | `ci.yml` | same checks, as the pre-merge gate |
| Merge / push to `main` | `deploy-play.yml` | build **signed** AAB → upload to Play **internal** track |
| Manual (Actions tab → Run workflow) | `deploy-play.yml` | same, via `workflow_dispatch` |

> PRs into `develop` are covered by the branch-push trigger (CI runs on the
> feature branch's pushes); the `pull_request` trigger fires specifically for PRs
> into `main`. Nothing runs on `main` except the deploy.

### Workflows

- **`ci.yml`** — `flutter analyze` (errors only for now), `flutter test`, and a
  **release app-bundle** build to verify it compiles the same way the deploy does.
  No secrets needed — `android/app/build.gradle.kts` falls back to debug signing.
- **`deploy-play.yml`** — builds a **signed** bundle from `config/preprod.json`
  (+ `config/mass_dev.json`) and uploads it to the Play **internal** testing
  track. The `versionCode` is set from the workflow run number, so uploads never
  collide.

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
