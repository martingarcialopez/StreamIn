---
name: commit
description: Create a git commit in StreamIn — check there's something to commit and that it's on a well-named feature branch, write a Conventional Commits message with the Claude co-author trailer for paired work (gitmoji on request), get Martín's approval, then offer to push. Use for every commit in this repository.
---

# Commit

Commits made pairing with Claude show Martín **and Claude** as authors on
GitHub. That's the point of the project's history: May's commits are Martín
alone; from October 2026 on, paired work documents the pairing. Work Martín did
on his own stays his own — no trailer.

## Steps

1. **Check there's something to commit.** Run `git status`. If the working tree
   is clean, tell Martín "Nothing to commit — the working tree is clean." and stop.

2. **Check the branch.** Run `git branch --show-current`. Committing to `main`
   is never an option (a hook blocks it). If you're on `main`, propose a branch
   named after the change — see **Branch names** — and create it with
   `git switch -c <name>` once Martín agrees.

3. **Stage explicit paths** that belong to this change — never `git add -A` or
   `git add .`. Run `git diff --cached --stat`, then read `git diff --cached` to
   understand what changed. Leave out secrets, `.claude/settings.local.json`,
   build output and unrelated edits; mention anything you left unstaged.

4. **Write the message** — see **Message format**.

5. **Ask for approval, and whether to push, in one prompt.** Show the message in
   a code block, then ask (with `AskUserQuestion`):
   - *Commit?* — **Commit**, **Commit with gitmoji**, **Commit as my own work**
     (no co-author trailer), or change something (free text).
   - *Push afterwards?* — **Push to origin**, or **Don't push yet**.

   Don't run `git commit` or `git push` without these answers. If Martín asks for
   changes, revise and ask again.

6. **Commit with a heredoc,** so the whole message is passed exactly as approved:

   ```bash
   git commit -F - <<'EOF'
   fix(search): keep results when returning from Details

   The results screen's task re-fires on reappear; a repeated request now keeps them.

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   EOF
   ```

7. **Push if Martín said so:** `git push -u origin <branch>`. Report the commit
   hash and, if pushed, the branch on GitHub.

When Claude runs in GitHub Actions (claude[bot]) there's nobody to ask: skip
step 5's prompt, commit, and push to the pull request's branch.

## Message format

```
<type>(<scope>): <summary>

<optional body: at most two short lines saying why>

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

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
- **trailer:** on every commit of work done pairing, exactly
  `Co-Authored-By: Claude <model> <noreply@anthropic.com>`, where `<model>` is the
  model pairing right now (e.g. `Opus 5.5`). The email is what makes GitHub show
  Claude as co-author — it belongs to Anthropic's `claude` account — so never
  shorten it. Leave the trailer out only when Martín says the change is his own
  work. No other trailers, no "Generated with" lines.

## Gitmoji (only when Martín asks)

Plain messages by default. When Martín picks **Commit with gitmoji** — or asks
for emoji in his request — put the emoji before the type:
`✨ feat(watchlist): add the heart toggle on Details`.

| Type | Emoji | | Type | Emoji |
|---|---|---|---|---|
| `feat` | ✨ | | `perf` | ⚡️ |
| `fix` | 🐛 | | `test` | ✅ |
| `refactor` | ♻️ | | `docs` | 📝 |
| `chore` | 🔧 | | | |

Emoji go in commit titles only, never in branch names, and PR titles stay plain
so squash titles keep the `type(scope): summary` shape.

## Branch names

`<type>/<task>`: the same types as commits, and a task of three or four
hyphenated words that says what this branch does. Be specific —
`feat/watchlist-heart-toggle`, `fix/search-field-flicker` — not
`feat/update-details` or `chore/changes`. One roadmap phase is one branch.

## Pull requests and squash merges

PRs are squash-merged with the PR title as the commit title plus ` (#N)`, and an
empty description. GitHub still copies the co-authors of the PR's commits into
the squash commit, so the badge reaches `main` as long as the branch's commits
carry the trailer. That makes the PR title a commit title too: same format,
65 characters at most to leave room for ` (#N)`.

---

The empty-tree check, branch naming, approval and push prompts and opt-in
gitmoji are adapted from Carlo van Wyk's
[commit-message skill](https://github.com/thecarlo/carlo-marketplace) (MIT,
© 2026 Carlo van Wyk); the emoji mapping follows [gitmoji](https://gitmoji.dev).
