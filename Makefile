# Waykin canonical targets (pattern adopted from the first implementation).

.PHONY: build test demo generate ios ui-test clean

build:
	swift build

test:
	swift test

demo:
	swift run waykin-sim

generate:
	cd App && rm -rf Waykin.xcodeproj && xcodegen generate

ios: generate
	xcodebuild -project App/Waykin.xcodeproj -scheme Waykin \
		-sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build

ui-test: generate
	xcodebuild -project App/Waykin.xcodeproj -scheme Waykin \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

clean:
	rm -rf .build App/Waykin.xcodeproj
