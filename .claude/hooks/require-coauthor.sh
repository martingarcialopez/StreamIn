#!/bin/bash
# PreToolUse(Bash): every commit is co-authored by Claude, so GitHub shows the
# pairing on each commit — and on squash merges, which inherit the co-authors
# of the PR's commits. Exit 2 blocks the commit and tells Claude why.

command=$(jq -r '.tool_input.command // empty')

# `git commit`, but not `git commit-tree` or a commit hash in `git show`.
commits='git[[:space:]][^;&|]*commit([[:space:]]|$)'
[[ "$command" =~ $commits ]] || exit 0

[[ "$command" == *"<noreply@anthropic.com>"* ]] && exit 0

echo "Blocked: every commit needs the trailer 'Co-Authored-By: Claude <model> <noreply@anthropic.com>' (see the commit skill). Pass the message with a heredoc or -m so the trailer is part of the command." >&2
exit 2
