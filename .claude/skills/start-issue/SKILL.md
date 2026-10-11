---
name: start-issue
description: Start work on a StreamIn GitHub issue — read it and its milestone, plan when it's non-trivial, and create the branch. Use when Martín says "work on #12", "start issue 12" or similar.
argument-hint: <issue number>
---

# Start an issue

Work in StreamIn starts from a GitHub issue; the PR that finishes it closes it.
`gh` lives at `/opt/homebrew/bin/gh` (not on the Bash tool's PATH).

## 1. Read the issue

```bash
gh issue view <n> --comments
```

Note the milestone (the roadmap phase), labels, acceptance criteria and how to
verify. Read the matching section of `docs/roadmap.md` for the phase's design.
If the issue is closed, already has an open PR (`gh pr list --search "<n>"`), or
its acceptance criteria are missing or ambiguous, stop and ask Martín.

## 2. Plan

Non-trivial work (more than a couple of files, a new package, UI changes) goes
through plan mode first and waits for Martín's approval. A small, clear change
can start right away; say which files you'll touch.

## 3. Branch from an up-to-date main

```bash
git switch main && git pull --ff-only origin main
git switch -c <type>/<task>
```

Name the branch with the `commit` skill's rules (`feat/watchlist-heart-toggle`,
`fix/details-offline-error`). If `main` has uncommitted changes, ask before
switching. In a worktree the app made, sync with the base branch through the app
instead of pulling.

## 4. Work, then ship

- Check locally at the end of the task (CLAUDE.md, "How we work").
- Comment on the issue only for decisions Martín should see later
  (`gh issue comment <n> --body …`), not for progress.
- Open the PR with `Closes #<n>` — through `/ship-phase` when Martín asks, or the
  `commit` skill plus `gh pr create` for a small issue. CI and the automated
  review run on the PR; merging closes the issue.
