# Workflow log

How StreamIn is built with Claude Code, and what each change to the workflow
actually improved. Newest first. Numbers are what was observed, not estimates.

## Per-phase scorecard

| Phase | PR | Planned first | Reviewer findings fixed before PR | Verified before PR | Bugs found by Martín after hand-off | Review rounds |
|---|---|---|---|---|---|---|
| 2 — Caching, search fixes | [#1](https://github.com/martingarcialopez/StreamIn/pull/1) | Yes (plan mode) | — (no reviewer yet) | No — build and 65 tests verified a week later | 2 | 1 (iPad support) |

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
