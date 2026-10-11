---
name: commit
description: Write and create a git commit in StreamIn — a Conventional Commits title, at most two short lines of body, and the mandatory Claude co-author trailer. Use for every commit in this repository.
---

# Commit

Every commit from October 2026 on shows Martín **and Claude** as authors on
GitHub. That's the point of the project's history: May's commits are Martín
alone; from Phase 2 on, each one documents the pairing.

## Steps

1. **Branch.** Commit on a feature branch, never `main` (a hook blocks it).
2. **Stage explicit paths** — no `git add -A` / `git add .`. Check
   `git diff --cached --stat` and leave out secrets, `.claude/settings.local.json`,
   build output and anything unrelated to the change.
3. **Write the message** in this exact shape:

   ```
   <type>(<scope>): <summary>

   <optional body: at most two short lines saying why>

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   ```

4. **Commit with a heredoc** so the whole message, trailer included, is visible
   in the command (the co-author hook checks it there):

   ```bash
   git commit -F - <<'EOF'
   fix(search): keep results when returning from Details

   The results screen's task re-fires on reappear; a repeated request now keeps them.

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   EOF
   ```

## The parts

- **type:** `feat`, `fix`, `refactor`, `test`, `docs`, `perf` or `chore` (tooling,
  configuration, the Claude Code setup).
- **scope** (optional): the package or area — `search`, `details`, `settings`,
  `watchlist`, `tmdb`, `design-system`, `reference-data`, `persistence`, `app`,
  `workflow`. Leave it out when the change spans several.
- **summary:** imperative, starts lowercase, no final period, 72 characters at
  most including the type. It says what changes for the user or the code, not
  which files were touched.
- **body:** optional. Plain sentences, at most two short lines, about *why*. No
  bullet lists, no "This commit…".
- **trailer:** always, exactly `Co-Authored-By: Claude <model> <noreply@anthropic.com>`,
  where `<model>` is the model pairing right now (e.g. `Opus 5.5`). The email is
  what makes GitHub show Claude as co-author — it belongs to Anthropic's `claude`
  account — so never remove or change it. No other trailers, no "Generated with"
  lines.

## Pull requests and squash merges

PRs are squash-merged with the PR title as the commit title plus ` (#N)`, and an
empty description. GitHub still copies the co-authors of the PR's commits into
the squash commit, so the badge reaches `main` as long as the branch's commits
carry the trailer. That makes the PR title a commit title too: same format,
65 characters at most to leave room for ` (#N)`.
