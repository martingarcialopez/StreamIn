# StreamIn — roadmap to the App Store

Where the project stands and what's left, phase by phase. Start every session
by reading this file; update it when a phase ships or a plan changes. The tasks
themselves live in GitHub: each phase is a milestone, each task an issue.

**How we work** is in [CLAUDE.md](../CLAUDE.md) (tools, rules, decisions) and
[docs/workflow-log.md](workflow-log.md) (what each workflow change improved).
This file doesn't repeat them.

## Status (Oct 29, 2026)

| Phase | What | State |
|---|---|---|
| 1 | DesignSystem package + landing page | ✅ May 2026 |
| 2 | Caching, provider catalog, search/Settings fixes, iPhone + iPad | ✅ [#1](https://github.com/martingarcialopez/StreamIn/pull/1) |
| — | Workflow foundation: rules, skills, `ios-reviewer`, hooks, Xcode MCP | ✅ [#2](https://github.com/martingarcialopez/StreamIn/pull/2) |
| — | Claude GitHub app: `@claude`, automatic PR review | ✅ [#3](https://github.com/martingarcialopez/StreamIn/pull/3), [#4](https://github.com/martingarcialopez/StreamIn/pull/4) |
| — | `commit` skill: gitmoji, co-author trailer, one-prompt commit + push | ✅ [#5](https://github.com/martingarcialopez/StreamIn/pull/5) |
| — | Review follow-ups: Details error state, one logo per brand, translated languages only, README, roadmap in the repo | ✅ [#6](https://github.com/martingarcialopez/StreamIn/pull/6) |
| — | macOS CI + issue-driven work (workflow upgrades 1–2) | ✅ [#7](https://github.com/martingarcialopez/StreamIn/pull/7) |
| — | [Workflow upgrades](https://github.com/martingarcialopez/StreamIn/milestone/1) 3–5 | 🔄 #9 ✅ (`/parallel`, [#62](https://github.com/martingarcialopez/StreamIn/pull/62)); #8: screenshots in review ([#71](https://github.com/martingarcialopez/StreamIn/pull/71)), UI test left; #10 open |
| — | PR review gate: `ios-reviewer` on every push, verdict as a commit status | ✅ [#52](https://github.com/martingarcialopez/StreamIn/pull/52), [#57](https://github.com/martingarcialopez/StreamIn/pull/57), [#64](https://github.com/martingarcialopez/StreamIn/pull/64), [#70](https://github.com/martingarcialopez/StreamIn/pull/70) |
| 3 | [Watchlist (Persistence + SwiftData)](https://github.com/martingarcialopez/StreamIn/milestone/2) | ✅ [#42](https://github.com/martingarcialopez/StreamIn/pull/42), [#39](https://github.com/martingarcialopez/StreamIn/pull/39), [#40](https://github.com/martingarcialopez/StreamIn/pull/40), [#43](https://github.com/martingarcialopez/StreamIn/pull/43), [#68](https://github.com/martingarcialopez/StreamIn/pull/68) |
| 4 | [Details page redesign](https://github.com/martingarcialopez/StreamIn/milestone/3) | ✅ [#41](https://github.com/martingarcialopez/StreamIn/pull/41), [#50](https://github.com/martingarcialopez/StreamIn/pull/50), [#55](https://github.com/martingarcialopez/StreamIn/pull/55) |
| — | README as a portfolio front page, with the three verdicts | ✅ [#65](https://github.com/martingarcialopez/StreamIn/pull/65), [#74](https://github.com/martingarcialopez/StreamIn/pull/74) |
| 5 | [App design & UX](https://github.com/martingarcialopez/StreamIn/milestone/4) | next: #46–#49, one screen each, and #72 (rank services per search row) |
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

## Phase 3 — Watchlist ✅

**Goal:** save movies from Details with a heart, list them in the Watchlist tab,
open Details from there.

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
- **Failed writes are said once (decided Oct 14, in #35):** the store keeps the
  latest failed add or remove as `writeFailure` until it's dismissed, and
  `RootView` shows one alert for it, whichever tab the change came from. A failed
  `refresh` isn't reported: the user didn't ask for it.

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

## Phase 4 — Details page redesign ✅

**Goal:** the answer to "can I watch this?" comes first, clear at a glance, and nothing is said twice.

One outlined card sits right after the title, metadata and directors; the overview follows it.
"Where to watch · 🇪🇸" cuts its top border on the left, and the home region's other services cut it
on the right: up to 5 small logos + "+N", unlabeled since the flag already says where. Inside, only
the answer: one verdict, an emoji plus a tinted headline.

| Verdict | When | Card content |
|---|---|---|
| 🍿 **Watch now** | One of your services or a free one carries it at home | Big logos (yours, then free); no services picked: a small "Choose your services" button |
| 🌍 **On your services abroad** (a real globe, flicked and slowing to a stop) | Nothing of yours or free at home; your services carry it elsewhere | One row per service: logo, name, top 3 flags `+N` ›, opening the full region list. Popular VPN countries first |
| 📖 **Go read a book** | Nothing of yours or free at home, none of yours abroad | "Not on your services, here or abroad.", or "Not available to stream here or on your services." when no service carries it here |
| (prompt) | No services picked, nothing free at home | "Add the streaming services you pay for…" + "Choose your services" |

**Decided (Oct 12):**
- **Rent and buy stay hidden in v1**: the audience wants free, subscription and VPN options. The data
  stays in Domain.

**Decided (Oct 13, design review after testing #36's first layout):**
- **One verdict.** Free at home counts as much as your own services, and either one hides the abroad
  block: there's no reason to reach for a VPN. "Not available" is said once.
- **Other services in your region are secondary:** small logos (22pt) on one wrapping line, never a
  section of their own.
- **No VPN in the copy.** "On your services abroad" says it without inviting App Review trouble.
- **No captions under logos;** minimal chrome. Logos are icon-only (VoiceOver reads the names).
- **Credits** ("Powered by TMDB · Availability by JustWatch") go in the search landing page footer,
  not on Details.

**Issues**

1. #33 — `DetailsViewModel` state and the `makeModel` test helper (claude[bot])
2. #36 — The card: `verdict`, popular-region order, strings via `localize`, seven previews
3. #44 — Credits footer on the landing page

**Verify:**
- Each verdict on the simulator: LOTR (Watch now), Peter Pan 2003 (abroad), Peter Pan 1953 (read a
  book, Disney+ in Spain), La bola negra (read a book, nothing).
- iPhone and iPad layouts both hold, in en and es.

---

## Phase 5 — App design & UX

**Goal:** bring every screen up to the level of the Phase 4 Details redesign. One issue per screen,
each starting with a short design Q&A, then previews and the simulator (iPhone and iPad, en and es).

**Reuse the Phase 4 language where it fits:**
- `AppPalette.background` pages
- tinted cards with legends on the border
- app-icon `ProviderLogo`s
- emoji + semibold headlines
- `SpinningGlobe`

A pattern used by two screens moves to DesignSystem.

**Issues**

1. #46 — Landing page and its animation.
   - The conic-gradient halo is stashed as `landing-halo-wip` (12 s rotation, blur 28, opacity 0.7):
     restore and refine it, or redo it.
   - Reduce Motion, light and dark, small iPhones, no overlap with the logo or tab bar.
   - The credits footer (#44) lives here.
2. #47 — Search results: the same language as Details, maybe a verdict hint per row.

   **Decided (Oct 29, design Q&A):**
   - **No verdict label per row.** A plain line of logos reads better in a list than an emoji and a
     headline.
   - **The logos are Details' answer, in Details' order:** your services at home, then free ones.
     Without either, your services abroad, behind a small, still `SpinningGlobe` (only Details'
     card spins it; one per row would be too busy). Up to 3 logos at
     `LogoSize.small`, then "+N" (`ProviderLogoStrip`, promoted to DesignSystem from Details).
   - **No logos:** a quiet caption, "Not on your services", or "Not streaming here" when no
     subscription or free service carries it at home.
   - **A failed row** says "Couldn't check availability"; pull to refresh retries it, and Details
     still opens and loads on its own.
   - **The system inset list stays,** on `AppPalette.background` pages with
     `AppPalette.secondaryBackground` rows. Card rows (one rounded card per movie, bigger posters,
     "2003 · ★ 7,1") were tried and dropped: the single list reads better. At accessibility text
     sizes the poster moves above the title. VoiceOver reads each row as one element and names
     every provider, even those behind "+N".
   - **One derivation for both screens:** `WatchOptions` (Domain) reads an `AvailabilityBundle`
     from the home region and your services. Rows fetch `availabilities(for:in:)`, the same TMDB
     request and cache entry as before, so the abroad logos cost nothing and Details opens from the
     cache.
3. #48 — Watchlist tab, after #35: an inviting empty state, maybe "what can I watch tonight".
4. #49 — Settings, the services picker and onboarding's reuse of it.

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
- Search: filter out "empty" movies (no year, no runtime, no rating, no backdrop, like "The Lord of
  the Rings: Shadow of the Past"); they only add noise to the results (noted Oct 13, #45).
- Details: tapping a service logo zooms it and shows its name with a playful animation (agreed
  Oct 13, deferred). Also a candidate: opening TMDB's JustWatch page (`externalLink`) from the card.
