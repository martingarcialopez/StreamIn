#!/bin/bash
# PreToolUse(Bash): work ships as one PR per roadmap phase, so commits and
# pushes never land on main directly. Exit 2 blocks the command and shows the
# message to Claude.

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
# The session's own directory: a worktree session commits in its worktree,
# while $CLAUDE_PROJECT_DIR stays the main checkout, which sits on main.
dir=$(jq -r '.cwd // empty' <<<"$input")
dir=${dir:-$CLAUDE_PROJECT_DIR}

# Patterns stay inside one command: [^;&|]* stops at &&, ; and |, so
# `git push && gh pr edit --base main` isn't mistaken for a push to main.
# `commit`/`push` must be whole words, so `git branch -D chore/commit-skill`
# doesn't count, but `git push;` and `(cd repo && git push)` still do.
writes_git='git[[:space:]]([^;&|]*[[:space:]])?(commit|push)([[:space:];&|)]|$)'
[[ "$command" =~ $writes_git ]] || exit 0

# Creating the branch in the same command (git switch -c … && git commit) is fine,
# with other flags before the create flag too (git switch -q -c …).
creates_branch='git[[:space:]]+(switch|checkout)([[:space:]]+-[^[:space:];&|]+)*[[:space:]]+(-c|-C|-b|-B|--create|--force-create)([[:space:]]|$)'
[[ "$command" =~ $creates_branch ]] && exit 0

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
pushes_main='git[[:space:]]+push[^;&|]*[[:space:]:]main([[:space:]]|$)'

if [[ "$branch" == "main" || "$command" =~ $pushes_main ]]; then
    echo "Blocked: changes reach main only through a PR (one per roadmap phase). Start a branch first: git switch -c feat/<phase-name>" >&2
    exit 2
fi
exit 0
