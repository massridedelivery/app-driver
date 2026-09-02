# Google Play deploy pipeline (Android)

The Android equivalent of the iOS TestFlight flow. `make deploy_play_prod_devapi`
bumps the build number, builds a signed **prod-devapi** AAB, and uploads it to
the **internal testing** track via fastlane `supply`.

```
make deploy_play_prod_devapi   # bump + build AAB + upload to Play internal track
make build_aab_prod_devapi     # just build the AAB (no bump, no upload)
make upload_play_prod_devapi   # upload an already-built AAB (no bump, no build)
make deploy_play_check         # verify the service-account JSON only (no upload)
```

- **prod-devapi** = prod package `com.massapp.massdrive` (app label "Driver")
  built on the **dev API**, via
  `--dart-define-from-file=config/prod_devapi.json --dart-define-from-file=config/mass_prod_devapi.json`.
- Driver has **no Flutter flavors** — everything is dart-define config. So the
  AAB lands at `build/app/outputs/bundle/release/app-release.aab` (no flavor
  subdir).
- The Play app **"Mass Driver"** (`com.massapp.massdrive`) already exists in the
  Play Console (draft). We only ship the binary; store listing / screenshots /
  changelog stay managed in the console.

The gradle signing config (`android/app/build.gradle.kts`) and the `.gitignore`
for secrets are already in place. What's left is **one-time setup** with two
secrets that only you can create. Neither is committed.

---

## What is already done (in this repo)

- `android/app/build.gradle.kts` — release `signingConfig` reads
  `android/key.properties`; falls back to debug keys when it's absent.
- `android/fastlane/Appfile` + `Fastfile` — `deploy` and `whoami` lanes.
- `android/Gemfile` (+ `Gemfile.lock`) — fastlane.
- `Makefile` — `bump`, `build_aab_prod_devapi`, `upload_play_prod_devapi`,
  `deploy_play_prod_devapi`, `deploy_play_check`.
- `android/.gitignore` — ignores `key.properties`, `**/*.jks`,
  `fastlane/play-service-account.json`, fastlane artifacts, `vendor/bundle`.
- `android/key.properties.example` — template.

## What you need to provide (one-time)

### 1. Upload keystore + `key.properties`

The upload keystore already exists: `mass-driver-keystore.jks` (alias
`mass-drive`), registered with Play App Signing for `com.massapp.massdrive`.
Create `android/key.properties` from the template and point `storeFile` at it:

```bash
cp android/key.properties.example android/key.properties
# then edit android/key.properties:
#   storeFile=/absolute/path/to/mass-driver-keystore.jks
#   keyAlias=mass-drive
#   storePassword=…  keyPassword=…
```

Confirm the alias and that this is the **upload** cert Play expects:

```bash
keytool -list -v -keystore <path>/mass-driver-keystore.jks -storepass <pw> | grep "Alias name"
keytool -list -v -keystore <path>/mass-driver-keystore.jks -storepass <pw> | grep "SHA1:"
```

The `SHA1:` must match the **upload key** certificate shown in Play Console →
Setup → App signing for `com.massapp.massdrive`.

### 2. Play service-account JSON

Fastlane authenticates to Google Play with a service account (not your login).

1. In the Google Cloud project behind the service account, enable the
   **Google Play Android Developer API** (`androidpublisher.googleapis.com`).
2. In **Play Console → Users and permissions**, invite the service account
   email and grant it **Admin (or release to testing tracks)** on the app
   `com.massapp.massdrive`.
3. Download the SA key JSON and save it as
   `android/fastlane/play-service-account.json` (gitignored).

> There is an existing SA `play-upload@prod-mass-project` used for the customer
> app — you can reuse it: just grant it permission on `com.massapp.massdrive`
> in Play Console too. A **SA mismatch** (JSON is not the SA that has Release
> permission) surfaces as `caller does not have permission`.

### 3. Install the fastlane gem (once)

```bash
cd android && RBENV_VERSION=3.3.5 bundle install
```

Every fastlane command needs the `RBENV_VERSION=3.3.5` prefix — fastlane lives
in Ruby 3.3.5.

---

## Verify + deploy

```bash
make deploy_play_check           # green ✓ = SA JSON authenticates for the package
make deploy_play_prod_devapi     # bump + build signed AAB + upload to internal track
```

Then in Play Console → Testing → Internal testing, the new build appears; add
testers / roll it out from there.

## Notes

- `bump` increments the `+N` in `pubspec.yaml` (= Android `versionCode`). Play
  rejects a versionCode that isn't strictly higher than a previous upload.
- iOS is unaffected by `bump`: `ios/ExportOptions.plist` sets
  `manageAppVersionAndBuildNumber`, so TestFlight build numbers auto-stamp.
- Never commit `key.properties`, the `.jks`, or `play-service-account.json`.
