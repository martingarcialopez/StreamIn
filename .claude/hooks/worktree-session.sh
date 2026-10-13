#!/bin/bash
# SessionStart: set up a session that runs in its own git worktree (/parallel,
# `claude -w`), so it can't collide with sessions in other checkouts.
#
# In a linked worktree it:
#   - creates a simulator for this worktree ("StreamIn <worktree>"), so two
#     sessions never install the app on the same simulator
#   - exports STREAMIN_SIMULATOR for the session's commands
#     (scripts/xcodebuild-locked.sh uses it as the default destination)
#   - opens the worktree's Xcode project in the background, for the Xcode MCP
#   - tells the session its Xcode window, its simulator and the parallel rules
# In the main checkout, and on Linux (claude[bot] in GitHub Actions), it does
# nothing. It never blocks the session: every step is best effort.

command -v xcrun >/dev/null 2>&1 || exit 0

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")
source=$(jq -r '.source // empty' <<<"$input")
cd "${cwd:-$PWD}" 2>/dev/null || exit 0

git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0
common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd)
[ "$git_dir" = "$common_dir" ] && exit 0   # the main checkout

top=$(git rev-parse --show-toplevel)
name=$(basename "$top")
branch=$(git branch --show-current)
simulator="StreamIn $name"
project="$top/StreamIn.xcodeproj"

# A simulator of its own: newest iOS runtime, iPhone 17.
if ! xcrun simctl list devices -j 2>/dev/null \
    | jq -e --arg n "$simulator" '[.devices[][] | select(.name == $n)] | length > 0' >/dev/null; then
  runtime=$(xcrun simctl list runtimes -j 2>/dev/null | jq -r '
    [.runtimes[] | select(.platform == "iOS" and .isAvailable)]
    | sort_by(.version | split(".") | map(tonumber)) | last | .identifier // empty')
  [ -n "$runtime" ] && xcrun simctl create "$simulator" \
    com.apple.CoreSimulator.SimDeviceType.iPhone-17 "$runtime" >/dev/null 2>&1
fi

# Every Bash command of this session sees it.
if [ -n "$CLAUDE_ENV_FILE" ]; then
  printf 'export STREAMIN_SIMULATOR=%q\n' "$simulator" >> "$CLAUDE_ENV_FILE"
fi

# Open the project once, when the session starts, without stealing focus.
if [ "$source" = "startup" ] && [ -d "$project" ]; then
  open -g -a Xcode "$project" >/dev/null 2>&1
fi

context="You are a parallel session, in the git worktree \`$top\` (worktree \`$name\`, branch \`$branch\`). Other Claude sessions may be working in the main checkout or other worktrees at the same time, so:
- Work only inside this worktree. Never cd into or edit the main checkout.
- Xcode MCP: there may be several Xcode windows. Call XcodeListWindows and use only the tab whose workspacePath is \`$project\`.
- Simulator: use \`$simulator\` (in \$STREAMIN_SIMULATOR), never another session's simulator.
- Local builds and tests: run them through \`scripts/xcodebuild-locked.sh\` (same arguments as xcodebuild). It queues behind other sessions' builds and defaults to your simulator.
- Branch: if it's still \`worktree-$name\`, /start-issue renames it to the issue's \`<type>/<task>\` branch."

jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
exit 0
