# Waykin Validation Makefile
# Canonical targets for build, test, and validation.

.PHONY: generate build test validate validate-simulator clean-generated

generate:
	@rm -rf Waykin.xcodeproj
	xcodegen generate

build:
	swift build

test:
	swift test

validate:
	@./scripts/validate.sh

validate-simulator:
	@./scripts/validate_simulator.sh $(WAYKIN_SIMULATOR_NAME)

clean-generated:
	rm -rf Waykin.xcodeproj
	find . -name "*.xcodeproj" -prune -o -name "DerivedData" -type d -prune -o -print 2>/dev/null | head -5 || true
