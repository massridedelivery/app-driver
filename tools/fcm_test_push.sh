#!/usr/bin/env bash
# Send one FCM push and print exactly what Google says back.
#
# The Firebase console's "send test message" swallows APNs rejections — it
# reports success whether or not the push reached the device, which makes an
# iOS delivery failure indistinguishable from a silent drop. The HTTP v1 API
# returns the real error, so this is the tool to reach for when a token
# registers fine but nothing arrives.
#
# Needs only bash, curl and openssl — no gcloud, no pip installs.
#
# Usage:
#   tools/fcm_test_push.sh <credential> <fcm-token> [job|plain]
#
# <credential> is whichever of these you can actually get:
#   path/to/sa.json  a service account key (Firebase console -> Project
#                    settings -> Service accounts -> Generate new private key).
#                    Blocked on projects whose org disables key creation.
#   ya29.xxx         an OAuth access token, pasted directly. Get one without
#                    any key via `gcloud auth print-access-token`, including
#                    from Cloud Shell (shell.cloud.google.com) where gcloud is
#                    installed and already signed in as you.
#   gcloud           run `gcloud auth print-access-token` here.
#
# The project defaults to the dev one; override with FCM_PROJECT=... for another.
#
#   job    payload matching fcm_push_notification_spec.md (loud job-offer
#          channel + job_alert sound + /incoming-job route) — use this to test
#          what a real job offer does
#   plain  minimal notification, default sound (the default) — use this first
#          to separate "push doesn't work at all" from "the job payload is off"
#
# A service account key is a credential: keep it out of the repo (tools/*.json
# is gitignored) and delete it when done. Access tokens expire in an hour.
set -euo pipefail

CRED=${1:-}
FCM_TOKEN=${2:-}
MODE=${3:-plain}
PROJECT_ID=${FCM_PROJECT:-dev-driver-43965}

if [ -z "$CRED" ] || [ -z "$FCM_TOKEN" ]; then
  sed -n '3,26p' "$0" | sed 's/^# \{0,1\}//'
  exit 64
fi

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# --- get an access token ------------------------------------------------------
if [ "$CRED" = "gcloud" ]; then
  command -v gcloud >/dev/null \
    || { echo "gcloud is not installed. Use Cloud Shell (shell.cloud.google.com) and pass the ya29.* token it prints." >&2; exit 69; }
  ACCESS_TOKEN=$(gcloud auth print-access-token)

elif [ -f "$CRED" ]; then
  # Service account key: sign a JWT and exchange it (RFC 7523 bearer flow).
  json_get() { python -c "import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])" "$1" "$2"; }
  CLIENT_EMAIL=$(json_get "$CRED" client_email)
  PROJECT_ID=$(json_get "$CRED" project_id)

  NOW=$(date +%s)
  HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
  CLAIM=$(printf '{"iss":"%s","scope":"https://www.googleapis.com/auth/firebase.messaging","aud":"https://oauth2.googleapis.com/token","iat":%s,"exp":%s}' \
    "$CLIENT_EMAIL" "$NOW" "$((NOW + 3600))" | b64url)

  PRIV=$(mktemp); trap 'rm -f "$PRIV"' EXIT
  python -c "import json,sys;sys.stdout.write(json.load(open(sys.argv[1]))['private_key'])" "$CRED" > "$PRIV"
  SIG=$(printf '%s.%s' "$HEADER" "$CLAIM" | openssl dgst -sha256 -sign "$PRIV" -binary | b64url)

  ACCESS_TOKEN=$(curl -s -X POST https://oauth2.googleapis.com/token \
    -d grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer \
    -d "assertion=$HEADER.$CLAIM.$SIG" \
    | python -c "import json,sys;d=json.load(sys.stdin);print(d.get('access_token') or 'ERROR: '+json.dumps(d))")

  case "$ACCESS_TOKEN" in
    ERROR*) echo "Could not get an access token — $ACCESS_TOKEN" >&2; exit 77 ;;
  esac

elif [ "${CRED#ya29.}" != "$CRED" ]; then
  ACCESS_TOKEN=$CRED

else
  echo "Don't know how to use '$CRED' as a credential." >&2
  echo "Expected a readable .json key path, a ya29.* access token, or 'gcloud'." >&2
  case "$CRED" in
    *@*.iam.gserviceaccount.com)
      echo "That looks like a service account's address — the script needs its key file, not its name." >&2 ;;
  esac
  exit 66
fi

# --- build the message --------------------------------------------------------
if [ "$MODE" = "job" ]; then
  APNS='{"headers":{"apns-priority":"10"},"payload":{"aps":{"sound":"job_alert.caf"}}}'
  ANDROID='{"priority":"high","notification":{"channel_id":"job_offer_channel_v1"}}'
  DATA='{"route":"/incoming-job"}'
  TITLE='งานเข้าใหม่'; BODY='มีงานใหม่รอคุณอยู่ แตะเพื่อดูรายละเอียด'
else
  APNS='{"headers":{"apns-priority":"10"},"payload":{"aps":{"sound":"default"}}}'
  ANDROID='{"priority":"high"}'
  DATA='{}'
  TITLE='test'; BODY='plain push test'
fi

BODY_JSON=$(python -c "
import json,sys
token,title,body,apns,android,data = sys.argv[1:7]
print(json.dumps({'message':{
  'token':token,
  'notification':{'title':title,'body':body},
  'data':json.loads(data),
  'android':json.loads(android),
  'apns':json.loads(apns),
}}))" "$FCM_TOKEN" "$TITLE" "$BODY" "$APNS" "$ANDROID" "$DATA")

# --- send ---------------------------------------------------------------------
echo "project : $PROJECT_ID"
echo "mode    : $MODE"
echo "token   : ${FCM_TOKEN:0:24}..."
echo
RESP=$(curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY_JSON" \
  "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send")

CODE=$(printf '%s' "$RESP" | tail -1)
printf '%s' "$RESP" | sed '$d' | python -m json.tool 2>/dev/null || printf '%s\n' "$RESP"
echo
echo "HTTP $CODE"

# --- translate the outcome ----------------------------------------------------
case "$CODE" in
  200) cat <<'EOF'

Accepted by FCM. If nothing shows on the device, the push was handed to APNs
and dropped after that — look at the device (Focus mode, notification summary,
per-app notification settings) rather than at the server config.
EOF
  ;;
  *) cat <<'EOF'

Read the "status"/"errorCode" above:
  THIRD_PARTY_AUTH_ERROR  APNs rejected the credentials — wrong/revoked .p8, a
                          key from another team, or the App ID has no Push
                          Notifications capability.
  UNREGISTERED            The token is dead. Reinstall and grab a fresh one.
  SENDER_ID_MISMATCH      Token belongs to a different Firebase project.
  INVALID_ARGUMENT        Malformed payload — the detail field says which key.
EOF
  ;;
esac
