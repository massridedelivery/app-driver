# Permissions & Store Compliance — Driver app

Audit of every permission the **Driver** app declares/uses, mapped to a feature,
with the timing of the request and what to fill in on each store. Keep this in
sync whenever a permission is added/removed.

> **Principle:** request only what a feature needs, request it **in-context**
> (never at cold launch), and declare on the stores exactly what is requested.

_Last audited: 2026-08-21 · app version `1.0.0+12`._

## TL;DR

- **Location = When-In-Use / foreground only.** No background location, no
  "Always". The driver's position is streamed only while the app is open and
  the driver is online. → **Not** subject to Google Play's background-location
  declaration or Apple's Always justification.
- **No foreground service.** Location tracking stops when the app is
  backgrounded (by design). If continuous background tracking is ever required,
  it must be added deliberately (see "If background location becomes required").
- **No microphone / contacts / calendar / storage** permissions. Calls use
  `tel:` links; media uses the OS photo picker + camera.

## Permission map

| Permission | Feature | Required | Requested when |
|---|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` | API calls, connectivity monitor | ✅ | n/a (normal) |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (Android) · `NSLocationWhenInUseUsageDescription` (iOS) | Navigate to pickup/drop-off, receive nearby jobs, stream position while online | ✅ | On the home map / when going **online** (`LocationService.startLocationUpdates` → `Geolocator.requestPermission`) |
| `POST_NOTIFICATIONS` (Android 13+) · iOS notification authorization | Job-offer & status push | ✅ | **After login** — `PushTokenRegistrar` is gated on `SessionNotifier.isAuthenticated`, then requests before registering the FCM token |
| `NSCameraUsageDescription` (iOS) · camera via `image_picker` | KYC docs, profile photo, chat photo | ✅ | On tapping "take photo" (in-context) |
| `NSPhotoLibraryUsageDescription` (iOS) · gallery via `image_picker` | KYC docs, profile photo, slip upload, chat | ✅ | On tapping "choose from gallery". Android 13+ uses the system **Photo Picker** (no media permission). |
| `WAKE_LOCK`, `VIBRATE`, `com.google.android.c2dm.permission.RECEIVE` | Injected by Firebase Messaging (push wake/vibrate) | ✅ (normal) | n/a |

### Explicitly NOT declared / used
`ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE*`, `RECORD_AUDIO`,
`READ_CONTACTS`, `READ/WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_*`,
`NSLocationAlwaysAndWhenInUseUsageDescription` (removed — background not used).

## In-context request flow

```
launch (logged out) → request nothing
  ↓ login
POST_NOTIFICATIONS → requested when the FCM token registers (post-auth)
  ↓ open home map / go online
LOCATION (when-in-use) → requested by LocationService
  ↓ KYC / profile / chat photo
CAMERA / PHOTOS → requested on the specific action
```

`denied` → the feature no-ops and can be retried. On `deniedForever`, going online opens a dialog that routes the driver to
Settings via `Geolocator.openAppSettings()` (and `openLocationSettings()` when
GPS itself is off).

## iOS — App Store

`ios/Runner/Info.plist`:

- `NSLocationWhenInUseUsageDescription` — "ใช้ตำแหน่งของคุณเพื่อนำทางไปยังจุดรับ-ส่ง
  และรับงานที่อยู่ใกล้คุณ ขณะที่เปิดใช้งานแอป"
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` — specific Thai strings (present).
- `UIBackgroundModes = [remote-notification, fetch]` — for FCM. **No `location`**
  background mode (foreground-only tracking).

**App Privacy labels** (App Store Connect → App Privacy):

| Data type | Collected | Linked to user | Purpose |
|---|---|---|---|
| Precise Location | Yes | Yes | App Functionality (matching, navigation) |
| Photos | Yes | Yes | App Functionality (KYC / verification) |
| Identifiers (FCM token) | Yes | Yes | App Functionality (push) |

Guideline **5.1.1**: all prompts are in-context — do not move them to launch.

## Android — Google Play

`android/app/src/main/AndroidManifest.xml` declares only the permissions in the
map above. The merged manifest was verified (`aapt dump permissions` on the
release APK): **no** `ACCESS_BACKGROUND_LOCATION`, **no** `FOREGROUND_SERVICE*`.

**Data safety form:**

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Location (precise) | Yes | No | App functionality |
| Photos | Yes | No | App functionality (KYC) |
| Device IDs (FCM token) | Yes | No | App functionality (push) |

- **No** Location Permissions Declaration needed (foreground-only).
- **No** Foreground Service form needed.
- Android 13+: `POST_NOTIFICATIONS` runtime prompt (post-login); media uses the
  Photo Picker.

## If background location becomes required

Only if the product must stream position while the app is backgrounded:

1. Add `ACCESS_BACKGROUND_LOCATION` + a `foregroundServiceType="location"`
   service + `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION`.
2. Re-add `NSLocationAlwaysAndWhenInUseUsageDescription` + `UIBackgroundModes:
   location`, and request "Always" **only after** When-In-Use is granted, behind
   a prominent in-app disclosure.
3. Google Play: submit the **Location Permissions Declaration** (often a demo
   video) + the **Foreground Service** declaration.
4. Apple: justify background location and show the location indicator.

Until then, keep it foreground-only — it's the simplest path to approval.
