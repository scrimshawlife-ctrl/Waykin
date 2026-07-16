# Waykin Validation Makefile
# Canonical targets for build, test, and validation.

.PHONY: generate build test validate clean-generated

generate:
	@rm -rf Waykin.xcodeproj
	xcodegen generate

build:
	swift build

test:
	swift test

validate:
	@./scripts/validate.sh

clean-generated:
	rm -rf Waykin.xcodeproj
	find . -name "*.xcodeproj" -prune -o -name "DerivedData" -type d -prune -o -print 2>/dev/null | head -5 || true
