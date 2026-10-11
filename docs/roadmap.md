# StreamIn — roadmap to the App Store

Where the project stands and what's left, phase by phase. Start every session
by reading this file; update it when a phase ships or a plan changes.

**How we work** is in [CLAUDE.md](../CLAUDE.md) (tools, rules, decisions) and
[docs/workflow-log.md](workflow-log.md) (what each workflow change improved).
This file doesn't repeat them.

## Status (Oct 11, 2026)

| Phase | What | State |
|---|---|---|
| 1 | DesignSystem package + landing page | ✅ May 2026 |
| 2 | Caching, provider catalog, search/Settings fixes, iPhone + iPad | ✅ [#1](https://github.com/martingarcialopez/StreamIn/pull/1) |
| — | Workflow foundation: rules, skills, `ios-reviewer`, hooks, Xcode MCP | ✅ [#2](https://github.com/martingarcialopez/StreamIn/pull/2) |
| — | Claude GitHub app: `@claude`, automatic PR review | ✅ [#3](https://github.com/martingarcialopez/StreamIn/pull/3), [#4](https://github.com/martingarcialopez/StreamIn/pull/4) |
| — | `commit` skill: gitmoji, co-author trailer, one-prompt commit + push | ✅ [#5](https://github.com/martingarcialopez/StreamIn/pull/5) |
| — | Review follow-ups: Details error state, one logo per brand, translated languages only, README, roadmap in the repo | 🔄 `fix/review-bugs-readme` |
| — | Workflow upgrades (next section) | ⏭ next |
| 3 | Watchlist (Persistence + SwiftData) | planned |
| 4 | Details page redesign | planned |
| 5 | Landing page animation | planned |
| 6 | App Store readiness + submission | planned |

**No ship date.** StreamIn ships when it ships: learning state-of-the-art AI
workflows comes first. Rough sizing for phases 3–6: 3: 4 days, 4: 3, 5: 2, 6: 5.

## Workflow upgrades (agreed Oct 11, before Phase 3)

From the outside review of Oct 11. CI comes first because the others lean on it.

1. **macOS CI as the source of truth:** a GitHub Actions job on a macOS runner
   builds the app and runs every package's tests on each PR; agents and the PR
   template quote the run instead of local runs.
2. **Issue-driven work:** phases become issues and milestones; `@claude` on an
   issue (or a local session) opens a branch and a PR; automated review and CI
   run; Martín reviews last.
3. **A visual check before every PR:** render the previews of changed views with
   the Xcode MCP (`RenderPreview`), attach the screenshots to the PR, and add one
   UI test for search → details → providers.
4. **Parallel agents in worktrees:** Phases 3 and 4 are mostly independent; run
   them in separate worktrees and sessions, each with its own PR.
5. **Evals for the skills and `ios-reviewer`:** skill-creator's eval loop on
   `localize` first, then a `claude plugin eval` suite once CI exists.

## Working on a phase

1. **Open the project in Xcode** and allow external agents, so the `xcode` MCP
   server connects (build, tests, previews, Apple docs).
2. **Plan in plan mode** before code; get Martín's approval.
3. **One branch per phase**, named by the `commit` skill's rules
   (e.g. `feat/watchlist-with-swiftdata`).
4. **Verify at the end of each task:** app build + tests of the packages touched.
5. **Ship with `/ship-phase`:** `ios-reviewer` → verification → docs → commit →
   PR. Martín reviews on GitHub (claude[bot] also reviews automatically) and
   squash-merges.
6. **After the merge:** tick the phase here and add its row to the scorecard in
   the workflow log.

---

## Phase 3 — Watchlist

**Goal:** save movies from Details with a heart, list them in the Watchlist tab,
open Details from there. Today `WatchlistView` is a placeholder.

**Architecture — fixes the earlier plan.** The first draft had a SwiftData
`WatchlistStore` handing `@Model` objects to features, which breaks the rule
"features never depend on SwiftData". Instead:

- **Domain:** a `WatchlistItem` value type (movie ID, title, poster path, release
  year, director names, date added) and a `WatchlistRepository` protocol
  (list, add, remove, contains), Sendable and async.
- **Persistence** (new package, via the `new-package` skill): a SwiftData `@Model`
  and a `SwiftDataWatchlistRepository` implementing the protocol. SwiftData types
  never leave the package.
- **Observable state** that Details (the heart) and Watchlist (the list) share
  without importing Persistence: a `@MainActor @Observable` store built on the
  Domain protocol. *Decide in plan mode where it lives* (a small package next to
  `ReferenceData`, or Domain-only types plus the store in the App target).
- **Composition root** builds the `ModelContainer`, the repository and the store.

**Scope**

- Heart toggle in Details' toolbar (`heart` / `heart.fill`); saving stores the
  directors already loaded on Details, so no extra request.
- Watchlist tab: list of rows — poster, title, year, directors — newest first;
  swipe to delete; empty state ("Add movies from the Details screen").
- Directors on a row: none → no line; one → name; two → "A, B"; three or more →
  "A, B & N more" (localized: `watchlistDirectorsOverflow`, en + es, via
  `localize`).
- Tapping a row opens Details. The Watchlist tab's Details destination passes
  `onEditSubscriptions`, like the Search tab, through a `showingStreamingServices`
  binding from `RootView`. Settings stays on the tab's first screen only.
- Tests: repository against an in-memory `ModelContainer`; store add/remove/
  contains; the heart toggle in `DetailsViewModel`; the directors formatter.

**Verify:** heart a movie → it's in Watchlist; delete by swiping; relaunch → it's
still there; open Details from Watchlist.

---

## Phase 4 — Details page redesign

**Goal:** where to watch comes first, grouped by the user's region.

New section order, top to bottom:

1. Backdrop, title, metadata, directors (unchanged).
2. **"Where to watch in 🇪🇸 Spain"** with up to three subsections, each shown only
   when it has data: **Free** (`availability.free`), **With your subscriptions**
   (`providersAvailableAtHome`), **With other services** (regional subscription
   providers minus the ones already shown).
3. Separator.
4. **"Watch with your subscriptions in other regions"** (`providersAvailableElsewhere`).
5. Separator.
6. Overview, moved to the bottom.

- New strings via `localize` (en + es): `detailsWhereToWatchRegion` ("Where to
  watch in %@"), `detailsWhereToWatchFree`, `detailsWhereToWatchSubs`,
  `detailsWhereToWatchOther`.
- `DetailsViewModel.homeSubscriptionsOthers` (subscription providers minus those
  already listed), with tests.
- Empty states: nothing at home → one "not available" line for the section; no
  other-region availability → no header.
- **Rent and buy stay hidden in v1** (decided): the audience wants free,
  subscription and VPN options; the data stays in Domain.
- Keep the "Choose your services" button for users with no services picked.

**Verify:** a movie with full availability shows every subsection; a home-only
movie shows no other-regions header; iPhone and iPad layouts both hold.

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
