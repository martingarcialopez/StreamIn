#!/usr/bin/env bash
# xcodebuild for one session at a time.
#
#   scripts/xcodebuild-locked.sh <xcodebuild arguments>
#
# Parallel Claude sessions (/parallel) each have their own worktree, but share
# the Mac's CPU. Two test-plan runs at once slow each other down badly, so local
# builds take a shared lock and the second one waits.
#
# Without a -destination, it uses this session's simulator: $STREAMIN_SIMULATOR
# (set in worktree sessions by .claude/hooks/worktree-session.sh), or iPhone 17.

set -euo pipefail

lock="${TMPDIR:-/tmp}/streamin-xcodebuild.lock"

args=("$@")
if [[ " $* " != *" -destination "* ]]; then
  args+=(-destination "platform=iOS Simulator,name=${STREAMIN_SIMULATOR:-iPhone 17},OS=latest")
fi

# lockf -t 0 fails at once if another session holds the lock.
if ! lockf -s -t 0 "$lock" true 2>/dev/null; then
  echo "Another session is building; waiting for its xcodebuild to finish…" >&2
fi
exec lockf -s "$lock" xcodebuild "${args[@]}"
