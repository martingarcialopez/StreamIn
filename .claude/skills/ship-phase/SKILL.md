---
name: ship-phase
description: Finish a roadmap phase or issue — review the branch, check it locally, log the workflow, commit, open the PR into main, and wait for CI before handing it to Martín.
disable-model-invocation: true
argument-hint: [phase title or issue number]
---

# Ship a phase

Only when Martín asks. Stop and report at the first step that fails.

## 1. Check the branch

Must be a feature branch (`feat/…`, `fix/…`, `chore/…`), never `main`. Show
`git status` and `git log --oneline main..HEAD`. Uncommitted work belongs to this
phase only if it's part of the plan — ask otherwise. Note the issue(s) the branch
closes (`gh issue view <n>`) so the PR can link them.

## 2. Review

Delegate to the `ios-reviewer` subagent with the branch diff. Fix CRITICAL and
HIGH findings, or explain why not. Keep MEDIUM/LOW for the PR's reviewer notes.

## 3. Check locally

Fast feedback before pushing; CI (step 6) is the record.

- **Build and tests** — Xcode MCP build tool if connected; otherwise the test plan
  that CI runs, which builds the app and every package's tests in one go:

  ```bash
  scripts/xcodebuild-locked.sh test -project StreamIn.xcodeproj -scheme StreamIn \
    -testPlan StreamIn -derivedDataPath .build/xcode
  ```

  The script is `xcodebuild` under a lock shared by all sessions, so parallel
  sessions' builds queue instead of competing for the CPU. Its default
  destination is this checkout's simulator (`scripts/worktree-simulator.sh`).

- **Previews** of every view the branch changed, with the Xcode MCP's
  `RenderPreview`. Look at each snapshot.

If something can't run, say so — never imply it passed.

## 4. Document

- CLAUDE.md: update architecture or decisions the phase changed.
- `docs/roadmap.md`: tick what shipped.
- `docs/workflow-log.md`: add the phase's entry — workflow pieces used, what they
  caught or saved, what Martín still had to find by hand.

## 5. Commit and open the PR

- Commit with the `commit` skill: one prompt where Martín approves (or edits)
  the message, and the commit is pushed. The PR title follows the commit format,
  gitmoji included.
- Once pushed, `gh pr create --base main` with a body that follows
  `.github/pull_request_template.md`, including `Closes #<n>` for each issue.
  Leave the CI box for step 6 and manual checks for Martín unticked.

## 6. Wait for CI

The `CI` workflow ("Build and test") and the review ("ios-reviewer verdict") run
on the PR, taking about 5 minutes. Don't block the conversation while they run:
watch them with the **Monitor** tool (deadline 30 minutes), e.g. `gh pr checks <n>
--watch`, and tell Martín you'll report when they finish, so he can keep talking
to you meanwhile. In the desktop app, its PR status works too.

- **Red:** read the failure (`gh run view <run-id> --log-failed`, or the job
  summary), fix it, commit with the `commit` skill, and wait again.
- **Green:** tick the CI box and paste the run link into the PR body
  (`gh pr edit <n> --body-file …`).

## 7. Hand over

Reply with the PR URL, the CI run link and result, and a suggested reading order
for the review.

In a `/parallel` session, add that once the PR is merged, `/parallel clean` (run
from the main checkout) removes this worktree, its branch and its simulator.
