#!/bin/bash
# SessionStart: warn (never block) when the main checkout is stale.
#
# Hooks and settings (and skills, by default) load from the directory a session
# starts in: the main checkout, unless it was started inside a worktree (claude -w).
# New worktrees also copy its gitignored files (.worktreeinclude). A main
# checkout that's behind origin/main, off main or edited locally means sessions
# run yesterday's workflow — a hook fix merged an hour ago doesn't apply until
# it's pulled.

# CI checkouts (claude[bot], the PR review) are never the control room.
[[ -n "${GITHUB_ACTIONS:-}" ]] && exit 0

common=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
main=$(dirname "$common")

problems=()

branch=$(git -C "$main" branch --show-current)
[[ "$branch" == "main" ]] || problems+=("it's on '${branch:-a detached HEAD}', not main")

changed=$(git -C "$main" status --porcelain --untracked-files=no | wc -l | tr -d ' ')
(( changed == 0 )) || problems+=("$changed tracked file(s) have local changes")

# A failed fetch (offline, or credentials needed) just skips the check; it
# never waits for a prompt.
if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes' \
        git -C "$main" fetch --quiet origin main 2>/dev/null; then
    behind=$(git -C "$main" rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
    (( behind == 0 )) || problems+=("it's $behind commit(s) behind origin/main")
fi

(( ${#problems[@]} == 0 )) && exit 0

joined=$(printf '%s; ' "${problems[@]}")
message="Main checkout ($main): ${joined%; }. Hooks, settings and skills load from it, and new worktrees copy its gitignored files, so bring it up to date (git -C \"$main\" switch main && git -C \"$main\" pull --ff-only) once its local changes are dealt with."

jq -n --arg m "$message" '{
    systemMessage: $m,
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $m }
}'
exit 0
