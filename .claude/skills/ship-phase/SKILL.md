---
name: ship-phase
description: Finish a roadmap phase — review the branch, verify build and tests, log the workflow, commit, and open the PR into main for Martín's review.
disable-model-invocation: true
argument-hint: [phase title]
---

# Ship a phase

Only when Martín asks. Stop and report at the first step that fails.

## 1. Check the branch

Must be a feature branch (`feat/…`, `chore/…`), never `main`. Show `git status`
and `git log --oneline main..HEAD`. Uncommitted work belongs to this phase only
if it's part of the plan — ask otherwise.

## 2. Review

Delegate to the `ios-reviewer` subagent with the branch diff. Fix CRITICAL and
HIGH findings, or explain why not. Keep MEDIUM/LOW for the PR's reviewer notes.

## 3. Verify

- **App build** — Xcode MCP build tool if connected; otherwise the desktop app's
  simulator build tool; otherwise:

  ```bash
  xcodebuild -project StreamIn.xcodeproj -scheme StreamIn \
    -destination 'platform=iOS Simulator,name=<iPhone from xcrun simctl list devices available>' \
    -derivedDataPath .build/xcode build
  ```

- **Tests** for every package the diff touches, from the package directory
  (`swift test` can't run these iOS-only packages on macOS):

  ```bash
  xcodebuild test -scheme <Package> \
    -destination 'platform=iOS Simulator,name=<iPhone>' -derivedDataPath ../../.build/xcode-<Package>
  ```

Record the result per package (tests passed / failed). If something can't run,
say so — never imply it passed.

## 4. Document

- CLAUDE.md: update architecture or decisions the phase changed.
- `docs/workflow-log.md`: add the phase's entry — workflow pieces used, what they
  caught or saved, what Martín still had to find by hand.

## 5. Commit and open the PR

- Commit with the `commit` skill: one prompt where Martín approves (or edits)
  the message, and the commit is pushed. The PR title follows the commit format,
  gitmoji included.
- Once pushed, `gh pr create --base main` with a body that
  follows `.github/pull_request_template.md`. Tick only test-plan items that step 3
  verified; leave manual checks for Martín unticked.

## 6. Hand over

Reply with the PR URL and a suggested reading order for the review.
