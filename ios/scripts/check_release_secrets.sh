#!/bin/sh
# Xcode Run Script phase: stop a Release/Profile build that has no Google Maps
# key. MAPS_API_KEY comes from the gitignored Secrets.xcconfig, which
# Release.xcconfig pulls in with #include? — so a checkout without that file
# (e.g. a fresh git worktree) silently builds with an empty key, and the app
# then crashes as soon as the home map shows (TestFlight 40, 2026-10-30).

case "$CONFIGURATION" in
  Release|Profile) ;;
  *) exit 0 ;;
esac

case "$MAPS_API_KEY" in
  ''|'$('*)
    echo "error: MAPS_API_KEY is empty: ios/Flutter/Secrets.xcconfig is missing or has no MAPS_API_KEY_PROD/_DEV. Build from the main checkout or copy Secrets.xcconfig in."
    exit 1
    ;;
esac
exit 0
