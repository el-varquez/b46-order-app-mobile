.DEFAULT_GOAL := help

-include .env

FLUTTER ?= flutter
ADB ?= adb
APP_ENV ?= development
API_BASE_URL ?= http://127.0.0.1:8080
BACKEND_PORT ?= 8080
ORDER_POLL_SECONDS ?= 5
GOOGLE_SERVER_CLIENT_ID ?=
GOOGLE_CLIENT_ID ?=
DEVICE ?=
EXTRA_DART_DEFINES ?=

DEVICE_FLAG = $(if $(strip $(DEVICE)),-d $(DEVICE),)
ADB_DEVICE_FLAG = $(if $(strip $(DEVICE)),-s $(DEVICE),)
DART_DEFINES = --dart-define=APP_ENV=$(APP_ENV) \
	--dart-define=API_BASE_URL=$(API_BASE_URL) \
	--dart-define=ORDER_POLL_SECONDS=$(ORDER_POLL_SECONDS) \
	--dart-define=GOOGLE_SERVER_CLIENT_ID=$(GOOGLE_SERVER_CLIENT_ID) \
	--dart-define=GOOGLE_CLIENT_ID=$(GOOGLE_CLIENT_ID) \
	$(EXTRA_DART_DEFINES)

.PHONY: help dependencies setup-ios run debug run-android run-ios debug-apk devices doctor \
	check build-test architecture design contracts conventions gates

help:
	@echo B46 Order App Mobile - make targets
	@echo   make dependencies   download Flutter and Dart package dependencies
	@echo   make setup-ios      prepare Flutter, Swift packages, and iOS artifacts
	@echo   make run            run a debug app using API_BASE_URL and optional DEVICE
	@echo   make debug          alias for make run
	@echo   make run-android    run on a USB Android phone with backend port forwarding
	@echo   make run-ios        compile and run on a selected iPhone
	@echo   make debug-apk      build the Android debug APK
	@echo   make devices        list connected Flutter devices
	@echo   make doctor         inspect the local Flutter toolchain
	@echo   make check          run build, architecture, and design gates
	@echo   make build-test     run formatting, analysis, tests, and debug APK build
	@echo   make architecture   verify Clean Architecture rules
	@echo   make design         verify Pop Shelf design-system rules
	@echo   make contracts      verify the pinned backend OpenAPI artifact
	@echo   make conventions    verify branch and commit conventions
	@echo Optional overrides: DEVICE, API_BASE_URL, BACKEND_PORT, APP_ENV, ORDER_POLL_SECONDS, GOOGLE_SERVER_CLIENT_ID, GOOGLE_CLIENT_ID, EXTRA_DART_DEFINES

dependencies:
	$(FLUTTER) pub get

setup-ios:
	$(FLUTTER) config --enable-swift-package-manager
	$(FLUTTER) precache --ios
	$(FLUTTER) pub get

run:
	$(FLUTTER) run --debug $(DEVICE_FLAG) $(DART_DEFINES)

debug: run

run-android:
	$(ADB) $(ADB_DEVICE_FLAG) reverse tcp:$(BACKEND_PORT) tcp:$(BACKEND_PORT)
	$(MAKE) run API_BASE_URL=http://127.0.0.1:$(BACKEND_PORT) DEVICE="$(DEVICE)"

run-ios:
	$(MAKE) run API_BASE_URL="$(API_BASE_URL)" DEVICE="$(DEVICE)"

debug-apk:
	$(FLUTTER) build apk --debug $(DART_DEFINES)

devices:
	$(FLUTTER) devices

doctor:
	$(FLUTTER) doctor -v

build-test:
	node scripts/check-build-test.mjs

architecture:
	node scripts/check-architecture.mjs

design:
	node scripts/check-design.mjs

contracts:
	node scripts/check-contract-pin.mjs

conventions:
	node scripts/check-conventions.mjs

check: build-test architecture design contracts
	@echo all mobile quality gates passed

gates: check
