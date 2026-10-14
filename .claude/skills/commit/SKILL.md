---
name: commit
description: Commit and push in StreamIn with a single confirmation from Martín — check there's something to commit on a well-named feature branch, write a gitmoji Conventional Commits message with the Claude co-author trailer, ask once to commit and push, then do both. Use for every commit in this repository.
---

# Commit

Every commit Claude makes shows Martín **and Claude** as authors on GitHub.
That's the point of the project's history: May's commits are Martín alone; from
October 2026 on, work done together documents the pairing. Martín commits work
he did alone himself, outside Claude — so a commit made through this skill is
always co-authored.

Martín confirms **once** per commit: one prompt covers the message, the commit
and the push.

## Steps

1. **Check there's something to commit.** Run `git status`. If the working tree
   is clean, tell Martín "Nothing to commit — the working tree is clean." and stop.

2. **Check the branch.** Run `git branch --show-current`. Committing to `main`
   is never an option (the `.githooks/pre-commit` hook refuses it, and GitHub
   rejects pushes to `main`). If you're on `main`, pick a branch name
   for the change — see **Branch names** — and include creating it in the prompt
   of step 5; don't ask separately.

3. **Stage explicit paths** that belong to this change — never `git add -A` or
   `git add .`. Run `git diff --cached --stat`, then read `git diff --cached` to
   understand what changed. Leave out secrets, `.claude/settings.local.json`,
   build output and unrelated edits; mention anything you left unstaged.

4. **Write the message** — see **Message format**.

5. **Ask once.** Show the message in a code block, then ask a single question
   with `AskUserQuestion`: *"Commit and push this to `<branch>`?"* — mentioning a
   new branch, or other unpushed commits that the push will include. Options:
   - **Yes** — commit and push;
   - **No** — stop; nothing is committed and the changes stay staged.

   If Martín answers with changes instead (free text), apply them and commit and
   push right away: his edit is the yes. Ask again only if the change is unclear.

6. **Commit with a heredoc,** so the message is passed exactly as approved:

   ```bash
   git commit -F - <<'EOF'
   🐛 fix(search): keep results when returning from Details

   The results screen's task re-fires on reappear; a repeated request now keeps them.

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   EOF
   ```

7. **Push:** `git push -u origin <branch>`. Report the commit hash and the branch.

When Claude runs in GitHub Actions (claude[bot]) there's nobody to ask: skip
step 5's prompt, commit, and push to the pull request's branch.

## Message format

```
<gitmoji> <type>(<scope>): <summary>

<optional body: at most two short lines saying why>

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

- **gitmoji:** always, from the table below, before the type.
- **type:** `feat`, `fix`, `refactor`, `test`, `docs`, `perf` or `chore` (tooling,
  configuration, the Claude Code setup).
- **scope** (optional): the package or area — `search`, `details`, `settings`,
  `watchlist`, `tmdb`, `design-system`, `reference-data`, `persistence`, `app`,
  `workflow`. Leave it out when the change spans several.
- **summary:** imperative, starts lowercase, no final period. The whole title,
  emoji included, is 72 characters at most. It says what changes for the user or
  the code, not which files were touched.
- **body:** optional. Plain sentences, at most two short lines, about *why*. No
  bullet lists, no "This commit…".
- **trailer:** always, exactly
  `Co-Authored-By: Claude <model> <noreply@anthropic.com>`, where `<model>` is the
  model pairing right now (e.g. `Opus 5.5`). The email is what makes GitHub show
  Claude as co-author — it belongs to Anthropic's `claude` account — so never
  shorten or drop it. No other trailers, no "Generated with" lines.

## Gitmoji

| Type | Emoji | | Type | Emoji |
|---|---|---|---|---|
| `feat` | ✨ | | `perf` | ⚡️ |
| `fix` | 🐛 | | `test` | ✅ |
| `refactor` | ♻️ | | `docs` | 📝 |
| `chore` | 🔧 | | | |

One exception: a commit that only removes code or files (dead code, template
tests) takes 🔥 whatever its type, as gitmoji intends.

Emoji go in commit and PR titles, never in branch names.

## Branch names

`<type>/<task>`: the same types as commits, and a task of three or four
hyphenated words that says what this branch does. Be specific —
`feat/watchlist-heart-toggle`, `fix/search-field-flicker` — not
`feat/update-details` or `chore/changes`. One roadmap phase is one branch.

## Pull requests and squash merges

PRs are squash-merged with the PR title as the commit title plus ` (#N)`, and an
empty description. So the PR title is a commit title too: same format, gitmoji
included, 65 characters at most to leave room for ` (#N)`. GitHub copies the
co-authors of the PR's commits into the squash commit, so the badge reaches
`main` as long as the branch's commits carry the trailer.

---

The empty-tree check, branch naming, confirmation before committing and pushing,
and gitmoji are adapted from Carlo van Wyk's
[commit-message skill](https://github.com/thecarlo/carlo-marketplace) (MIT,
© 2026 Carlo van Wyk); the emoji mapping follows [gitmoji](https://gitmoji.dev).
