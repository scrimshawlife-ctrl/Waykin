# Waykin Validation Makefile
# Canonical targets for build, test, and validation.

.PHONY: generate build test demo validate validate-collaboration validate-simulator clean-generated check-core-isolation test-core-isolation

generate:
	@rm -rf Waykin.xcodeproj
	xcodegen generate

build:
	swift build

test:
	swift test

demo:
	swift run WaykinDemo

check-core-isolation:
	@./scripts/check_core_framework_isolation.sh

test-core-isolation:
	@./scripts/test_check_core_framework_isolation.sh

validate:
	@./scripts/validate.sh

validate-collaboration:
	@python3 scripts/validate_collaboration_coordination.py

validate-simulator:
	@./scripts/validate_simulator.sh $(WAYKIN_SIMULATOR_NAME)

clean-generated:
	rm -rf Waykin.xcodeproj
	find . -name "*.xcodeproj" -prune -o -name "DerivedData" -type d -prune -o -print 2>/dev/null | head -5 || true
