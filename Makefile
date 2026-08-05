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

# Extra args passed through to flutter, e.g. make run ARGS=-v
ARGS ?=

.DEFAULT_GOAL := help
.PHONY: help setup env deps run run-preprod run-prod gen watch analyze test \
        format check aab apk clean devices

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

clean:
	flutter clean
	flutter pub get
