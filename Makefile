# Waykin Validation Makefile
# Canonical targets for build, test, and validation.

.PHONY: generate build test demo validate validate-simulator validate-ar3-frame-pacing clean-generated

generate:
	@rm -rf Waykin.xcodeproj
	xcodegen generate

build:
	swift build

test:
	swift test

demo:
	swift run WaykinDemo

validate:
	@./scripts/validate.sh

validate-simulator:
	@./scripts/validate_simulator.sh $(WAYKIN_SIMULATOR_NAME)

validate-ar3-frame-pacing:
	@./scripts/run_ar3_frame_pacing_capture.sh

clean-generated:
	rm -rf Waykin.xcodeproj
	find . -name "*.xcodeproj" -prune -o -name "DerivedData" -type d -prune -o -print 2>/dev/null | head -5 || true
