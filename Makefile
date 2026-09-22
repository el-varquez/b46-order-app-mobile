.DEFAULT_GOAL := help

.PHONY: help check build-test architecture design conventions gates

help:
	@echo B46 Order App Mobile - make targets
	@echo   make check          run build, architecture, and design gates
	@echo   make build-test     run scaffold or Flutter build and test checks
	@echo   make architecture   verify Clean Architecture rules
	@echo   make design         verify Pop Shelf design-system rules
	@echo   make conventions    verify branch and commit conventions

build-test:
	node scripts/check-build-test.mjs

architecture:
	node scripts/check-architecture.mjs

design:
	node scripts/check-design.mjs

conventions:
	node scripts/check-conventions.mjs

check: build-test architecture design
	@echo all mobile quality gates passed

gates: check
