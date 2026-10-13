#!/usr/bin/env bash
# xcodebuild for one session at a time.
#
#   scripts/xcodebuild-locked.sh <xcodebuild arguments>
#
# Parallel Claude sessions (/parallel) each have their own worktree, but share
# the Mac's CPU. Two test-plan runs at once slow each other down badly, so local
# builds take a shared lock and the second one waits.
#
# Without a -destination, it uses this checkout's simulator
# (scripts/worktree-simulator.sh: iPhone 17 in the main checkout, a dedicated one
# in a worktree, created on first use).

set -euo pipefail

lock="${TMPDIR:-/tmp}/streamin-xcodebuild.lock"

args=("$@")
if [[ " $* " != *" -destination "* ]]; then
  simulator=$("$(dirname "$0")/worktree-simulator.sh")
  args+=(-destination "platform=iOS Simulator,name=$simulator,OS=latest")
fi

# lockf -t 0 fails at once if another session holds the lock.
if ! lockf -s -t 0 "$lock" true 2>/dev/null; then
  echo "Another session is building; waiting for its xcodebuild to finish…" >&2
fi
exec lockf -s "$lock" xcodebuild "${args[@]}"
