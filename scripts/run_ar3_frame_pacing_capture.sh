#!/bin/bash

set -euo pipefail

DEVICE_UDID="00008150-000A6C120CB8401C"
PROCESS_NAME="Waykin AR Lab"
TRACE_TEMPLATE="Animation Hitches"
ARTIFACT="/private/tmp/waykin-ar3-env-none-derived/Build/Products/Debug-iphoneos/Waykin AR Lab.app"
DERIVED_DATA="/private/tmp/waykin-ar3-frame-pacing-ui-tests-derived"
EXPECTED_EXECUTABLE_SHA="9d6f84e9cfc39adafaba527a99eb4021376f722e19f61444f233b9f45f4c46f5"
EXPECTED_DYLIB_SHA="9fb89d49d1bf2af32e14d6dcc0a408174cf4d3ea8c33f07ea5932fd6dbccc4b1"
AUTOMATED="${WAYKIN_AR3_AUTOMATED:-0}"
CAPTURE_ID="${WAYKIN_AR3_CAPTURE_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
TRACE="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.trace"
XML="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.xml"
NOTIFICATION="com.waykin.ar3.frame-pacing.${CAPTURE_ID}"
NOTIFICATION_LOG="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.notification"
XCTRACE_LOG="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.xctrace.log"
UI_TEST_LOG="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.ui-test.log"
UI_TEST_RESULT="/private/tmp/waykin-ar3-frame-pacing-${CAPTURE_ID}.xcresult"

trace_pid=""
notification_pid=""
ui_test_pid=""

cleanup() {
    if [[ -n "$notification_pid" ]]; then
        kill "$notification_pid" 2>/dev/null || true
    fi
    if [[ -n "$trace_pid" ]]; then
        kill "$trace_pid" 2>/dev/null || true
    fi
    if [[ -n "$ui_test_pid" ]]; then
        kill "$ui_test_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

fail() {
    echo "error: $*" >&2
    exit 2
}

case "$AUTOMATED" in
    0|1) ;;
    *) fail "WAYKIN_AR3_AUTOMATED must be 0 or 1" ;;
esac

[[ -d "$ARTIFACT" ]] || fail "exact candidate artifact is missing: $ARTIFACT"
[[ ! -e "$TRACE" ]] || fail "trace path already exists: $TRACE"
[[ ! -e "$XML" ]] || fail "XML path already exists: $XML"
if [[ "$AUTOMATED" == "1" ]]; then
    [[ ! -e "$UI_TEST_RESULT" ]] || fail "UI test result path already exists: $UI_TEST_RESULT"
fi

actual_executable_sha=$(shasum -a 256 "$ARTIFACT/$PROCESS_NAME" | awk '{print $1}')
actual_dylib_sha=$(shasum -a 256 "$ARTIFACT/$PROCESS_NAME.debug.dylib" | awk '{print $1}')
[[ "$actual_executable_sha" == "$EXPECTED_EXECUTABLE_SHA" ]] || fail "executable hash mismatch"
[[ "$actual_dylib_sha" == "$EXPECTED_DYLIB_SHA" ]] || fail "debug dylib hash mismatch"

if pgrep -x "iPhone Mirroring" >/dev/null 2>&1; then
    fail "close iPhone Mirroring and operate the unlocked physical phone during capture"
fi

online_devices=$(xcrun xctrace list devices | awk '/^== Devices Offline ==/{exit} {print}')
grep -Fq "($DEVICE_UDID)" <<<"$online_devices" || fail "recorded iPhone is offline or unavailable: $DEVICE_UDID"

echo "Candidate hashes: PASS"
echo "Device availability: PASS"
echo "Capture ID: $CAPTURE_ID"
echo "Trace: $TRACE"

if [[ "$AUTOMATED" == "1" ]]; then
    command -v xcodegen >/dev/null || fail "xcodegen is required for automated mode"
    xcodegen generate >/dev/null
    xcodebuild \
        -project Waykin.xcodeproj \
        -scheme WaykinARLab \
        -destination "platform=iOS,id=$DEVICE_UDID" \
        -derivedDataPath "$DERIVED_DATA" \
        -allowProvisioningUpdates \
        DEVELOPMENT_TEAM=X9M969D8M3 \
        CODE_SIGN_STYLE=Automatic \
        build-for-testing \
        >"$UI_TEST_LOG" 2>&1 || { cat "$UI_TEST_LOG" >&2; fail "AR Lab UI test build failed"; }

    preserved_executable_sha=$(shasum -a 256 "$ARTIFACT/$PROCESS_NAME" | awk '{print $1}')
    preserved_dylib_sha=$(shasum -a 256 "$ARTIFACT/$PROCESS_NAME.debug.dylib" | awk '{print $1}')
    [[ "$preserved_executable_sha" == "$EXPECTED_EXECUTABLE_SHA" ]] || fail "UI test build changed the preserved exact candidate executable"
    [[ "$preserved_dylib_sha" == "$EXPECTED_DYLIB_SHA" ]] || fail "UI test build changed the preserved exact candidate debug dylib"

    xctestrun=$(find "$DERIVED_DATA/Build/Products" -maxdepth 1 -name '*.xctestrun' -print -quit)
    [[ -n "$xctestrun" ]] || fail "AR Lab xctestrun file is missing"
    plutil -replace WaykinARLabUITests.UITargetAppPath -string "$ARTIFACT" "$xctestrun"
    plutil -replace WaykinARLabUITests.DependentProductPaths.0 -string "$ARTIFACT" "$xctestrun"

    xcodebuild \
        -xctestrun "$xctestrun" \
        -destination "platform=iOS,id=$DEVICE_UDID" \
        -only-testing:WaykinARLabUITests/AR3FramePacingUITests/testFramePacingWorkload \
        -resultBundlePath "$UI_TEST_RESULT" \
        test-without-building \
        >>"$UI_TEST_LOG" 2>&1 &
    ui_test_pid=$!

    echo "Waiting for the automated warm-up to complete."
    for _ in $(seq 1 180); do
        if grep -q "AR3_AUTOMATION_READY" "$UI_TEST_LOG"; then
            break
        fi
        if ! kill -0 "$ui_test_pid" 2>/dev/null; then
            wait "$ui_test_pid" || true
            cat "$UI_TEST_LOG" >&2
            fail "AR Lab UI test exited before its readiness marker"
        fi
        sleep 1
    done
    grep -q "AR3_AUTOMATION_READY" "$UI_TEST_LOG" || { cat "$UI_TEST_LOG" >&2; fail "timed out waiting for automated warm-up"; }
else
    echo "Before continuing, complete one Start Arc -> Run Arc -> Clear warm-up."
    echo "The app must be foregrounded, tracking active, and entity count 0."
    echo "Press Return when the warm-up is complete."
    read -r
fi

notifyutil -1 "$NOTIFICATION" >"$NOTIFICATION_LOG" 2>&1 &
notification_pid=$!

xcrun xctrace record \
    --template "$TRACE_TEMPLATE" \
    --device "$DEVICE_UDID" \
    --attach "$PROCESS_NAME" \
    --time-limit 90s \
    --notify-tracing-started "$NOTIFICATION" \
    --output "$TRACE" \
    >"$XCTRACE_LOG" 2>&1 &
trace_pid=$!

for _ in $(seq 1 60); do
    if ! kill -0 "$notification_pid" 2>/dev/null; then
        break
    fi
    if ! kill -0 "$trace_pid" 2>/dev/null; then
        wait "$trace_pid" || true
        cat "$XCTRACE_LOG" >&2
        fail "xctrace exited before recording began"
    fi
    sleep 1
done

if kill -0 "$notification_pid" 2>/dev/null; then
    cat "$XCTRACE_LOG" >&2
    fail "timed out waiting for the tracing-start notification"
fi
notification_pid=""

echo "Recording started. Leave the cleared scene idle for 10 seconds."
if [[ "$AUTOMATED" == "1" ]]; then
    echo "The UI test is executing three measured cycles and the final idle window."
else
    sleep 10
    echo "CYCLE 1 NOW: Start Arc -> Run Arc -> Clear"
    sleep 15
    echo "CYCLE 2 NOW: Start Arc -> Run Arc -> Clear"
    sleep 15
    echo "CYCLE 3 NOW: Start Arc -> Run Arc -> Clear"
    sleep 20
    echo "FINAL IDLE: keep the cleared camera foregrounded until capture ends"
fi

wait "$trace_pid"
trace_pid=""

if [[ "$AUTOMATED" == "1" ]]; then
    if ! wait "$ui_test_pid"; then
        ui_test_pid=""
        cat "$UI_TEST_LOG" >&2
        fail "automated AR Lab workload failed"
    fi
    ui_test_pid=""
    grep -q "AR3_AUTOMATION_WORKLOAD_COMPLETE" "$UI_TEST_LOG" \
        || { cat "$UI_TEST_LOG" >&2; fail "automated workload completion marker is missing"; }
    echo "Automated workload and cleanup assertions: PASS"
fi

set +e
xcrun xctrace export \
    --input "$TRACE" \
    --xpath '//trace-toc[1]/run[1]/data[1]/table[@schema="displayed-surfaces-interval"]' \
    --output "$XML"
export_status=$?
set -e

[[ -s "$XML" ]] || fail "xctrace export did not produce displayed-surface XML"
xmllint --noout "$XML" || fail "xctrace export produced malformed displayed-surface XML"
if [[ "$export_status" -ne 0 ]]; then
    echo "warning: xctrace export exited $export_status after producing valid XML; continuing"
fi

trace_manifest_sha=$(find "$TRACE" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')
echo "Trace manifest SHA-256: $trace_manifest_sha"
if [[ "$AUTOMATED" == "1" ]]; then
    echo "UI test log: $UI_TEST_LOG"
    echo "UI test result: $UI_TEST_RESULT"
else
    echo "Confirm separately: all three cycles completed, each Clear returned entity count to 0, and the app remained alive."
fi

PYTHONDONTWRITEBYTECODE=1 python3 scripts/analyze_ar3_frame_pacing.py "$XML"
