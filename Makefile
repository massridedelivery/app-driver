# Massdrive driver app — common tasks.
#
# Every build needs two --dart-define-from-file arguments: a backend config
# plus the app-identity config that supplies the Firebase keys (see README.md).
# The targets below pair them for you, so the Firebase-less combination that
# silently fails to initialize can't happen by accident.
#
# Runs from PowerShell, CMD or Git Bash. On Windows GNU Make falls back to
# cmd.exe whenever sh.exe isn't on PATH, so recipes here stick to commands both
# shells understand — no POSIX-only tools.

# Which shell did Make get? Git Bash/MSYS sets MSYSTEM; PowerShell and CMD
# don't, and there Make falls back to cmd.exe. Detected from environment
# variables rather than $(shell ...) — probing with a shell makes `make -n`
# emit a spurious CreateProcess error on Windows.
ifeq ($(OS)$(MSYSTEM),Windows_NT)
  MAKE_ENV := type nul > .env
else
  MAKE_ENV := touch .env
endif

# Backend config → the app identity it must be paired with.
DEV      := --dart-define-from-file=config/dev.json --dart-define-from-file=config/mass_dev.json
PREPROD  := --dart-define-from-file=config/preprod.json --dart-define-from-file=config/mass_dev.json
PROD     := --dart-define-from-file=config/prod.json --dart-define-from-file=config/mass_prod.json
# Prod-shaped build (env=prod, no package suffix -> com.massapp.massdrive, app
# name "Massdrive") running entirely on dev infra: dev Firebase/Omise from
# mass_prod_devapi.json and the dev API from prod_devapi.json. For exercising a
# prod-looking build without touching any real prod service.
PROD_DEVAPI := --dart-define-from-file=config/prod_devapi.json --dart-define-from-file=config/mass_prod_devapi.json

# Extra args passed through to flutter, e.g. make run ARGS=-v
ARGS ?=

.DEFAULT_GOAL := help
.PHONY: help setup env deps run run-preprod run-prod run-prod-devapi gen watch \
        analyze test format check aab apk apk-dev deploy-dev deploy-prod-devapi \
        bump build_aab_prod_devapi upload_play_prod_devapi deploy_play_prod_devapi \
        deploy_play_check clean devices

# Plain echo lines, one per target: cmd.exe has no grep/awk, and `echo.` for a
# blank line is not something Make can spawn on Windows.
help:
	@echo Massdrive driver app - make targets
	@echo   setup         First-time setup - .env, packages, codegen
	@echo   env           Create the .env the asset bundle requires
	@echo   deps          flutter pub get
	@echo   ---
	@echo   run           Run against dev
	@echo   run-preprod   Run against pre-prod
	@echo   run-prod      Run against prod - config/prod.json is still a placeholder
	@echo   run-prod-devapi  Run prod identity/Firebase against the dev API
	@echo   devices       List attached devices/emulators
	@echo   ---
	@echo   gen           Regenerate freezed/json/riverpod/injectable code
	@echo   watch         Regenerate on file change
	@echo   ---
	@echo   analyze       Static analysis, same flags as CI
	@echo   test          Unit/widget tests
	@echo   format        Format lib and test
	@echo   check         analyze + test, what CI runs
	@echo   ---
	@echo   aab           Signed release bundle for Play
	@echo   apk           Release APK for sideloading
	@echo   apk-dev       Release APK built against dev, to hand to testers
	@echo   deploy-dev    iOS - build + ship to TestFlight - the MassDriverDev app
	@echo                 needs BUILD=N, e.g. make deploy-dev BUILD=2
	@echo   deploy-prod-devapi  iOS - prod build for MassDriver app, on the dev API
	@echo                 Xcode auto-numbers the build past App Store Connect
	@echo   clean         flutter clean + pub get
	@echo   ---
	@echo   Pass extra flutter args with ARGS, e.g. make run ARGS=-v

# ---------------------------------------------------------------- setup

setup: env deps gen

# .env is a pubspec asset but gitignored, so it's missing on a fresh checkout
# and the asset bundle fails to build without it. Empty is fine locally.
env:
ifeq ($(wildcard .env),)
	@$(MAKE_ENV)
	@echo Created .env
else
	@echo .env present
endif

deps:
	flutter pub get

# ---------------------------------------------------------------- run

run: env
	flutter run $(DEV) $(ARGS)

run-preprod: env
	flutter run $(PREPROD) $(ARGS)

run-prod: env
	flutter run $(PROD) $(ARGS)

run-prod-devapi: env
	flutter run $(PROD_DEVAPI) $(ARGS)

devices:
	flutter devices

# ---------------------------------------------------------------- codegen

# No --build-filter here on purpose: combined with --delete-conflicting-outputs
# it deletes every generated file outside the filter.
gen:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

# ---------------------------------------------------------------- verify

analyze: env
	flutter analyze --no-fatal-warnings --no-fatal-infos

test: env
	flutter test

format:
	dart format lib test

check: analyze test

# ---------------------------------------------------------------- build

aab: env
	flutter build appbundle --release $(PREPROD)
	@echo Output: build/app/outputs/bundle/release/app-release.aab

apk: env
	flutter build apk --release $(PREPROD)
	@echo Output: build/app/outputs/flutter-apk/app-release.apk

# A dev-backend Android build to hand to testers, not a Play upload. Publishing
# is deploy-play.yml (Actions tab -> Run workflow), which builds pre-prod and
# needs the Play service account; there is no dev track. An APK rather than a
# bundle because this is meant to be installed directly, and because the release
# build is only signed with the real upload key when android/key.properties
# exists — without it Gradle falls back to debug signing, which sideloads fine
# but Play rejects.
apk-dev: env
	# --split-per-abi: one small APK per CPU arch instead of a 68MB universal
	# APK (which bundled x86_64 + armeabi-v7a + arm64). Hand testers the arm64
	# one (~28MB) for any modern phone.
	flutter build apk --release $(DEV) --split-per-abi
	@echo "Output (per ABI): build/app/outputs/flutter-apk/app-*-release.apk"
	@echo "Modern phones -> app-arm64-v8a-release.apk"

# ---------------------------------------------------------------- ship (iOS)

# The TestFlight round trip in one command: build the signed .ipa and upload it
# to the MassDriverDev app in App Store Connect, replacing "flutter build ipa"
# followed by dragging the file into Transporter. macOS only — the recipe
# drives Xcode's toolchain, so unlike the rest of this file it assumes a POSIX
# shell.
#
# Ships com.massapp.massdrive.dev, a *separate* App Store Connect app
# (MassDriverDev) from the com.massapp.massdrive one every other TestFlight
# upload goes to. Release leaves BUNDLE_ID_SUFFIX empty by default (so a plain
# `flutter build ipa` ships com.massapp.massdrive, matching the prod-driver
# Firebase project) — this target temporarily overrides it to .dev, along with
# APP_DISPLAY_NAME (Info.plist's CFBundleDisplayName, so the installed app reads
# "Massdrive DEV") and MAPS_API_KEY (back to the _DEV key, since Release.xcconfig
# defaults to the prod key), via ios/Flutter/Release.local.xcconfig, and always reverts
# (trap on EXIT), even if the build fails. Release.local.xcconfig is
# gitignored and #included from Release.xcconfig with #include? (silently
# a no-op when absent), so this can never leak into a normal `flutter build
# ipa`/CI run — only this recipe ever creates the file.
#
# BUILD is required. App Store Connect rejects a build number it has already
# seen, and pubspec's number trails what has been uploaded, so deriving it from
# pubspec would produce a rejected build — pass the next one explicitly.
#
# Uploading needs an App Store Connect API key (Users and Access -> Integrations
# -> App Store Connect API). Set both variables and this uploads; leave them
# unset and it stops at the .ipa and prints the manual step, i.e. exactly the
# flow this target replaces. AuthKey_$(ASC_KEY_ID).p8 must be readable at
# ~/.appstoreconnect/private_keys/ (or ~/private_keys/), where altool looks.
ifeq ($(filter deploy-dev,$(MAKECMDGOALS)),deploy-dev)
ifndef BUILD
$(error BUILD is required and must beat the last MassDriverDev TestFlight build, e.g. make deploy-dev BUILD=2)
endif
endif

deploy-dev: env
	@set -e; \
	trap 'rm -f ios/Flutter/Release.local.xcconfig' EXIT; \
	printf 'BUNDLE_ID_SUFFIX = .dev\nAPP_DISPLAY_NAME = Massdrive DEV\nMAPS_API_KEY = $$(MAPS_API_KEY_DEV)\n' \
	  > ios/Flutter/Release.local.xcconfig; \
	flutter build ipa --release $(DEV) --build-number=$(BUILD) \
	  --export-options-plist=ios/ExportOptions.plist; \
	if [ -n "$(ASC_KEY_ID)" ] && [ -n "$(ASC_ISSUER_ID)" ]; then \
	  echo "Uploading build $(BUILD) to TestFlight (MassDriverDev)..."; \
	  xcrun altool --upload-app -t ios -f build/ios/ipa/*.ipa \
	    --apiKey "$(ASC_KEY_ID)" --apiIssuer "$(ASC_ISSUER_ID)"; \
	else \
	  echo "Built build/ios/ipa/*.ipa (build $(BUILD))."; \
	  echo "ASC_KEY_ID/ASC_ISSUER_ID not set - upload it with Transporter or Xcode,"; \
	  echo "or set them to have this target upload too."; \
	fi

# Prod-identity iOS build (com.massapp.massdrive) on the dev API — see
# PROD_DEVAPI. A plain Release (no Release.local.xcconfig): BUNDLE_ID_SUFFIX
# stays empty, so it ships com.massapp.massdrive and lands in the MassDriver
# App Store Connect app, not MassDriverDev. Same ASC upload rules as deploy-dev
# (set the keys to upload, leave them unset to stop at the .ipa).
#
# No BUILD to pass: ios/ExportOptions.plist sets manageAppVersionAndBuildNumber,
# so Xcode stamps the number one past App Store Connect's latest at export time.
# That is the auto-bump — it can't collide and needs nothing tracked locally.
deploy-prod-devapi: env
	@set -e; \
	flutter build ipa --release $(PROD_DEVAPI) \
	  --export-options-plist=ios/ExportOptions.plist; \
	if [ -n "$(ASC_KEY_ID)" ] && [ -n "$(ASC_ISSUER_ID)" ]; then \
	  echo "Uploading to TestFlight (MassDriver)..."; \
	  xcrun altool --upload-app -t ios -f build/ios/ipa/*.ipa \
	    --apiKey "$(ASC_KEY_ID)" --apiIssuer "$(ASC_ISSUER_ID)"; \
	else \
	  echo "Built build/ios/ipa/*.ipa."; \
	  echo "ASC_KEY_ID/ASC_ISSUER_ID not set - upload it with Transporter or Xcode,"; \
	  echo "or set them to have this target upload too."; \
	fi

# ---------------------------------------------------------------- Google Play
# Android equivalent of the iOS TestFlight flow. Uploads a signed prod-devapi
# AAB (prod package com.massapp.massdrive on the dev API) to the Play
# **internal** track via fastlane `supply`.
#
# One-time setup (see docs/android-play-setup.md): android/key.properties
# (+ upload keystore) and android/fastlane/play-service-account.json, then
#   cd android && RBENV_VERSION=3.3.5 bundle install
# Every fastlane command needs the RBENV_VERSION prefix (fastlane is on Ruby 3.3.5).

# Bump the +build number in pubspec.yaml (Android versionCode) — Play requires a
# strictly higher versionCode on each upload. iOS is unaffected (ExportOptions
# auto-stamps the TestFlight build number).
bump:
	@perl -i -pe 's/^(version:\s*\d+\.\d+\.\d+\+)(\d+)\s*$$/$$1 . ($$2 + 1) . "\n"/e' pubspec.yaml
	@grep '^version:' pubspec.yaml

# Verify the Play service-account JSON authenticates (no upload).
deploy_play_check:
	cd android && RBENV_VERSION=3.3.5 bundle exec fastlane whoami

# Signed prod-devapi AAB (prod package com.massapp.massdrive, dev API). No
# flavor → output is build/app/outputs/bundle/release/app-release.aab.
build_aab_prod_devapi: env
	flutter build appbundle --release $(PROD_DEVAPI)
	@echo Output: build/app/outputs/bundle/release/app-release.aab

# Upload-only — the AAB must already be built (pairs with build_aab_prod_devapi).
upload_play_prod_devapi:
	cd android && \
		PLAY_PACKAGE_NAME=com.massapp.massdrive \
		AAB_PATH="$(CURDIR)/build/app/outputs/bundle/release/app-release.aab" \
		RBENV_VERSION=3.3.5 bundle exec fastlane deploy track:internal

# bump + build + upload prod-devapi to the Google Play internal track.
deploy_play_prod_devapi: bump build_aab_prod_devapi upload_play_prod_devapi

clean:
	flutter clean
	flutter pub get
