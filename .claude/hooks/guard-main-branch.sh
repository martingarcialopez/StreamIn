#!/bin/bash
# PreToolUse(Bash): work ships as one PR per roadmap phase, so commits and
# pushes never land on main directly. Exit 2 blocks the command and shows the
# message to Claude.

command=$(jq -r '.tool_input.command // empty')

writes_git='git[[:space:]].*(commit|push)'
[[ "$command" =~ $writes_git ]] || exit 0

# Creating the branch in the same command (git switch -c … && git commit) is fine.
creates_branch='(switch|checkout)[[:space:]]+(-c|-b|--create)'
[[ "$command" =~ $creates_branch ]] && exit 0

branch=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null)
pushes_main='push[[:space:]].*[[:space:]]main([[:space:]]|$)'

if [[ "$branch" == "main" || "$command" =~ $pushes_main ]]; then
    echo "Blocked: changes reach main only through a PR (one per roadmap phase). Start a branch first: git switch -c feat/<phase-name>" >&2
    exit 2
fi
exit 0
