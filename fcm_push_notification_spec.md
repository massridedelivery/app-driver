# FCM Push Notification Spec — Driver App

The contract the **backend** must follow to alert drivers of new jobs while the
app is **backgrounded or terminated** (foreground offers already arrive over the
WebSocket). Tracked in SCRUM-55.

The app is a **wake-and-route** receiver: the push wakes the driver and routes to
a screen; the screen then loads the actual job over the existing socket/REST
channels. **No job data is carried in the push.**

## Device token

The app registers the FCM token on startup (and on refresh) via:

```
POST /api/notifications/register-device
{ "token": "<fcm-token>", "platform": "ios" | "android" }
```

The backend stores the latest token per driver and sends to it on job assignment.

## Message shape (FCM HTTP v1)

```json
{
  "message": {
    "token": "<driver-fcm-token>",
    "notification": {
      "title": "งานเข้าใหม่",
      "body": "มีงานใหม่รอคุณอยู่ แตะเพื่อดูรายละเอียด"
    },
    "data": { "route": "/incoming-job" },
    "android": {
      "priority": "high",
      "notification": { "channel_id": "job_offer_channel_v2" }
    },
    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": { "aps": { "sound": "job_alert.caf" } }
    }
  }
}
```

## Rules the app enforces

- **Must** include the `notification` block (title + body). A data-only message
  can arrive silently or be throttled — the driver misses the job.
- **Loud alert:** to ring with the custom Grab/LineMan-style sound:
  - **Android:** `android.notification.channel_id` **must** be
    `job_offer_channel_v2` (a dedicated channel the app creates: custom sound
    `job_alert`, importance MAX, `USAGE_ALARM`). Using `high_importance_channel`
    (or omitting it) rings the **default** sound.
  - **iOS:** `apns.payload.aps.sound` **must** be `job_alert.caf` (bundled in the
    app). `default` rings the default sound.
- `data.route` is the **only** data key the app reads. Must be a String starting
  with `/`. Unknown routes fall back to `/home`.

### Allowed `route` values

| Purpose | route |
| --- | --- |
| New incoming job / offer | `/incoming-job` |
| Active ride/delivery live | `/job-live` |
| Active food order | `/food-live` |
| Messenger offer | `/messenger-offer` |
| Messenger live | `/messenger-live` |
| Home (fallback) | `/home` |

## App-side references

- `lib/core/services/push_notification_service.dart` — channels + handlers.
- `android/app/src/main/res/raw/job_alert.wav` — Android custom sound.
- `ios/Runner/job_alert.caf` — iOS custom sound (bundled in the Runner target).
- Channel id `job_offer_channel_v2` is versioned: a channel's sound is immutable
  once created, so bump `_vN` when the sound file changes.

## Troubleshooting: token registers fine, but nothing arrives

Don't debug delivery with the Firebase console's "send test message" — it
reports success whether or not APNs accepted the message, so an iOS rejection
looks identical to a delivered push nobody saw. Send through the HTTP v1 API
instead, which returns the real error:

```
tools/fcm_test_push.sh <credential> <fcm-token> plain
```

(`plain` isolates "does push work at all"; `job` exercises the loud job-offer
payload. The script header documents the credential options — note the org
policy blocks service-account key creation, so use a `gcloud auth
print-access-token` value, e.g. from Cloud Shell.)

Grab the FCM token from the in-app **Settings → นักพัฒนา → FCM Debug Log**
screen, which also shows the whole registration story (permission → APNs
token → FCM token → backend registration).

| v1 API error | Meaning | Where to look |
| --- | --- | --- |
| `THIRD_PARTY_AUTH_ERROR` / `InvalidProviderToken` | APNs rejected Firebase's auth key | See below — this is the big one |
| `UNREGISTERED` | Token is dead (app reinstalled/cleared) | Refresh the token in FCM Debug Log |
| `SENDER_ID_MISMATCH` | Token belongs to another Firebase project | App built against the wrong config/*.json |
| `INVALID_ARGUMENT` | Malformed payload | The `detail` field names the offending key |
| 200 + nothing shows | Delivered to APNs; dropped on-device | Focus mode, notification summary, per-app settings |

### `InvalidProviderToken` (hit 2026-08-13, dev)

Everything client-side can be correct — bundle id, team id, entitlements,
capabilities, APNs token obtained, backend registration OK — and iOS still
gets nothing, because this failure happens between Firebase and Apple. Android
is unaffected (it never touches APNs), which is exactly the confusing
"Android works, iOS silent" symptom.

The console listing a key under Cloud Messaging → Apple app configuration
proves only that a file was uploaded; Firebase never validates it against
Apple. In particular the team has two APNs keys created the same day (Driver
`37DK9D46T6`, Customer `2Q72LZL55C`) — uploading one key's `.p8` with the
other's Key ID typed in produces exactly this error.

Checklist, in order:

1. Apple Developer portal → Keys: the Key ID exists, isn't revoked, lists
   APNs in services, and the portal's team matches the Team ID typed into
   Firebase.
2. Find the original `AuthKey_<KeyID>.p8` and confirm its filename matches
   the Key ID entered in Firebase. Delete + re-upload if unsure.
3. No original file → revoke and create a new key. Apple caps a team at
   **two** APNs auth keys, so the old one must be revoked first — and every
   Firebase project using it (prod too) must get the replacement.
4. Re-run the test send: success looks like
   `{"name": "projects/<project>/messages/<id>"}` plus a notification on the
   device.

## Out of scope

Carrying full job details in the push (e.g. `job_id`) — the app ignores extra
data keys today and would need an app-side change first.
