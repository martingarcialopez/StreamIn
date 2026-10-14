---
name: start-issue
description: Start work on a StreamIn GitHub issue — read it and its milestone, plan when it's non-trivial, and create the branch. Use when Martín says "work on #12", "start issue 12" or similar.
argument-hint: <issue number>
---

# Start an issue

Work in StreamIn starts from a GitHub issue; the PR that finishes it closes it.
Call `gh` by its plain name, so the allow rules in `.claude/settings.json` match.
Pass `--json` to `gh issue view` and `gh pr view`: without a terminal they can
print nothing.

## 1. Read the issue

```bash
gh issue view <n> --json title,state,body,labels,milestone,comments
```

Note the milestone (the roadmap phase), labels, acceptance criteria and how to
verify. Read the matching section of `docs/roadmap.md` for the phase's design.
If the issue is closed, already has an open PR (`gh pr list --search "<n>"`), or
its acceptance criteria are missing or ambiguous, stop and ask Martín.

## 2. Plan

Non-trivial work (more than a couple of files, a new package, UI changes) goes
through plan mode first and waits for Martín's approval. A small, clear change
can start right away; say which files you'll touch.

## 3. Move into a worktree, then branch

Every session that changes the repository works in its own git worktree, so
parallel sessions never collide; the main checkout stays a control room for
planning and GitHub.

1. **If this session is in the main checkout** (`git rev-parse --absolute-git-dir`
   equals the absolute `--git-common-dir`), call **`EnterWorktree`** first, named
   `issue-<n>`. Do it **before any git command**: shell commands run wherever the
   session is, so a `git switch` here would switch the branch under every other
   session using the main checkout. Skip this only if Martín asks to work in the
   main checkout.

   `EnterWorktree` creates `.claude/worktrees/issue-<n>` from a freshly fetched
   `origin/main`, on branch `worktree-issue-<n>`, and copies the gitignored files
   in `.worktreeinclude` (the secrets).
2. **Name the branch** with the `commit` skill's rules
   (`feat/watchlist-heart-toggle`, `fix/details-offline-error`,
   `tooling/review-merge-gate`), renaming the worktree's branch:

   ```bash
   git branch -m <type>/<task>
   ```

   Don't switch to `main` from a worktree: it's checked out in the main
   checkout.

## 4. Work, then ship

- Check locally at the end of the task (CLAUDE.md, "How we work").
- Comment on the issue only for decisions Martín should see later
  (`gh issue comment <n> --body …`), not for progress.
- Open the PR with `Closes #<n>` — through `/ship-phase` when Martín asks, or the
  `commit` skill plus `gh pr create` for a small issue. CI and the automated
  review run on the PR; merging closes the issue.
