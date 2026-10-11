# Workflow log

How StreamIn is built with Claude Code, and what each change to the workflow
actually improved. Newest first. Numbers are what was observed, not estimates.

## Per-phase scorecard

| Phase | PR | Planned first | Reviewer findings fixed before PR | Verified before PR | Bugs found by Martín after hand-off | Review rounds |
|---|---|---|---|---|---|---|
| 2 — Caching, search fixes | [#1](https://github.com/martingarcialopez/StreamIn/pull/1) | Yes (plan mode) | — (no reviewer yet) | No — build and 65 tests verified a week later | 2 | 1 (iPad support) |

---

## 2026-10-11 — The roadmap moves into the repo

- **`docs/roadmap.md`** replaces a plan file that lived in `~/.claude/plans/` on
  Martín's Mac: invisible to the terminal Claude, to claude[bot] and to anyone
  reading the repo, and already stale (old dates, finished phases still open, a
  Phase 3 design that broke the "no SwiftData in features" rule). CLAUDE.md now
  points every session to it.
- **Second guard-hook false positive:** deleting the merged branch
  `chore/commit-skill` while on `main` was blocked because the branch name
  contains "commit". `commit`/`push` now have to be whole words; 17 cases pass.

---

## 2026-10-11 — Commits made pairing are co-authored

**Why:** the history should show the pairing at a glance. May's commits list
Martín alone even though Claude was already helping; from October on, every
commit made pairing with Claude lists Martín *and* Claude. Work Martín does
alone stays his alone.

**What changed**

- `commit` skill: Conventional Commits title (72 characters at most), at most two
  short body lines, and always `Co-Authored-By: Claude <model> <noreply@anthropic.com>`.
  The trailer names the model that paired on the commit.
- Mashed up with a third-party skill (Carlo van Wyk's `commit-message`, MIT) after
  reading it instead of installing it: kept its empty-tree check, specific branch
  names, approval and push prompts (merged into one prompt) and opt-in gitmoji;
  dropped its "never add a co-author" rule, stage-everything offer, 50-character
  titles and bullet-list bodies, which contradict this project's rules.
- No enforcement hook. A `require-coauthor` hook was tried and removed on Martín's
  request: he must be able to push his own code without Claude's signature, so
  the skill alone carries the rule for Claude's commits.
- Martín cut the confirmation to one action: gitmoji always (no question), and a
  single "commit and push this to `<branch>`?" prompt — editing the message in the
  answer counts as yes. Choosing the emoji, approving the message and approving
  the push had been three decisions per commit.
- No "my own work" option: whatever is done together is always co-authored;
  Martín commits work he did alone himself, outside Claude.
- First `@claude` round trip: Martín asked for the removal in a review comment on
  #5; claude[bot] deleted the hook, updated CLAUDE.md and this log and pushed in
  44 s. It can't write to `.claude/skills/` from GitHub Actions, so the skill text
  was aligned locally.
- `ship-phase` now commits through the skill.

**Decisions**

- **The email stays.** GitHub only shows a co-author when the trailer's email
  belongs to a GitHub account; `noreply@anthropic.com` is Anthropic's `claude`
  account. #2's squash had it removed, so GitHub shows no co-author there.
- **`claude` for pairing, `claude[bot]` for GitHub automation.** Commits made
  pairing locally point at the `claude` account; reviews and `@claude` fixes on
  GitHub come from the `claude[bot]` app.
- **No history rewrite.** #2 and #3 predate the rule and show Martín alone.
  Fixing them would mean force-pushing `main`, losing GitHub's Verified badges
  and breaking the merged-commit links on PRs #2–#4.
- **Squash merges keep the co-author.** With the repo's squash default (PR title
  + empty description), GitHub still copies the PR commits' co-authors into the
  squash commit — verified on #4.

---

## 2026-10-11 — Claude gets its own GitHub identity

**Why:** review conversations on #1 showed one account talking to itself
(Martín's comments and replies signed "— Claude Code"); resolved threads are
also collapsed, so the collaboration was invisible to anyone browsing the repo.

**What changed**

- Claude GitHub app installed with `/install-github-app`; it authenticates with
  Martín's Claude subscription (`CLAUDE_CODE_OAUTH_TOKEN` secret), so there's no
  separate API billing. From now on it acts on GitHub as **claude[bot]**.
- `claude.yml`: `@claude` in a PR comment, review or issue makes claude[bot] answer
  or push a fix. Only the repository owner can trigger it; extra instructions tell
  it that it can't build iOS on Linux, to follow CLAUDE.md, keep commits short and
  never push to `main`.
- `claude-code-review.yml`: Anthropic's official `code-review` plugin (multi-agent,
  checks CLAUDE.md compliance, reports only high-confidence issues) reviews each PR
  once — when opened, reopened or marked ready, not on every push. Drafts skipped.
- The `after-edit` hook skips cleanly where Apple tools don't exist, since project
  hooks also load when Claude runs in GitHub Actions.

**Decisions**

- **Two reviewers, not one copied twice.** `ios-reviewer` runs locally before a PR
  with the project checklist; the official plugin reviews independently on GitHub.
  Duplicating `ios-reviewer` in CI would have added nothing.
- **Review on open only.** Re-reviewing on every push would burn usage and bury the
  conversation; `@claude review` asks for another pass when it's worth it.
- **Known limit:** GitHub's Linux runners can't build the app, so verification stays
  on the Mac until a macOS CI job exists.

---

## 2026-10-11 — First review round on a PR

**What happened:** Martín's review of #1 had two comments with one request:
ship on iPad as well as iPhone. It reversed the iPhone-only change made
during Phase 2 — a product decision, caught before it reached `main`, which
is exactly what the review gate is for. Fixed in one commit (device family
`1,2`, all four iPad orientations restored), built for an iPad simulator,
then merged into the stacked #2 branch (a merge, not a rebase, so nothing
was force-pushed).

**Lessons**

- **Stacked PRs hide the tooling.** The `.claude/` setup lives on #2's branch,
  so switching to #1's branch to fix the review removed the hooks, skills and
  settings from disk: the fix was made without guard rails and validated by
  hand. Land workflow changes first, before stacking feature work on them.
- **Xcode MCP needs Xcode itself.** The `xcode` server registered but exposed no
  tools because Xcode wasn't open and allowing agents; the simulator build tool
  covered it.
- **Simulator runtimes matter.** The first iPad simulator booted ran iOS 17.4,
  below the app's iOS 26.2 minimum, so the build failed before compiling.
  Check the runtime (`xcrun simctl list devices available`) before booting.
- **First hook false positive.** The main-branch guard blocked
  `git push && gh pr edit 2 --base main`: its pattern saw `push` and, later on the
  line, `main`. Patterns now stop at `&&`, `;` and `|`, and also catch
  `git push origin HEAD:main`, which slipped through before. 12 regression cases pass.
- **Skills load live.** Once `.claude/skills/` was back on disk, `localize` and
  `new-package` appeared mid-session; `ship-phase` stays hidden until invoked
  because it's user-only (`disable-model-invocation`).

---

## 2026-10-04 — Workflow foundation

**Why:** Phase 2 worked, but every safety net was a person. Two UI bugs reached
manual testing, code was handed over unbuilt, and repetitive steps were done by
hand. CLAUDE.md had also drifted from the code.

**What changed**

- **Shared Claude Code setup in git.** `.claude/` used to be ignored entirely; now
  settings, rules, skills, agents and hooks are committed. Personal settings and
  worktrees stay local.
- **CLAUDE.md rewritten.** It was wrong in six places: it said DesignSystem didn't
  exist yet, listed Persistence as existing, kept an "only outermost packages"
  rule the project contradicts, referenced a deleted `ContentView`, planned a
  search-history store that was dropped, and recommended `swift test`, which
  can't run these iOS-only packages. Long reference material moved to
  path-scoped rules in `.claude/rules/`, loaded only when matching files are touched.
- **Skills, with tested scripts.**
  - `localize`: adds a key in en + es and regenerates symbols. The script
    round-trips Xcode's catalog format byte for byte (5 of 6 catalogs) and
    preserves the other style, so diffs show only the new key; it refuses a
    missing translation.
  - `new-package`: scaffolds a package and registers it in the Xcode project.
    Re-adding `ReferenceData` with the script produced exactly the eight entries
    written by hand in Phase 2 (modulo IDs).
  - `ship-phase`: review → verify → log → commit → PR.
- **Hooks**, tested against 13 cases: block commits/pushes to `main`; block
  edits to generated symbols and secrets; regenerate string symbols after any
  catalog edit; `plutil -lint` after any `project.pbxproj` edit.
- **`ios-reviewer` subagent**: read-only review against the project rules before
  every PR.
- **Xcode MCP** (`.mcp.json` → `xcrun mcpbridge`): build, test, previews and Apple
  docs from Claude Code.
- **Verify at the end of each task** replaces "never build or test unless asked".
  First run, on PR #1: app build in 77 s, 65 unit tests passing across 5 packages.

**Decided against**

- **Format-on-edit with `swift-format`.** Measured on a copy: it would rewrite 42
  of 60 files (~200 lines) — dropping column alignment, reordering imports,
  changing `public extension` style, and splitting one `return` from its value.
  Noise in every PR outweighed the benefit. Revisit with SwiftLint if style drifts.
- **Build/test hooks on every turn.** About 1–2 minutes per turn on this Mac;
  verifying once per task catches the same problems.

**Measure in Phase 3:** findings caught by the reviewer vs by Martín, manual steps
avoided (package wiring, symbol regeneration), review rounds per PR.

---

## 2026-09-28 — Phase 2: plan mode and PR per phase

- Audit of the codebase with an Explore subagent, then a phased roadmap written
  in plan mode with a timeline, revised with Martín before any code.
- First pull request instead of committing to `main`, with reviewer notes and a
  test plan.

**What went wrong**

- Two UX bugs only surfaced in Martín's manual test: the Settings button missing
  on pushed screens, and the search field collapsing right after results loaded.
  Nothing checked the UI before hand-off.
- The plan put `ProviderCatalog` in TMDBClient, which would have broken the
  layer rule. Caught by re-reading CLAUDE.md mid-implementation, not by tooling.
- Registering the new package meant writing eight `project.pbxproj` entries by hand.
- Code was handed over unbuilt; compile and tests were only verified a week later.
- The auto-mode permission check timed out repeatedly, blocking edits for several turns.

---

## May 2026 — Baseline (Phases 0–1)

- Claude Code sessions, some in worktrees; every commit straight to `main`.
- `.claude/` fully gitignored: no shared settings, skills, hooks or agents. All
  context lived in CLAUDE.md, which drifted from the code over time.
- Verification by Martín in Xcode; a "never run tests unless asked" rule meant
  agent sessions never built the app themselves.
