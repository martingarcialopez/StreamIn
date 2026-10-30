# Workflow log

How StreamIn is built with Claude Code, and what each change to the workflow
actually improved. Newest first. Numbers are what was observed, not estimates.

## Per-phase scorecard

| Phase | PR | Planned first | Reviewer findings fixed before PR | Verified before PR | Bugs found by Martín after hand-off | Review rounds |
|---|---|---|---|---|---|---|
| 2 — Caching, search fixes | [#1](https://github.com/martingarcialopez/StreamIn/pull/1) | Yes (plan mode) | — (no reviewer yet) | No — build and 65 tests verified a week later | 2 | 1 (iPad support) |
| 3 — Watchlist data layer (#30) | [#42](https://github.com/martingarcialopez/StreamIn/pull/42) | Yes (plan mode, then issues) | 3 medium + 2 low of 5 | Yes — CI green; each fix mutation-checked | 0 | 0 |
| 3 — Heart on Details (#34) | [#43](https://github.com/martingarcialopez/StreamIn/pull/43) | Yes (issue) | 2 low of 2 | Yes — CI, 3 previews, Martín's simulator checks | 0 (the placeholder tab read as one) | 0 |
| 3 — Watchlist tab (#35) | #35's PR | Yes (plan mode; Martín added the write-failure alert) | 1 medium + 1 low of 2 | Yes — full test plan, 3 previews (light, dark, XXX Large), launch in es; swipe flows left to Martín | — | — |
| 4 — Details redesign (#36) | [#50](https://github.com/martingarcialopez/StreamIn/pull/50) | Yes (issue, then a plan-mode design Q&A) | 1 medium + 10 low of 13 (two were merge notes) | Yes — full test plan + 7 previews, light, dark, XXX Large | — | — |
| 5 — Landing page (#46) | #46's PR | Yes (issue, then three design Q&As, two in plan mode) | 3 medium + 2 low of 5 | Yes — full test plan (267 tests), previews, SE and iPad simulators in en and es, spin recordings | — | — |
| 5 — Watchlist tab (#48) | #48's PR | Yes (issue, a one-round design Q&A, then plan mode) | 1 medium + 1 low of 2 | Partly — full test plan before and after merging #85's branch, 5 previews; simulator left to Martín | — | — |

---

## 2026-10-30 — Translation review in a spreadsheet (#87)

**What shipped:** `scripts/translations.sh export` writes every on-screen string
to an `.xlsx`, one sheet per screen, where a reviewer who isn't a developer
edits the English and Spanish copy in place; `import` writes the edits back to
the String Catalogs.
`scripts/translator-preview.sh` opens the app in the simulator in one language
next to the sheet.

**Workflow pieces used**
- **Two questions before the plan:** a workbook rather than a web page or CSVs,
  and the simulator on Martín's Mac rather than TestFlight. Then the plan in the
  conversation and an issue written from it.
- **Screens come from the code:** a key goes to the screen of the Swift file that
  uses its symbol, so only `screens.json` (file → screen) is maintained by hand,
  and a new view missing from it fails the export.

**What the checks caught**
- **Six keys no Swift file uses** (`settingsSubscriptionsMajor` and five more):
  left out of the workbook, listed by the export.
- **A dry run on the real catalogs** refused a `%2$lld` turned into `%2$@` and
  wrote nothing; the real import changed only the value lines.
- **Domain's committed symbols were stale:** today's `xcstringstool` adds
  `nonisolated` to one line. Any import touching Domain regenerates it; harmless.
- **The Spanish errors use "usted"** while the rest of the app uses "tú": the
  first thing for the reviewer to fix.
- **`ios-reviewer`, 1 medium:** a plural key would have been flattened by an
  import, losing its forms. Plural keys are now left out and refused. **4 low**
  fixed too: `%d` no longer passes for `%lld`, catalogs are all written before
  symbols regenerate, a new pin rebuilds the venv, and the doc has a Spanish part.
- **Martín, after the first export:** no "proposal" columns. The reviewer edits
  the English and Spanish cells in place; hidden copies of the exported text
  keep the change and staleness checks working.
- **The preview script, run for real:** the first launch showed "Disponibles en
  Francia", since the default region comes from the simulator's locale. It now
  passes `-AppleLocale` with the language, so es opens in Spain and en in the US.

---

## 2026-10-30 — The Watchlist tab answers "what can I watch tonight" (#48)

**What shipped:** each saved movie shows Search's provider line. The derivation
moved to Domain (`WatchSummary`) and the line to DesignSystem (`ProviderLine`), so
two features share them without importing each other. The tab also got a new
empty state and the look of Search.

**Workflow pieces used**
- **A one-round design Q&A**: four questions, each with a recommended option.
  Martín took all four. The plan followed in plan mode.
- **`ios-reviewer` before the PR.**
- **Merging an open PR's branch:** #85 (the cinema theme) was still open. Its PR
  body carried a "merge note for #48" listing what this branch would need, and
  every item on it was right: `trendingMovies()` in the new fakes, `.cinemaRow()`,
  `AbroadMark` in the shared line, and three small conflicts.

**What the checks caught**
- **`ios-reviewer`, 1 medium:** the view model lives as long as the app, so rows
  that loaded once never refreshed. Pull to refresh now asks again for every
  row.
- **`ios-reviewer`, 1 low:** no test covered an old region's answer landing after
  the new region's. A gated fake now holds that request back. The test was
  mutation-checked: it fails with the guard removed.
- **Previews:** the first snapshot of every Watchlist preview was blank, because
  `.task` hadn't loaded the store yet. A second render was always complete, as
  `pr-screenshots` already says.

**What got in the way**
- An inline SF Symbol can't go through generated string symbols: `%@` takes a
  `String`. The empty state's hint names the heart in words instead.
- In this worktree session, a heredoc piped into `python3 -I -` was refused;
  the same edit went through with the Edit tool.

---

## 2026-10-30 — Phase 5 starts: the landing page (#46)

**What shipped:** the slot machine landing page, trending movies through Domain and
TMDBClient, and an app-wide dark "cinema" look in DesignSystem.

**Workflow pieces used**
- **Design Q&As** with `AskUserQuestion`, previews attached, in three rounds:
  - the first direction (a halo, a popcorn mark with a globe badge)
  - the slot machine
  - its slot-machine cues
- **Then about a dozen rounds on Martín's simulator screenshots.** Each one was
  checked on dedicated `StreamIn issue-46 SE` and `iPad` simulators with
  `simctl` screenshots, in en and es.
- **Screen recordings for motion.** `simctl io recordVideo`, then a small
  AVFoundation script pulled frames every 0.25 s and tiled them into one image
  (no ffmpeg on the Mac). Static previews can't judge an animation.
- **`/parallel` mid-session:** a background session drafted the Phase 6 issues
  while this one kept designing.

**What the checks caught**
- **The recording caught a bug no preview could show.** A `visualEffect` drum read
  the layout's final position mid-animation, so the reels went blank while they
  spun. The fix: an `Animatable` drum.
- **Screenshots caught a geometry bug that a test had "passed".** The barrel outline
  grew ears at its corners, because a cylinder's visible edge sits at about 72°,
  not 90°. The test checked the window against the wrong edge.
- **Repeated launches cleared a false alarm.** Prime Video landed three times out
  of three. Four more launches showed four different results, so it was chance.
- **The self-review before shipping found a real bug:** a cancelled first load
  left the reels on placeholders for the whole session. There's now a test for it.

**What Martín found by hand:** taste, which no tool checks. That covered the
first direction, a lever and glass that didn't fit, the barrel shape, and the
knob, three times. On his screenshots Claude found the seam under Details'
backdrop (the new spotlight against the backdrop's fade), the cool greys on the
warm page, and the repeated Settings headers.

**What got in the way**
- In a worktree session, Claude Code refuses heredocs, `cd … &&` chains and
  `git -C` into another worktree. Writing files with the tools and running scripts
  with `python3 -I` worked.
- `RenderPreview` failed now and then on `SearchResultsView` with a design-time
  thunk error (`__designTimeSelection`). A retry rendered it.
- The canvas's default light appearance overrides `.preferredColorScheme(.dark)`
  for navigation chrome, so dark-only screens need the Dark variant to preview
  faithfully.

---

## 2026-10-29 — `new-package` writes the project file the way Xcode does

**What broke:** `add_local_package.py` appended its objects at the end of each section, but Xcode keeps sections sorted by ID. The next time Xcode saved the project, it moved the Persistence and Watchlist entries, which left an unexplained change to `project.pbxproj` in the main checkout.

**Fix:** the script now inserts each object in ID order. A dry run on a copy of the project added two packages, and every section stayed sorted.

---

## 2026-10-14 — Screenshots in the PR description (part of #8)

**Why:** Martín asked for PRs that change a screen, or add one, to show it in
the description. Reviewing a UI change meant checking the branch out, and the
Phase 2 bugs Martín found by hand were UI bugs.

**What changed**
- **The `pr-screenshots` skill**, run by `ship-phase` after the PR opens:
  - It picks the previews of the screens the branch changed or added.
  - It renders them with `RenderPreview` on the branch, then on the merge base. Both use the same worktree and Xcode window, through `git switch --detach`.
  - It writes a before/after table into the PR body between markers, so a re-run replaces it.
- **Compact on purpose:**
  - Before and after sit side by side, each image at 180 px.
  - A new screen shows "new" in the before column.
  - Past 3 screens, the rest fold into a `<details>` section.
- **Hosting:** GitHub has no API to attach an image to a PR body, so
  `scripts/publish-screenshots.sh` pushes the PNGs to an orphan
  `pr-screenshots` branch, scaled to 800 px. It builds the commit with git plumbing on a temporary
  index, so the checkout is never touched. It rebuilds on top when a parallel
  session pushed first. The URLs are pinned to the commit.

**What the build-out found**
- **`RenderPreview` returns `previewSnapshotPath`:** a PNG on disk, 689×1500 for a
  full screen. Without a file there would be nothing to publish.
- A fresh worktree's first render failed with "cannot find `GeneratedSecrets`".
  The second render passed. The skill says to retry.
- Opening the project re-sorted `project.pbxproj` again (6 lines). The skill
  restores it before switching commits.
- macOS's bash 3.2 treats an empty array as unbound under `set -u`. That broke the
  first publish, when the branch had no parent commit yet.

**Left for #8:** the UI test (search → details → providers) and the
`ios-reviewer` check for preview fakes that `fatalError`.

---

## 2026-10-14 — Phase 3 ships: the Watchlist (#35)

**What shipped:** five PRs.
- #42: the data layer
- #39 and #40: `MoviePoster` and the directors formatter, by claude[bot]
- #43: the heart
- #35's PR: the tab, plus one app-wide alert for failed writes

**Measured, as Phase 2's entry asked:**
- **Reviewer vs Martín:** `ios-reviewer` found 4 medium + 5 low across #42, #43 and #35, all fixed before each PR. The #35 medium was a real race: swipe offsets read after a `Task` hop could delete the wrong row. Martín found no code bugs after hand-off.
- **Manual steps avoided:** both new packages were registered by `new-package`, and 6 strings went through `localize`.
- **Review rounds:** none on #42 and #43; both merged as opened.

**What worked**
- **Plan approval as a design review.** The #35 plan listed "surface `lastWriteError`" under *Not doing*. Martín rejected the plan to pull it in, and one `AskUserQuestion` with two previews settled the scope:
  - the alert is app-wide, shown at `RootView`
  - the store keeps the failure until it's dismissed
  - failed refreshes stay silent

**What broke**
- **A fresh worktree's first app build fails.** The Run Script writes `GeneratedSecrets.swift` into a synchronized folder whose file list was planned before the file existed. The second build passes. Fixed in #66: `.worktreeinclude` copies the file.
- **`localize` only knows package catalogs.** The alert's strings for the app catalog were added with a one-off script.
- **Preview snapshots still catch the loading frame** after a rebuild. Two of six renders were blank, the same as in Phase 4.
- **The simulator can't be driven.** Launching and screenshots work; taps and swipes don't. Heart → list, swipe, relaunch and Details-from-list are manual checks for Martín until the UI test (#8).
- **The worktree guard refuses compound shell commands** (loops, `$VAR` paths, pipes into `gh`), so commands had to be split one per call. CLAUDE.md now spells out the shell style that gets past it (#66).
- **The commit was blocked** by `guard-main-branch.sh`, which read the main checkout's branch. #66 removed the hook, and this PR's commit went through once the main checkout was pulled.

---

## 2026-10-14 — Fewer local guards: GitHub guards `main` (#66)

**Why:** `guard-main-branch.sh` blocked every commit from `EnterWorktree`
sessions. The sessions for #64 and #35 stopped at their commit, and Martín had
to commit by hand. This was the hook's third false positive, after
`push && gh pr edit --base main` (#6) and `switch -q -c` (#26). The cause:
`$CLAUDE_PROJECT_DIR` stays at the main checkout after `EnterWorktree`, so the
hook asked the main checkout (on `main`) for its branch. The session's
directory is the `cwd` field of the hook input.

**What the transcripts showed** (33 sessions):
- **The hook added no safety.** Branch protection already rejects any push to
  `main` without a PR, admins included. The hook only added false positives:
  11 blocks.
- **Claude Code's own worktree guard** refused 16 commands that it couldn't
  prove stay in the worktree (`$VAR` paths, loops, heredocs, `$(…)`), most of
  them not git at all. It's a Claude Code limit, not project config.
- **Fresh worktrees failed their first build** twice: `.worktreeinclude` copied
  the key but not `GeneratedSecrets.swift`.
- **Every `gh` call raised a permission prompt.** The skills called
  `/opt/homebrew/bin/gh` (from a memory that was out of date), which the
  `Bash(gh pr view *)` allow rules never match.

**What changed**
- The Claude hook is gone. `.githooks/pre-commit` (enabled by `setup.sh`) checks
  `git branch --show-current` where the commit actually runs: refused on `main`,
  allowed on branches, tested in the main checkout and in worktrees.
- `.worktreeinclude` copies `GeneratedSecrets.swift`.
- The skills call plain `gh`. The allow list covers read-only `gh`
  (issue/run view and list), `git fetch`, `git worktree list` and the
  build/simulator scripts.
- A `SessionStart` hook warns, and never blocks, when the main checkout is off
  `main`, edited or behind `origin/main`. Hooks and settings load from there,
  and skills do by default.
  Today it's one commit behind, with a local `project.pbxproj` edit, so a
  merged workflow fix wouldn't reach any session until it's pulled.
- CLAUDE.md gets the shell style that gets past Claude Code's worktree guard.

**Lesson:** when a server-side rule exists, don't mirror it with a local hook
that pattern-matches shell text. A local check belongs where git runs (a git
hook), and should warn rather than block unless it prevents real damage.

**Still Martín's call** (not in this PR):
- make the review verdict advisory
- one review per PR instead of two
- keep feature PRs out of the workflow log
- plan mode only for issues with open questions

---

## 2026-10-14 — The review verdict becomes a commit status

**Why:** #59's review was clean and its verdict concluded ✅ on the head
commit, but the merge box kept showing "ios-reviewer verdict — Expected" and
the PR stayed blocked.

**Root cause, from the API:**
- The verdict was a check run created with `POST /check-runs`. GitHub, not the
  workflow, picks the check suite it joins: the oldest github-actions suite on
  the commit. That was CI's on #57 and the review's on #60.
- #59 was opened as a draft and marked ready seconds later, so the review
  workflow ran twice on one commit: a skipped run, then the real one.
- GitHub keeps only the newest run per workflow and event on a commit. The
  skipped run's suite, which held the verdict, was dropped from the PR and from
  branch protection. GraphQL still listed it as required and successful.
- Re-running the review or adding the override label landed in the same hidden
  suite, so nothing on the PR could fix it.

**Fix:** "ios-reviewer verdict" is now a commit status. Statuses don't belong to
any suite, so no other run can hide them.
- Medium findings pass in green and say "🟠 … merge at your discretion". A
  status has no neutral; that's why the check was kept last time, and Martín
  traded it for a gate that can't vanish.
- The full summary is the review run's job summary, and the status links there.
- `verdict.json` is kept as an artifact (30 days), so `review-override.yml` can
  still re-evaluate without reviewing again.

**Found while shipping it:** `guard-main-branch.sh` read the branch of
`$CLAUDE_PROJECT_DIR`, the main checkout. With the main checkout now parked on
`main`, it blocked every commit from a worktree session. It now reads the
session's `cwd` from the hook input, and falls back to the project directory.

---

## 2026-10-14 — `/parallel`: one command per parallel session (#61)

**Why:** with a PR per issue and about 5 minutes of CI each, the session that
shipped a PR sat waiting. The Phase 3/4 setup worked but was a page of manual
steps: worktree, copying secrets, an Xcode window, a simulator, a kickoff
prompt.

**What exists, checked against the docs and a probe session:**
- `claude --bg -w <name>` starts a session *inside* a new worktree, from a
  fresh `origin/main`. The probe's first commands already ran there, so the
  main checkout is never touched.
- `claude agents` lists every session, this one included; a background session
  there is just "managed", not hidden.
- `claude rm` removes a session with its worktree and branch.
- `.worktreeinclude` copies gitignored files.
- Auto memory is shared across a repo's worktrees, which fixes last time's
  "memory may not load" gotcha.

**What the project adds:**
- **`/parallel <issue>`** dispatches the session, named after the issue. It runs
  `/start-issue` until its first question and waits in agent view (Martín's
  choice: a row he opens, not a new tab).
- **`/parallel <task in plain words>`** works too. The new session first turns
  the text into a GitHub issue (Task form), then starts it, so every PR still
  closes an issue and `/parallel` returns at once.
- **`scripts/worktree-simulator.sh`:** each worktree gets its own simulator,
  `StreamIn <worktree>`, created on first use.
- **`scripts/xcodebuild-locked.sh`:** `xcodebuild` under a shared `lockf`
  lock, so two local test runs queue instead of fighting for the CPU. Tested:
  the second waited and said so.
- **`start-issue`** renames `worktree-<name>` to `<type>/<task>`.
- **`ship-phase`** watches CI with Monitor instead of a blocking wait, so the
  session stays usable for those 5 minutes.
- **`/parallel clean`** removes finished worktrees, branches and simulators,
  never anything unpushed.

**Then the model changed (Martín's idea): every editing session in a worktree.**
Agent view's "new task" already starts background sessions. So instead of making
`/parallel` the only safe door, the main checkout became a control room, and any
session that changes the repository moves into a worktree first. A probe of an
agent-view-style session (no `-w`) showed what that takes:
- **Shell commands run in the main checkout until the session moves.** Its
  `touch` created a file there, so a `git switch` would have switched Martín's
  branch.
- **File edits are guarded natively:** "This background session hasn't
  isolated its changes yet. Call EnterWorktree first."
- **A SessionStart hook runs in the main checkout,** too early to set up the
  worktree.

So `/start-issue` calls `EnterWorktree` before any git command. The hook was
dropped: setup became deterministic (the simulator is named after the worktree,
and Xcode opens only when the session needs it, because every open copy of the
project gets indexed). `claude rm` refusing to delete a worktree with
uncommitted work turned out to be a useful safety net for cleanup.

---

## 2026-10-13 — Commit types: `tooling` for the workflow, `chore` for the app (#58)

**Why:** every workflow PR went out as `🔧 chore(workflow)`, which mixed tooling
with housekeeping in the app. Martín wanted the history to tell them apart.

**What changed:**
- `tooling` 🔧 for GitHub workflows, scripts and the Claude Code setup, with
  scopes `ci` and `claude`.
- `chore` 🧹 for app maintenance that changes no behavior (dependency bumps,
  project settings, cleanup).
- Branches follow: `tooling/…`, `chore/…`.

**Choices:**
- `tooling` is a custom type. Conventional Commits allows custom types, and
  nothing here parses them. The standard `ci` and `build` wouldn't cover the
  Claude setup.
- 🔧 stays (gitmoji's "configuration") so the workflow history looks the same as
  before.
- 🧹 is the project's one addition to gitmoji, which has no maintenance emoji.
- #57 was retitled before merging, so it's the first `tooling` commit on `main`.
  Past commits weren't rewritten.

---

## 2026-10-13 — The review becomes a merge gate (#56)

**Why:** the first working review, on #53, was useful but read like a log. It
posted 6 notifications, used `[rule: …]` tags, gave the same failing test
MEDIUM in one run and HIGH in another, and its green tick meant nothing for
merging. Martín asked for a gate: high blocks, medium is his call, low passes.

**What changed**

- **One review per run:** the summary is the review's body and every finding
  is a line comment. It has a ```` ```suggestion ```` block when the fix
  replaces exactly those lines, and a readable source footer
  ("📏 Project rule: Swift & SwiftUI style", linked) only when a rulebook says
  so.
- **A written severity rubric in `ios-reviewer.md`.** HIGH now explicitly
  includes "the PR can't pass CI" and "breaks the architecture boundary", so
  merge-blocking doesn't depend on the model's mood.
- **The verdict is computed, not judged.** Claude writes its findings as JSON,
  and `review-verdict.sh` (14 tests, run in CI) maps them to the required
  "ios-reviewer verdict" check:
  - ❌ failure for critical or high
  - ◻️ neutral for medium
  - ✅ success for low or nothing

  A review that doesn't finish is a failure, never a silent pass.
- **Re-review on every push** (~$0.15 on Sonnet):
  - Threads from earlier reviews are checked, and the fixed ones resolved.
  - Still-open findings aren't posted again but still count for the verdict.
  - Only threads the earlier reviews opened can be resolved.
- **Override:** the `review-override` label turns a failure into neutral for the
  current commit, and the next push removes it. Branch protection already
  enforces rules for admins, so this is the only way past a red verdict, and it
  leaves a trace.
- **Writes moved out of the model's reach.** Claude can only write two local
  files and post one review. Resolving threads, setting the verdict and
  removing the label are deterministic workflow steps.

**Tested before merging,** since a PR can't run a workflow it changes:
- The verdict script's 14 cases ran locally.
- Two local dry runs of the new prompt on #53's planted diff: 28–31 s and
  $0.14–0.17 each.
  - **First run:** consecutive lines ran together on GitHub, and a deletion
    suggestion left an empty test that passes.
  - **Second run:** those were fixed, but one suggestion only worked together
    with another.

  Both are now rules in the prompt. The real test is the throwaway PR after
  merging.

**Found on #57 itself, before merging:**
- **Fail-closed works on GitHub:** the review step was skipped (the PR changes
  the workflow), and the verdict published as ❌ "Review didn't finish".
- **A real bug:** a missing review stored no findings, so the override label had
  nothing to re-evaluate. With admins bound by branch protection, a PR that
  changes the review workflow could never have merged. The label now also
  overrides a missing review.
- **Clearer message:** such PRs get "This PR changes the review workflow, which
  can't review itself: add review-override to merge" instead of advice to retry.
- **Less clutter:** the override job moved to `review-override.yml`, so normal
  pushes no longer list a skipped job.
- **First real run, on #59:** it reviewed the PR and the verdict was ✅, but the
  review was never posted (2 permission denials). In Claude Code's allow-list,
  `:*` only matches at a word boundary, so `…/pulls/:*` never matched
  `…/pulls/59/reviews`. A local test with a stand-in command confirmed it, and
  showed the glob `…/pulls/*/reviews *` does match. The publish step now also
  flags a review that should exist but wasn't posted, since the verdict alone
  hid the failure.
- **Two lines, renamed:** the review job is now called "run review". GitHub
  lists every job, so the engine ("run review") and its result ("ios-reviewer
  verdict") both show, and the names now say which is which.
- **Kept as is:** GitHub files the API-created verdict under the "CI" group
  ("CI / ios-reviewer verdict"). Martín kept that over a commit status, because
  only checks can show medium findings as neutral. (Replaced by a status on 2026-10-14: see
  that entry.)

---

## 2026-10-13 — Phase 4 (#36): designing on screen with Martín

**Why:** #36 shipped its planned layout, but on the simulator it answered "can I
watch this?" badly: "not available" said twice, services you don't have as big as
yours, and headers like a settings page. The redesign was done live, in the
Phase 4 worktree, in parallel with Phase 3.

**What happened**

- **Design as a Q&A, not a spec:**
  - Plan mode plus `AskUserQuestion` with ASCII previews, four questions a round, four rounds.
  - Martín answered as a stakeholder ("only the meaningful bits, nothing twice").
  - The result was a one-verdict card, written into the plan, #36's body and the roadmap before any code.
- **The look iterated through `RenderPreview` snapshots,** about 15 rounds:
  - the card surface
  - the emoji badge (dropped)
  - the gradient
  - the legends on the border
  - three tries at the label cutting the tint
  - opaque vs translucent cells
  - Martín judged each one on the simulator with real logos, which previews don't have.
- **A spinning globe:**
  - The first try was emoji frames, which Martín called "lame".
  - A Metal shader came next. It needed Xcode 26's separately downloaded Metal Toolchain, which is missing locally and possibly in CI.
  - It became a Swift CPU renderer: a public-domain Natural Earth map, a projection cached per size, and a spin curve that slows like a ball on a table. Unit tested.
- **`ios-reviewer` caught what the previews hid:**
  - the border legends overlapping the lines around them at large Dynamic Type sizes
  - the verdict sorting ~90 regions with locale lookups on every render
  - a VoiceOver regression on the abroad rows
  - the merge conflicts waiting with Phase 3

  All fixed before the PR. Then the large-size case was checked in previews at XXX Large and AX 5.

**What broke**

- **Preview snapshots often catch the loading frame:** `.task` hasn't finished
  when the snapshot is taken, so a second render was routinely needed.
- **Xcode re-sorts `project.pbxproj` on open** (same content, new order). Each time,
  it was restored by hand so the PR stays limited to the feature.
- **The Search results preview doesn't build in preview mode,** an issue in its
  existing code. The app build and tests are fine.
- **Martín still found by eye** every design problem (the twice-said "not
  available", a redundant flag, a label crossed by the tint). No tool judges taste.
  Flags also showed as empty boxes on the iOS 26.3 simulator and drew fine on
  26.4, most likely the runtime (not confirmed).

---

## 2026-10-13 — The PR review becomes ios-reviewer, and it posts what it finds

**Why:** Martín noticed the automated PR review had never left a comment.

**What we found**

- **The review didn't review.** `claude-code-review.yml` ran Anthropic's
  generic `code-review` plugin. All 8 runs since it was set up ended after 2–9
  turns and 4–23 s, about $0.05–0.10 each, and reviewed nothing. Its output is
  hidden from the log, so the exact reason isn't visible.
- **It couldn't have posted anyway:** the job's token had `pull-requests: read`.
- **The green check made it look fine.** "claude-review: pass" on every PR meant
  "the job didn't crash", not "the PR was reviewed". It took a person asking
  why there were never comments to notice.

**What changed (#51)**

- **The GitHub review runs `ios-reviewer`,** the reviewer `/ship-phase` already
  used locally. It posts one inline comment per finding and a summary comment
  every time, so a clean run is visible too.
- **It runs once per PR,** and again on "@claude review".
- **`swiftui-pro`** (Paul Hudson, MIT) is vendored in the repo at v1.1. It was
  only on Martín's Mac, so CI and claude[bot] never had it.
  - `ios-reviewer` reads it in tiers. `swift.md` and `hygiene.md` (5 KB) load
    for every Swift change. `SKILL.md` and `api.md` (7 KB) load for SwiftUI
    files. The other six topic files load only when they fit the change, so
    the whole 28 KB isn't loaded on every review.
  - Where it overlaps the project's rules, it reports once and the project wins.
  - Upstream v2.0 targets Xcode 27, so it waits for the toolchain upgrade.
- **`ios-reviewer` can now review a PR, uncommitted work or a branch,** and
  cites the rulebook behind each finding. Until now it only knew
  `main...HEAD`, and twice it needed hand-written instructions for uncommitted
  work.

**Lesson:** a check that can pass without doing its job needs a visible output,
so check the output, not the green tick.

**Follow-up, same day: the real cause.** The new review also posted nothing on
the smoke-test PR #53: 3 turns, ~5 s, no Opus usage.
- **A debug re-run didn't help:** the action prints the conversation only with
  `show_full_output`, which is off on this public repo.
- **A local dry run (`claude -p`, same prompt and tools) showed it:**
  - The Agent tool runs subagents in the background.
  - The CI agent started `ios-reviewer`, then ended its turn "until it
    finishes", and in Actions the first final answer ends the job.
  - The old plugin starts its reviewers as subagents too, so this was very
    likely its problem as well.
- **The fix:** in CI, Claude follows `ios-reviewer.md` itself on Opus, with no
  subagent. The same local dry run then took 53 s and $0.42, and found all five
  planted problems with their sources:
  - a test that compiles but fails
  - hard-coded English
  - a feature importing TMDBClient
  - a fixed font size
  - `foregroundColor`
- **Opus or Sonnet for the GitHub review?** Measured with the same dry run on
  #53:

  | Model | Time | Cost | Plants found | Rulebooks read |
  |---|---|---|---|---|
  | Opus | 53 s | $0.42 | 5 of 5 | all |
  | Sonnet | 35 s | $0.12 | 5 of 5 | none of `swiftui-pro` |
  | Sonnet, told to read them and list what it read | 30 s | $0.15 | 5 of 5 | all 4 required, plus `accessibility.md` |

  Martín chose Sonnet: on PRs Claude opens, this is the second review, after
  the Opus one in `/ship-phase`. Requiring a `Checked against:` line in the
  summary makes a skipped rulebook visible on every PR.
- **Editing a comment to add `@claude` now wakes the bot** (Martín had added it
  by editing on #54 and nothing ran). The workflows listen to `edited` too, but
  only when the previous text didn't mention `@claude` yet, so fixing a typo in
  such a comment doesn't start a second run.
- **CI's test reporting passed the same smoke test:**
  - "Build and test" went red
  - the failing test is named in an annotation with its expectation
  - the summary step still runs

  One gap: the annotation's path is the bare file name, so it may not attach to
  the line in "Files changed".

---

## 2026-10-12 — Phases 3 and 4 kick off: plans as issues, three bot PRs in parallel

**Why:** the first phases run through the issue flow, with claude[bot] taking
the small pieces while local sessions take the rest (#9's trial).

**What happened**

- **Both phases planned in one session**, in plan mode, then published so the
  plans outlive it:
  - eight issues (#30–#37) with the decisions in their bodies
  - both milestone descriptions
  - the roadmap and a "Parallel sessions" how-to in CLAUDE.md (#38)
- **Ordering the issues around one shared test helper** (#33's `makeModel`)
  let Phase 3's heart and Phase 4's layout both build on the Details view model
  without editing the same nine call sites.
- **claude[bot] took three issues at once** (#31, #32, #33):
  - 1–2.5 min from label to PR
  - all three green in CI on the first run
  - merged within 45 min of kickoff, after Martín's review
- **A review comment refined before sending:** "take the enums out of the
  ViewModel" was rewritten to name all three enums, keep them in DetailsFeature
  and change no behavior. The bot did exactly that in one 50 s run.
- **`ios-reviewer` on #30 found three real problems** that 19 passing store
  tests had missed, all fixed before the PR:
  - two failing writes to one movie could leave the screen showing the opposite
    of what's stored
  - `@ModelActor` made a SwiftData initializer public, so callers could skip
    the migration plan
  - a test passed whether or not writes waited for the initial load

  Each fix was checked by breaking it on purpose and watching its test fail.
- **`ios-reviewer` on #34:** two LOW findings, both fixed before the PR:
  - a log line OSLog would have redacted
  - the architecture table not listing `Watchlist` as a feature dependency
- **The cost of one PR per issue:** after #34, hearting a movie works but the
  Watchlist tab still shows its placeholder until #35. Martín hit it on the
  simulator and read it as a bug. When a phase ships over several PRs, each PR
  should say what's still missing on screen.

**What broke**

- **The bot can't generate string symbols.** The `localize` script needs
  `xcrun xcstringstool`, which doesn't exist on its Linux runner. On #32 it
  added the catalog key and hand-wrote a `LocalizedStringResource` (a faithful
  copy of what the generator emits) instead of the generated symbol. Fixed
  locally in a temporary worktree: re-ran the script, swapped in
  `.watchlistDirectorsOverflow(…)`, one commit on the bot's branch.
  Issues that add strings aren't fully `good-for-claude` until the script can
  generate symbols without Xcode.
- **`@claude` in an unsubmitted review does nothing.** Comments made with
  "Start a review" stay private drafts and fire no events until the review is
  submitted. A plain PR comment triggers the bot at once.

---

## 2026-10-12 — Second claude[bot] issue: bot issues must fit in one run

**The run:** #14 (test the TMDB image URLs, HTTP client, mappings and errors,
then split `TMDBClient.swift`), rewritten first so the bot had every behavior to
pin down, the test layout and the Swift 6 constraints. Triggered with `@claude`.

**What it delivered** ([#28](https://github.com/martingarcialopez/StreamIn/pull/28)):
in 2 min 16 s, 45 new tests in exactly the requested layout, with no production
code touched. CI green on the first push: 151 tests, TMDBClient coverage
53% → 96.9% (`TMDBClient.swift` 44% → 96.4%), target 85%. It reported honestly
that none of it had run before CI.

**What it didn't do, and why**

- **Step 2 (the file split) never started.** The issue said "only after step 1
  is green", and CI only starts after the bot pushes, so it can't wait for CI
  inside a run. It stopped and asked for a second `@claude`. The flaw was in the
  issue, not the bot. **Lesson: an issue for claude[bot] must fit in one run.**
  Several steps become one commit each in the same PR; CI checks every push and
  the PR can't merge until it's green.
- **The PR description was the empty template**, `Closes #` without a number, so
  merging wouldn't have closed the issue. The run had 8 denied commands: the
  allow-list had `gh pr create` but not `gh pr edit`, and a long description
  usually goes through a temporary file or `$(cat <<EOF …)`, which weren't
  allowed either. It fell back to a bare `gh pr create`.

**Changed:** `claude.yml` allows `gh pr edit`, and the bot's instructions say to
finish every step in one run (one commit each), to write the description inline
with `--body`, and to name any denied command in its reply. The one-run rule is
also in the task issue form and CLAUDE.md, where issues get written.
`show_full_output` (which would log every tool call) stays off: the repo is
public and those logs would be too.

---

## 2026-10-12 — Coverage in CI

**Why:** "are the tests any good?" had no number behind it.

**What changed:** CI runs the test plan with `-enableCodeCoverage YES`, and the
job summary adds line coverage per package. Each source file counts once, with
its best coverage across test bundles, since some packages compile into several.

**First measurement:** 21% of lines overall, which undersells it. The logic is
well covered: `ProviderAliases`, `MemoryCache` and `CachingMovieRepository` at
100%, `RemoteImageStore` 98%, `ProviderCatalog` 93%, `SearchViewModel` 91%,
`Preferences` 85%, `DetailsViewModel` 73%. SwiftUI views and the app target are
at 0% by design (previews check views; the UI test is #8). The real gap is
`TMDBClient.swift` at 44%: the live HTTP client, search and detail mapping, date
parsing, directors and image URLs have no tests. #14 now covers all of it, with
an 85% target.

---

## 2026-10-12 — First issue done by claude[bot], with no local session

**The trial:** #15 (remove dead code and a template test), triggered by Martín
commenting `@claude implement this issue`. No Claude Code session ran on the Mac.

**What happened**

- About 1 min from the comment to [#17](https://github.com/martingarcialopez/StreamIn/pull/17);
  Claude itself worked 38 s on a Linux runner. It made a branch, edited exactly
  the five files the issue named, committed in the project format, opened the PR
  with the template and `Closes #15` (CI box left unticked), and summarized it
  on the issue. GitHub linked the PR to the issue on its own.
- The bot's push triggered CI, which proves the app token works: green in
  3 min 55 s, 106 tests, exactly the three fewer it predicted (Domain 22,
  TMDBClient 24, DesignSystem 3). The bot never built anything; CI was its proof.

**What broke, fixed in the follow-up PR**

- **The automated review refused the PR:** "Workflow initiated by non-human
  actor: claude (type: Bot)". The action rejects bot-started runs unless
  they're listed; `claude-code-review.yml` now has `allowed_bots: 'claude[bot]'`
  (the action strips `[bot]` before matching, per its source).
- **The bot's own progress comment queued a second `claude.yml` run,** which was
  then skipped. The concurrency group moved from the workflow to the job, so
  runs that fail the owner-only `if` end at once.
- **It used 🔥 for a removal,** gitmoji's actual convention, where the `commit`
  skill said 🔧 for `chore`. The skill now allows 🔥 for commits that only remove
  code.

**Still open:** the commit's author is `github-actions[bot]` (co-authored by
"Claude Sonnet 5.5", the action's default model), not claude[bot] — already on
the roadmap. The bot's summary also shows the action's default "Create PR" link
next to the real PR; cosmetic.

---

## 2026-10-11 — macOS CI is the record; work starts from issues

**Why:** until now "it builds and the tests pass" meant Claude saying so after
running them on Martín's Mac, and claude[bot] couldn't build at all. Work started
from a roadmap file, not from anything GitHub could link a PR to.

**What changed**

- **CI** (`ci.yml`, job "Build and test"): a `macos-26` runner with Xcode 26.6
  builds the app and runs `StreamIn.xctestplan` — every package's tests, one
  build — on each PR and push to `main`. The job summary lists results per
  package; the `.xcresult` and log are kept 14 days.
- **A shared `StreamIn` scheme and a test plan**, committed for the first time
  (before, CI would have relied on auto-created schemes). ⌘U now runs everything.
- **CI is the source of truth:** CLAUDE.md, `ship-phase` (new step: wait for CI,
  fix red runs, quote the green one), the PR template (a CI-run box replaces the
  self-reported build and test boxes) and claude[bot]'s instructions.
- **The repo went public**, so macOS runners are free and `main` can require CI.
  A history scan found no committed secrets first.
- **Issues:** milestones per roadmap phase, issue forms (task, bug), labels
  (`claude`, `good-for-claude`, `workflow`, `tech-debt`), and nine first issues
  (#8–#16) from the review and the roadmap. `/start-issue` starts local work;
  the `claude` label hands an issue to claude[bot], which now opens the PR itself
  (`gh pr create`) with `Closes #N`.

**What CI caught on its first run:** a fresh clone didn't build. The app target's
synchronized folder is scanned before the "Generate Secrets" script runs, so
`GeneratedSecrets.swift` didn't exist yet: "cannot find 'GeneratedSecrets'".
Reproduced locally on a fresh clone (first build fails, second passes) — anyone
following the README hit it. `scripts/setup.sh` now creates the placeholder;
README and CI run it.

**Numbers:** first run red in 1 min 22 s (the fresh-clone bug); first green run
2 min 39 s for the job — app build plus 109 tests across 9 packages on an iPhone 17
simulator (iOS 26.5). The same test plan takes about 30 s locally with a warm
machine.

**Decided against (for now):** `paths-ignore` for docs-only changes (a required
check that never runs blocks the merge, and public-repo minutes are free), and a
`workflow_run` auto-fix for red CI (#11: it runs PR code with write access;
revisit with data).

---

## 2026-10-11 — An outside review, and its first fixes

**Why:** before Phase 3, a fresh Claude session read the whole codebase and the
workflow and gave an honest review, to find what the tooling misses.

**What it found:** five bugs that neither tests nor `ios-reviewer` had caught
(the reviewer only reads diffs), a README describing another app, and workflow
gaps: a brittle guard hook, rules split between the repo and local memory, a
roadmap outside the repo, no automatic verification, and nothing that looks at
the UI.

**What changed**

- Fixed, with tests: a failed Details load read as "not available with your
  subscriptions"; the language picker offered four untranslated languages;
  per-region provider lists showed aliased brands twice (`ProviderAliases.merging`
  now serves the regional lists and the provider catalog); Details showed
  "cancelled" as an error; the Details preview crashed.
- `ios-reviewer` then found five LOW issues, all fixed: Retry ran outside
  `.task(id:)` so nothing cancelled it, a failed load hid the services picker,
  the previous region's providers stayed visible after a region change, the
  new hook pattern missed `git push;`, and two sentences in these docs were wrong.
- README rewritten from the code. CLAUDE.md's preview rule fixed: it allowed
  `fatalError` in "unused" methods, but a view's `.task` runs in previews too.
- Verified: app build, 102 tests across 7 packages, three previews rendered.

**What the tooling caught, and what it missed**

- **First real use of `RenderPreview`.** One call confirmed the preview crash;
  after the fix it rendered the "Available" and "Offline" previews as evidence.
  No workflow step rendered previews before.
- **Guard-hook false positives, live:** three read-only git commands were blocked
  because a branch name or path contained "commit" (fixed in the entry below).
- **A destination string cost a test run:** `OS=26.3` matches no simulator when
  the runtime is `26.3.1`. Name the newest runtime, or leave `OS` out.
- **Two sessions, one checkout.** A second session moved the roadmap into the
  repo while this one fixed bugs, in the same working tree, so its staged
  changes landed on this branch. It worked out, but parallel sessions need their
  own worktrees (workflow upgrade 4 in the roadmap).

**Decided:** learning beats the ship date, so the roadmap has none. Next, before
Phase 3: macOS CI, issue-driven work, a visual check before every PR, parallel
agents in worktrees, and evals — listed in `docs/roadmap.md`.

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
