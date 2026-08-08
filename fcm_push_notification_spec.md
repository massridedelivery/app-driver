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
      "notification": { "channel_id": "job_offer_channel_v1" }
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
    `job_offer_channel_v1` (a dedicated channel the app creates: custom sound
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
- Channel id `job_offer_channel_v1` is versioned: a channel's sound is immutable
  once created, so bump `_vN` when the sound file changes.

## Out of scope

Carrying full job details in the push (e.g. `job_id`) — the app ignores extra
data keys today and would need an app-side change first.
