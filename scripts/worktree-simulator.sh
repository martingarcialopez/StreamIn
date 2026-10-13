#!/usr/bin/env bash
# Prints the simulator this checkout should use, creating it on first use.
#
#   scripts/worktree-simulator.sh
#
# The main checkout uses "iPhone 17". A git worktree (every session that changes
# the repo works in one) gets its own, "StreamIn <worktree folder>": an iPhone 17
# on the newest iOS. Two sessions then never install the app on the same
# simulator. /parallel clean deletes it with the worktree.

set -euo pipefail

git_dir=$(git rev-parse --absolute-git-dir)
common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd)
if [ "$git_dir" = "$common_dir" ]; then
  echo "iPhone 17"
  exit 0
fi

name="StreamIn $(basename "$(git rev-parse --show-toplevel)")"
if ! xcrun simctl list devices -j | jq -e --arg n "$name" '[.devices[][] | select(.name == $n)] | length > 0' >/dev/null; then
  runtime=$(xcrun simctl list runtimes -j | jq -r '
    [.runtimes[] | select(.platform == "iOS" and .isAvailable)]
    | sort_by(.version | split(".") | map(tonumber)) | last | .identifier')
  xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-17 "$runtime" >/dev/null
  echo "Created simulator \"$name\"." >&2
fi
echo "$name"
