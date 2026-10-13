---
name: parallel
description: Start an issue, or a task described in plain words, in a parallel Claude session that has its own worktree, simulator and Xcode window and shows up in `claude agents`, or clean up the sessions whose PRs are done. Use when Martín says "/parallel 35", "/parallel <some task>", "start #35 in parallel", "do this in another session", or "clean up the parallel sessions".
argument-hint: <issue number> | <task description> | clean
---

# Parallel sessions

Every session that changes StreamIn works in its own git worktree under
`.claude/worktrees/` (CLAUDE.md, "Parallel sessions"). A new task in agent view,
or `/start-issue` in any session, already moves into one with `EnterWorktree`.
This skill is the shortcut on top of that:

- `claude --bg -w <name>` starts the session **inside** its worktree from the
  first command, named after the issue or task, and visible in `claude agents`.
- A task in plain words is turned into an issue first.
- `clean` removes what finished sessions leave behind.

What every worktree session gets without this skill:
- **The gitignored secrets:** `.worktreeinclude` copies them.
- **Shared memory and approvals.**
- **Its own simulator:** `scripts/worktree-simulator.sh`.
- **Queued builds:** `scripts/xcodebuild-locked.sh`.

`gh` is at `/opt/homebrew/bin/gh`. Run this skill from the **main checkout**.

The argument decides the mode:

- **`35` or `#35`:** start that issue.
- **`clean`:** cleanup.
- **Anything else:** a task description, which becomes an issue first.

## Start an issue: `/parallel <n>`

1. **Check the issue.** `gh issue view <n> --json state,title,labels,milestone`.
   Stop and tell Martín if:
   - the issue is closed
   - a PR for it is already open (`gh pr list --search "<n>" --state open`)
   - `.claude/worktrees/issue-<n>` already exists (`git worktree list`)
2. **Dispatch the session**, from the repository root:

   ```bash
   claude --bg -w issue-<n> -n "#<n> <short title>" "/start-issue <n>"
   ```

   - **The name** (`-n`) is what agent view shows. Keep it under about 40
     characters, e.g. `#35 Watchlist tab`.
   - **The session starts working right away:** `/start-issue` reads the issue,
     renames the branch to `<type>/<task>`, plans, and stops at its first
     question (plan approval) with "Needs input".
3. **Report** the session id and name, and how to open it: `claude agents` (or
   `claude attach <id>`). When the session first needs the Xcode MCP, it opens
   its worktree's project, and Xcode may ask to allow the agent.

## Start a task: `/parallel <task description>`

Work starts from an issue, so the new session writes one first. Writing it there,
not here, means `/parallel` returns at once.

1. **Name it.** A worktree name `task-<three or four words>` (lowercase,
   hyphens), e.g. `task-readme-details-screenshots`, and a session name under
   about 40 characters, e.g. `README: Details screenshots`. Stop if
   `.claude/worktrees/<name>` already exists.
2. **Dispatch the session** with Martín's text, unchanged, inside the prompt.
   Single-quote it for the shell, writing each `'` as `'\''`:

   ```bash
   claude --bg -w task-<words> -n "<short title>" 'Martín asked for this task, in his words:

   <the task description>

   First turn it into a GitHub issue with gh issue create, using the Task form sections (### Goal, ### Acceptance criteria, ### How to verify, ### Packages touched, ### Out of scope). Add a milestone only if one clearly fits, and labels as the form suggests. Then follow the start-issue skill for that new issue.'
   ```

3. **Report** as for an issue, adding that the session writes the issue first:
   its link shows up in the session's first messages.

## Clean: `/parallel clean`

Removes what finished sessions leave behind. **Ask Martín before removing
anything**, and never remove a worktree with uncommitted changes or unpushed
commits.

1. **Inventory.** For each worktree under `.claude/worktrees/` (from
   `git worktree list --porcelain`), collect:
   - **the branch:** `git -C <path> branch --show-current`
   - **its PR:** `gh pr list --head <branch> --state all --json number,state,title`
   - **uncommitted changes:** `git -C <path> status --porcelain`
   - **unpushed commits:**
     - if `origin/<branch>` exists: `git -C <path> rev-list --count origin/<branch>..HEAD`
     - otherwise: any commits beyond `origin/main` count as unpushed
   - **its session**, if any: match on `cwd` in `claude agents --json --all`
2. **Propose.** A worktree is removable when its PR is merged or closed, it has
   no uncommitted changes, and nothing is unpushed. Show the table (worktree,
   branch, PR and state, session status, removable or why not). Ask once, with
   `AskUserQuestion`, which ones to remove.
3. **Remove each one chosen:**
   - **With a session:** `claude stop <id>` if it's still running, then
     `claude rm <id>`. That removes the worktree, and the branch when it's
     still `worktree-<name>`.
   - **Without one:** `git worktree remove <path>`.
   - **The renamed branch,** if it still exists: `git branch -D <branch>`. Its
     PR is merged or closed, so the work is on GitHub.
   - **The simulator:** `xcrun simctl delete "StreamIn <name>"`.
4. **Orphans.** Simulators named `StreamIn <name>` whose worktree no longer
   exists are leftovers: list them and delete them in the same confirmation.
5. **Report** what was removed and what was kept, and why.

Worktrees outside `.claude/worktrees/` (made by hand, like the old
`../StreamIn-phase4`) aren't this skill's to clean; mention them if they look
finished.
