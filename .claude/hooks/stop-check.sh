#!/bin/bash
# Stop hook: run swiftformat, swiftlint, and the test suite.
# On failure, exit 2 so Claude Code surfaces the output and re-wakes the model.
set -u

cd "$(dirname "$0")/../.." || exit 0

INPUT=$(cat)
# Avoid an infinite loop: if this hook already fired and re-woke the model,
# don't block the next stop.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

run_step() {
    local name=$1
    shift
    : >"$LOG"
    if ! "$@" >"$LOG" 2>&1; then
        echo "$name failed:" >&2
        tail -100 "$LOG" >&2
        exit 2
    fi
}

run_step "swiftformat" swiftformat pgrind pgrindTests
run_step "swiftlint"   swiftlint lint --quiet --strict pgrind pgrindTests
run_step "tests"       xcodebuild \
    -project pgrind.xcodeproj \
    -scheme pgrind \
    -configuration Debug \
    -derivedDataPath build \
    -only-testing:pgrindTests \
    test

exit 0
