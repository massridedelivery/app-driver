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
