#!/usr/bin/env python3
"""Assign the latest uploaded TestFlight build to an internal beta group.

Why this exists: our internal group (default "Mass-Drive-QA-Test") was created
with automatic build distribution OFF (hasAccessToAllBuilds=false), and App Store
Connect does NOT allow turning that on for an existing group — it is settable only
at group creation. So every new build has to be added to the group by hand before
testers can see it. This script does that step over the ASC API, right after the
`make deploy-prod-devapi` upload, so builds show up for QA automatically.

Env it reads (the Makefile already passes the first two for the upload):
  ASC_KEY_ID      App Store Connect API key id (e.g. M4PPU86374)
  ASC_ISSUER_ID   ASC issuer id (UUID)
  ASC_KEY_PATH    optional; defaults to altool's location
                  ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
  TF_BUNDLE_ID    optional; defaults to com.massapp.massdrive
  TF_GROUP        optional; internal group name, defaults to Mass-Drive-QA-Test

Exits 0 on success or when it safely no-ops (keys absent, build already in group).
Never fails the build over a non-fatal assignment hiccup — it prints and exits 0,
except for genuinely unexpected errors.
"""
import json
import os
import sys
import time
import base64
import urllib.request
import urllib.error
from datetime import datetime, timezone

BASE = "https://api.appstoreconnect.apple.com"

# A build counts as "the one we just uploaded" only if ASC says it was uploaded
# within this many seconds of now. The previous build is a week old, so this
# cleanly tells the fresh upload apart from whatever was latest before.
# Overridable via TF_FRESH_WINDOW_S (handy for re-running after a slow delivery).
FRESH_WINDOW_S = int(os.environ.get("TF_FRESH_WINDOW_S", "") or 45 * 60)
# After altool reports success the build still has to clear Apple's delivery
# pipeline before it shows in /v1/builds, so poll instead of reading once.
POLL_TRIES = 30
POLL_EVERY_S = 30


def _b64(b: bytes) -> bytes:
    return base64.urlsafe_b64encode(b).rstrip(b"=")


def _token(key_id: str, issuer: str, key_path: str) -> str:
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    from cryptography.hazmat.primitives.asymmetric import ec, utils
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.backends import default_backend

    key = load_pem_private_key(open(key_path, "rb").read(), None, default_backend())
    now = int(time.time())
    header = _b64(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"},
                             separators=(",", ":")).encode())
    payload = _b64(json.dumps({"iss": issuer, "iat": now, "exp": now + 600,
                               "aud": "appstoreconnect-v1"},
                              separators=(",", ":")).encode())
    signing_input = header + b"." + payload
    der = key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r, s = utils.decode_dss_signature(der)
    raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return (signing_input + b"." + _b64(raw)).decode()


def _api(token: str, path: str, method: str = "GET", body: dict | None = None):
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Authorization": "Bearer " + token}
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(BASE + path, data=data, method=method, headers=headers)
    resp = urllib.request.urlopen(req)
    text = resp.read().decode()
    return resp.status, (json.loads(text) if text.strip() else None)


def main() -> int:
    key_id = os.environ.get("ASC_KEY_ID", "").strip()
    issuer = os.environ.get("ASC_ISSUER_ID", "").strip()
    if not key_id or not issuer:
        print("tf-assign: ASC_KEY_ID/ASC_ISSUER_ID not set — skipping (no upload happened).")
        return 0

    key_path = os.environ.get("ASC_KEY_PATH", "").strip() or os.path.expanduser(
        f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8")
    if not os.path.exists(key_path):
        print(f"tf-assign: key file not found at {key_path} — skipping.")
        return 0

    bundle_id = os.environ.get("TF_BUNDLE_ID", "").strip() or "com.massapp.massdrive"
    group_name = os.environ.get("TF_GROUP", "").strip() or "Mass-Drive-QA-Test"

    try:
        token = _token(key_id, issuer, key_path)

        apps = _api(token, f"/v1/apps?filter[bundleId]={bundle_id}")[1]["data"]
        if not apps:
            print(f"tf-assign: no app for bundleId {bundle_id} — skipping.")
            return 0
        app_id = apps[0]["id"]

        # Poll until the just-uploaded build has registered in ASC. We only act
        # on a build uploaded within FRESH_WINDOW_S so we never assign the stale
        # previous build if the new one is still in the delivery pipeline.
        build = None
        for attempt in range(1, POLL_TRIES + 1):
            latest = _api(token, f"/v1/builds?filter[app]={app_id}&limit=1&sort=-uploadedDate")[1]["data"]
            if latest:
                attrs = latest[0]["attributes"]
                uploaded = attrs.get("uploadedDate")
                age = None
                if uploaded:
                    try:
                        age = (datetime.now(timezone.utc)
                               - datetime.fromisoformat(uploaded)).total_seconds()
                    except ValueError:
                        age = None
                if age is not None and age <= FRESH_WINDOW_S:
                    build = latest[0]
                    break
                print(f"tf-assign: [{attempt}/{POLL_TRIES}] newest build {attrs.get('version')} "
                      f"not fresh yet (uploaded {uploaded}) — waiting for delivery…")
            else:
                print(f"tf-assign: [{attempt}/{POLL_TRIES}] no builds listed yet — waiting…")
            if attempt < POLL_TRIES:
                time.sleep(POLL_EVERY_S)

        if build is None:
            print("tf-assign: fresh build never appeared within the wait window — "
                  "skipping (add it to the group manually once it processes).")
            return 0
        build_id = build["id"]
        version = build["attributes"].get("version")

        groups = _api(token, f"/v1/apps/{app_id}/betaGroups?limit=50")[1]["data"]
        group = next((g for g in groups if g["attributes"].get("name") == group_name), None)
        if not group:
            names = [g["attributes"].get("name") for g in groups]
            print(f"tf-assign: group '{group_name}' not found (have: {names}) — skipping.")
            return 0
        group_id = group["id"]

        status, _ = _api(token, f"/v1/betaGroups/{group_id}/relationships/builds",
                         method="POST", body={"data": [{"type": "builds", "id": build_id}]})
        print(f"tf-assign: build {version} -> group '{group_name}' (HTTP {status}). "
              f"QA can now see it in TestFlight.")
        return 0
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:400]
        # Already-assigned shows up as a 409; treat as success.
        if e.code == 409 and "already" in detail.lower():
            print("tf-assign: build already in group — nothing to do.")
            return 0
        print(f"tf-assign: non-fatal ASC error {e.code}: {detail}")
        return 0
    except Exception as e:  # never break the build over assignment
        print(f"tf-assign: non-fatal error: {e}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
