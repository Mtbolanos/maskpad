#!/usr/bin/env bash
set -euo pipefail

# Controller slot reconciliation (sleep, disconnect, reconnect, extra pads) lives in the
# libultraship patch shared with HarkinianPad; this exercises it without a device.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/2ship2harkinian/libultraship"

if ! git -C "$SOURCE" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Run scripts/clone-sources.sh and scripts/apply-patches.sh first." >&2
    exit 1
fi

if ! git -C "$SOURCE" apply --reverse --check "$ROOT/patches/libultraship-ios.patch" >/dev/null 2>&1; then
    echo "The maintained libultraship patch is not applied." >&2
    exit 1
fi

test_dir="$(mktemp -d "${TMPDIR:-/tmp}/maskpad-controller-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

"${CXX:-c++}" -std=c++20 -Wall -Wextra -Werror \
    -I"$SOURCE/include" \
    "$ROOT/tests/controller_slot_assignments_test.cpp" \
    "$SOURCE/src/ship/controller/physicaldevice/ControllerSlotAssignments.cpp" \
    -o "$test_dir/controller_slot_assignments_test"

"$test_dir/controller_slot_assignments_test"
