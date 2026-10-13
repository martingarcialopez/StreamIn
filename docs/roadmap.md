# StreamIn — roadmap to the App Store

Where the project stands and what's left, phase by phase. Start every session
by reading this file; update it when a phase ships or a plan changes. The tasks
themselves live in GitHub: each phase is a milestone, each task an issue.

**How we work** is in [CLAUDE.md](../CLAUDE.md) (tools, rules, decisions) and
[docs/workflow-log.md](workflow-log.md) (what each workflow change improved).
This file doesn't repeat them.

## Status (Oct 12, 2026)

| Phase | What | State |
|---|---|---|
| 1 | DesignSystem package + landing page | ✅ May 2026 |
| 2 | Caching, provider catalog, search/Settings fixes, iPhone + iPad | ✅ [#1](https://github.com/martingarcialopez/StreamIn/pull/1) |
| — | Workflow foundation: rules, skills, `ios-reviewer`, hooks, Xcode MCP | ✅ [#2](https://github.com/martingarcialopez/StreamIn/pull/2) |
| — | Claude GitHub app: `@claude`, automatic PR review | ✅ [#3](https://github.com/martingarcialopez/StreamIn/pull/3), [#4](https://github.com/martingarcialopez/StreamIn/pull/4) |
| — | `commit` skill: gitmoji, co-author trailer, one-prompt commit + push | ✅ [#5](https://github.com/martingarcialopez/StreamIn/pull/5) |
| — | Review follow-ups: Details error state, one logo per brand, translated languages only, README, roadmap in the repo | ✅ [#6](https://github.com/martingarcialopez/StreamIn/pull/6) |
| — | macOS CI + issue-driven work (workflow upgrades 1–2) | ✅ [#7](https://github.com/martingarcialopez/StreamIn/pull/7) |
| — | [Workflow upgrades](https://github.com/martingarcialopez/StreamIn/milestone/1) 3–5 | 🔄 #9 runs with Phases 3 + 4; #8, #10 open |
| 3 | [Watchlist (Persistence + SwiftData)](https://github.com/martingarcialopez/StreamIn/milestone/2) | 🔄 #30–#32 merged; #34 in review; #35 next |
| 4 | [Details page redesign](https://github.com/martingarcialopez/StreamIn/milestone/3) | 🔄 #33 merged; #36 next, in parallel with 3 |
| 5 | [Landing page animation](https://github.com/martingarcialopez/StreamIn/milestone/4) | planned |
| 6 | [App Store readiness + submission](https://github.com/martingarcialopez/StreamIn/milestone/5) | planned |

Cleanup outside the phases is tracked as [`tech-debt` issues](https://github.com/martingarcialopez/StreamIn/issues?q=is%3Aopen+label%3Atech-debt).

**No ship date.** StreamIn ships when it ships: learning state-of-the-art AI
workflows comes first. Rough sizing for phases 3–6: 3: 4 days, 4: 3, 5: 2, 6: 5.

## Workflow upgrades (agreed Oct 11, before Phase 3)

From the outside review of Oct 11. CI comes first because the others lean on it.

1. ✅ **macOS CI as the source of truth:** a GitHub Actions job on a macOS runner
   builds the app and runs every package's tests on each PR; agents and the PR
   template quote the run instead of local runs (#7).
2. ✅ **Issue-driven work:** phases are milestones, tasks are issues; `/start-issue`
   locally, or the `claude` label for claude[bot]; automated review and CI run;
   Martín reviews last (#7).
3. **A visual check before every PR** ([#8](https://github.com/martingarcialopez/StreamIn/issues/8)): render the previews of changed views with
   the Xcode MCP (`RenderPreview`), attach the screenshots to the PR, and add one
   UI test for search → details → providers.
4. **Parallel agents in worktrees** ([#9](https://github.com/martingarcialopez/StreamIn/issues/9)): Phases 3 and 4 are mostly independent; run
   them in separate worktrees and sessions, each with its own PR.
5. **Evals for the skills and `ios-reviewer`** ([#10](https://github.com/martingarcialopez/StreamIn/issues/10)): skill-creator's eval loop on
   `localize` first, then a `claude plugin eval` suite once CI exists.

## Working on a phase

1. **Open the project in Xcode** and allow external agents, so the `xcode` MCP
   server connects (build, tests, previews, Apple docs).
2. **Plan in plan mode** before code; get Martín's approval. The plan splits the
   phase into issues in its milestone (issue form: goal, acceptance criteria, how
   to verify). Small, Xcode-free ones get `good-for-claude`.
3. **Start each issue with `/start-issue <n>`**: one branch per issue or per
   phase, named by the `commit` skill's rules (e.g. `feat/watchlist-with-swiftdata`).
4. **Check locally at the end of each task:** build, tests of the packages
   touched, previews of changed views.
5. **Ship with `/ship-phase`:** `ios-reviewer` → local check → docs → commit →
   PR with `Closes #<n>` → CI green. Martín reviews on GitHub (claude[bot] also
   reviews automatically) and squash-merges once CI passes.
6. **After the merge:** tick the phase here and add its row to the scorecard in
   the workflow log.

---

## Phases 3 and 4 run in parallel (#9)

Planned together on Oct 12. Two local sessions, each in its own checkout, with claude[bot] alongside:

| Who | Where | Issues, in order |
|---|---|---|
| Session 1 | main checkout | Phase 3: #30 → #34 → #35 |
| Session 2 | worktree `../StreamIn-phase4` | Phase 4: #36 |
| claude[bot] | GitHub | #31, #32, #33 |

- **#33 merges first.** It adds the `makeModel` test helper and the view-model state that both #34
  and #36 build on.
- **Each phase owns part of Details.**
  - Phase 3: `DetailsViewModel.init`, the toolbar and the watchlist parameter in the previews.
  - Phase 4: the body, the section views, the strings and the preview data.
- **The one expected conflict** is the preview block in `DetailsView.swift`. Prefer merging #34 first;
  then #36 merges `main` into its branch.
- **Afterwards:** split `DetailsView.swift` into one file per section (#37).

How to run two sessions: CLAUDE.md, "Parallel sessions".

---

## Phase 3 — Watchlist

**Goal:** save movies from Details with a heart, list them in the Watchlist tab,
open Details from there. Today `WatchlistView` is a placeholder.

**Architecture (decided Oct 12).** Features never see SwiftData:

- **Domain:**
  - `WatchlistItem`: the whole `Movie` plus `addedAt`, so Details opens complete from the
    Watchlist, even offline.
  - `WatchlistRepository`: `items()` newest first, `save` (upsert), `remove`. There's no `contains`:
    the store answers it from memory.
  - `WatchlistError`.
- **Persistence** (new package):
  - A versioned SwiftData schema (V1 plus an empty migration plan) and an
    internal `@ModelActor` repository.
  - The only public entry point is `WatchlistPersistence.makeRepository(storage:)`, with
    `.appDefault`, `.inMemory` or `.file(URL)`, returning `any WatchlistRepository`.
    `@ModelActor` would otherwise make `init(modelContainer:)` public and let callers
    skip the migration plan.
- **Watchlist** (new package, depends on Domain only): `WatchlistStore`, `@MainActor @Observable`,
  modeled on `ProviderCatalog`.
  - Updates show immediately and are undone per item if the write fails.
  - Writes are chained and wait for the initial load.
  - `refresh(movie)` updates a saved snapshot when Details loads.
- **Composition root** builds the repository, falling back to in-memory if the store can't open.
  `STREAMIN_IN_MEMORY_WATCHLIST=1` forces a fresh store.
- **Heart everywhere:** the Details toggle, the tab icon and the empty state.

**Issues**

1. #30 — Data layer: Domain types, Persistence, `Watchlist` store
2. #31 — `PosterView` → DesignSystem `MoviePoster` (claude[bot])
3. #32 — Directors line formatter (claude[bot]): none → no line; one → name;
   two → "A, B"; three or more → "A, B & N more" (`watchlistDirectorsOverflow`)
4. #34 — Heart on Details, composition root, shared `MovieDetailsDestination`
5. #35 — Watchlist tab: list, swipe to delete, empty and error states, Details from the list

**Verify:**
- Heart a movie, and it's in the Watchlist.
- Swipe to delete it.
- Relaunch, and saved movies are still there, in the same order.
- Open Details from the Watchlist: complete on its first frame, heart filled.

---

## Phase 4 — Details page redesign

**Goal:** where to watch comes first, grouped by the user's region.

```
[Backdrop] Title · metadata · Directed by …
Where to watch in 🇪🇸 Spain
  Free / With your subscriptions / With other services   (each only with data)
  (no services picked: "Choose your services" in the subscriptions slot)
  (nothing at all: "Not available in your region.")
──────────
Watch with your subscriptions in other regions
  (no service carries it anywhere: one quiet line; at home only: hidden)
──────────
Overview
```

**Decided (Oct 12):**
- The three home subsections share one wrapping logo grid (`LazyVGrid`, adaptive columns).
- "With other services" is the regional subscription providers minus the ones already shown.
- **Rent and buy stay hidden in v1**: the audience wants free, subscription and VPN options. The data
  stays in Domain.

**Issues**

1. #33 — `DetailsViewModel`: `whereToWatchState`, `otherRegionsState`,
   `homeSubscriptionsOthers`, `homeRegionLabel`, plus the `makeModel` test helper (claude[bot])
2. #36 — The layout, the new strings via `localize`, six previews

**Verify:**
- A movie with full availability shows every subsection.
- A home-only movie shows no other-regions header.
- iPhone and iPad layouts both hold.

---

## Phase 5 — Landing page animation

**Goal:** the visual touch deferred from Phase 1.

- A conic-gradient halo behind the search bar is stashed:
  `git stash list` → `landing-halo-wip` (12 s rotation, blur 28, opacity 0.7).
  Default: restore it and refine; redo it only if the direction no longer fits.
- Respect Reduce Motion (static gradient), check light and dark mode, check
  performance on small iPhones (throttle `TimelineView` if needed), and make sure
  the halo doesn't overlap the logo or the tab bar on iPhone or iPad.
- Iterate with Xcode previews through the MCP server.

---

## Phase 6 — App Store readiness

- **Icon** (Martín designs it) and a launch screen matching the landing page.
- **TMDB attribution** (required by TMDB's terms): Settings, "Powered by TMDB" with
  their logo and a link; a line in onboarding.
- **`PrivacyInfo.xcprivacy`:** UserDefaults reason `CA92.1`, no tracking, no data
  collected. **Export compliance:** `ITSAppUsesNonExemptEncryption = NO`.
- **Onboarding trigger:** the one-shot `hasCompletedOnboarding` flag (steps in
  CLAUDE.md, "TODO: onboarding trigger").
- **Accessibility pass:** VoiceOver on every screen, Dynamic Type up to AX5,
  contrast in light and dark.
- **README:** refresh the status section and add screenshots or a demo GIF.
- **Store assets:** screenshots for iPhone **and iPad** (the app supports both),
  description in en + es, keywords, Entertainment category, age rating, a privacy
  policy URL (one page on GitHub Pages).
- **Make the repository public** before sharing it. History is clean: the secrets
  files were never committed.
- **Version 1.0.0, build 1**, TestFlight, submit. Expect one review round trip.

---

## After 1.0

- On-device Foundation Models for natural-language search ("a feel-good 90s
  comedy") — only if it earns its place; no backend or API key needed.
- Make claude[bot]'s own commits attribute to the real claude[bot] account; the
  action currently commits as `41898282+claude[bot]`, which GitHub maps to
  github-actions[bot].
- Similar movies on Details; pagination; rent/buy if the Details page has room.
- Package the `commit` skill and hooks as a plugin in an own marketplace.
