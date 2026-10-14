#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${MASKPAD_IOS_BUILD_DIR:-$ROOT/build-ios-simulator}"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <simulator-udid> [simulator-udid ...]" >&2
    exit 2
fi

MASKPAD_BUILD_UI_TESTS=1 "$ROOT/scripts/configure-ios.sh" --simulator

for udid in "$@"; do
    xcrun simctl bootstatus "$udid" -b
    results="$(mktemp -d "$BUILD/ui-results.XXXXXX")/Tests.xcresult"
    echo "UI test results: $results"
    xcodebuild \
        -quiet \
        -project "$BUILD/2s2h.xcodeproj" \
        -scheme 2ship \
        -configuration Release \
        -resultBundlePath "$results" \
        -destination "platform=iOS Simulator,id=$udid" \
        -only-testing:MaskPadUITests/MaskPadUITests/testControlPressReleaseToggleAndLifecycleCancellation \
        -only-testing:MaskPadUITests/MaskPadUITests/testMoveResizeClampProtectionResetAndPersistence \
        test || {
            status=$?
            summary="$(xcrun xcresulttool get test-results summary --path "$results" --compact || true)"
            echo "$summary"
            # Surface the failing tests as annotations (job logs are not always reachable).
            python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
except ValueError:
    sys.exit(0)
for failure in (data.get("testFailures") or [])[:10]:
    text = " ".join(str(failure.get("failureText", "")).split())[:900]
    print("::error title=UI test failed: %s::%s" % (failure.get("testName", "?"), text))
if not data.get("testFailures"):
    print("::error title=UI test summary::%s" % " ".join(json.dumps(data).split())[:900])
' <<<"$summary" || true
            exit "$status"
        }
done
