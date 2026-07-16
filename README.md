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

Two kinds of file, layered together: a **backend** file (env + API URL) and an
**app-identity** file (name, package, Firebase/Omise keys).

Backend files:

- `config/dev.json` — dev backend (the backend URL/env also has a compiled-in default)
- `config/preprod.json` — pre-prod backend
- `config/prod.json` — prod backend — ⚠️ `API_BASE_URL` is a `REPLACE_ME_…` placeholder; fill in the real URL before any prod build

App-identity files (pick the one matching the target):

- `config/mass_dev.json` — dev/pre-prod app identity + Firebase/Omise keys (`APP_PACKAGE_NAME_SUFFIX` is `.dev`)
- `config/mass_prod.json` — prod app identity — ⚠️ Firebase/Omise values are `REPLACE_ME_…` placeholders (separate prod Firebase project + Omise **live** key); fill them in before any prod build

### Android application id

The Android `applicationId` is derived at build time from `APP_PACKAGE_NAME` +
`APP_PACKAGE_NAME_SUFFIX` (decoded from the dart-defines in
`android/app/build.gradle.kts`), so it tracks the app-identity file:

- dev / pre-prod (`mass_dev.json`, suffix `.dev`) → **`com.massapp.massdrive.dev`**
- prod (`mass_prod.json`, no suffix) → **`com.massapp.massdrive`**

This lets a dev and a prod build coexist on one device. The Gradle `namespace`
stays `com.massapp.massdrive` (it's the compiled R-class package, not the
installed id). iOS bundle-id separation is not wired yet — it needs Xcode
scheme/xcconfig work and is a follow-up.

> ⚠️ **CI / Play impact:** `deploy-play.yml` builds with `preprod.json` +
> `mass_dev.json`, which now produces `com.massapp.massdrive.dev`. A Play
> Console listing for that id must exist, or the deploy config must be pointed
> at a prod identity file, before the next upload — otherwise the upload
> targets an app id that isn't registered.

> The `REPLACE_ME_…` placeholders are non-empty on purpose so `assertConfigured()`
> still passes and the structure builds, but they are **not** real credentials —
> a prod build with them left in will boot yet fail against Firebase/Omise.

Pass both the backend file and the matching app-identity file — the second file supplies the
Firebase/Omise config that `lib/firebase_options.dart` and the payment code
read. `EnvironmentConfig.assertConfigured()` runs at boot and throws if any of
those defines are missing, so a build without `mass_dev.json` fails fast with a
clear message rather than breaking later inside Firebase. This means plain
`flutter run` (no `--dart-define-from-file`) will not boot — always pass both
files.

```sh
# Run against dev
flutter run --dart-define-from-file=config/dev.json --dart-define-from-file=config/mass_dev.json

# Run against pre-prod
flutter run --dart-define-from-file=config/preprod.json --dart-define-from-file=config/mass_dev.json

# Run against prod (once the placeholders in config/prod.json + config/mass_prod.json are filled in)
flutter run --dart-define-from-file=config/prod.json --dart-define-from-file=config/mass_prod.json
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
   main            (no auto-deploy for now)
     │
     ▼ manual: Actions tab → Run workflow
  [deploy-play.yml]  build SIGNED AAB ─▶ Play internal track
```

| Git event | Workflow | What happens |
| --- | --- | --- |
| Push to any non-`main` branch (feature, `develop`) | `ci.yml` | `flutter analyze` → `flutter test` → release AAB build (verify) |
| PR targeting `main` | `ci.yml` | same checks, as the pre-merge gate |
| **Manual** (Actions tab → Run workflow) | `deploy-play.yml` | build **signed** AAB → upload to Play **internal** track |

> **Auto-deploy on push to `main` is temporarily disabled** — `deploy-play.yml`
> runs by manual `workflow_dispatch` only, until the Play secrets and the first
> manual Play Console upload are in place. Re-enable by restoring the
> `push: branches: [main]` trigger in the workflow.
>
> PRs into `develop` are covered by the branch-push trigger (CI runs on the
> feature branch's pushes); the `pull_request` trigger fires specifically for PRs
> into `main`.

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

After that, run **`deploy-play.yml`** manually (Actions tab → Run workflow) to
publish to internal testing. Once it's proven out, re-enable the `push: [main]`
trigger to make merges to `main` deploy automatically.
