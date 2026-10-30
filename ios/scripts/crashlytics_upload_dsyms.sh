#!/bin/sh
# Xcode Run Script phase: upload this build's dSYMs to Firebase Crashlytics so
# iOS crash reports show readable stack traces. Release builds only.
#
# The app has no GoogleService-Info.plist (Firebase is configured from
# --dart-define), so the Firebase iOS app id is read from DART_DEFINES, which
# Flutter passes as base64 entries in Generated.xcconfig. Never fails the
# build: a missing id or a failed upload only prints a warning.

[ "$CONFIGURATION" = "Release" ] || exit 0

APP_ID=""
for entry in $(echo "$DART_DEFINES" | tr ',' ' '); do
  decoded=$(echo "$entry" | base64 --decode 2>/dev/null)
  case "$decoded" in
    APP_IOS_FIREBASE_APP_ID=*) APP_ID="${decoded#APP_IOS_FIREBASE_APP_ID=}" ;;
  esac
done

if [ -z "$APP_ID" ]; then
  echo "warning: Crashlytics: APP_IOS_FIREBASE_APP_ID not in DART_DEFINES, dSYMs not uploaded"
  exit 0
fi

"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" --build-phase --app-id "$APP_ID" \
  || echo "warning: Crashlytics: dSYM upload failed"
exit 0
