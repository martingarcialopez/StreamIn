# StreamIn — context for Claude

Portfolio iOS app: search a movie and see where you can stream it — in your
region, and on the services you pay for in other regions (the VPN use case).
Built to demonstrate senior-level architecture, testability and Swift
concurrency, and to be built with a state-of-the-art agentic workflow
(see **How we work**).

## Stack

- Swift 6.2+, strict concurrency; iOS 26+, **iPhone and iPad**
- SwiftUI + `@Observable` + `NavigationStack`
- async/await throughout (no Combine in feature code)
- SwiftData for local persistence (watchlist, Phase 3)
- Swift Testing for unit tests, XCTest for UI tests

## Architecture

One Swift Package per layer; boundaries are enforced at build time.

| Package | Depends on | Holds |
|---|---|---|
| `Domain` | — | Entities, value types, `MovieRepository`, `MovieError` |
| `TMDBClient` | Domain | HTTP client, DTOs, `TMDBMovieRepository`, `CachingMovieRepository` |
| `Preferences` | Domain | `@Observable` user settings (region, language, subscriptions), UserDefaults-backed |
| `ReferenceData` | Domain | `ProviderCatalog` — provider names and logos, loaded at launch |
| `Persistence` | Domain, SwiftData | `WatchlistPersistence.makeRepository(storage:)` → an internal `@ModelActor` repository on a versioned schema; the only package that imports SwiftData |
| `Watchlist` | Domain | `WatchlistStore` — `@MainActor @Observable` saved movies, shared by Details and the Watchlist tab |
| `DesignSystem` | — | Tokens (`Spacing`, `Radius`, `LogoSize`, `Symbol`), `AppPalette`, `ProviderLogo`, `AppLogoMark`, `RemoteImage`, `SpinningGlobe` (map from `scripts/make-globe-map.swift`) |
| `SearchFeature`, `DetailsFeature`, `SettingsFeature`, `WatchlistFeature` | Domain, DesignSystem (+ Preferences, ReferenceData, Watchlist) | One screen each, with its view model |
| App (`StreamIn/`) | everything | Composition root (`StreamInApp`), `RootView`, tab containers |

**The most important rule: features depend on Domain protocols, never on
TMDBClient or SwiftData directly.**

## Conventions

- One feature = one package. Shared view code is promoted to DesignSystem, never imported across features.
- DTOs live only in TMDBClient; `URLError` / decoding errors are mapped to `MovieError` in the adapter.
- Typed IDs (`MovieID`, `ProviderID`); `Region` and `Language` are value types, never strings.
- View models are `@MainActor @Observable` classes with dependencies injected through `init`.
- Search: Landing pushes `SearchResultsRoute`; results re-run through `.task(id:)` (query + region + language) with cancellation.
- User-facing strings come from the package's String Catalog in en + es (`localize` skill).
- Settings is reachable from each tab's first screen only; pushed screens keep their toolbar for content actions.
- Swift/SwiftUI style rules: `.claude/rules/swift-swiftui.md` (loaded when editing Swift).

## How we work

- **Work starts from a GitHub issue.** Each roadmap phase is a milestone and its tasks are issues; [`docs/roadmap.md`](docs/roadmap.md) holds the direction, decisions and phase designs. Read it at the start of a session and update it when a phase ships. Start local work with `/start-issue <n>`; small, well-specified issues (`good-for-claude`) can go to claude[bot] with the `claude` label. When writing an issue for claude[bot], make it fit in one run: it can't wait for CI, so several steps become one commit each in the same PR, never "after step 1 is green".
- **One branch and one PR per issue or phase** (`feat/…`, `fix/…`, `chore/…`) into `main`, with `Closes #<n>` in the PR body. Martín reviews every PR on GitHub before merging. A hook blocks commits and pushes to `main`; branch protection requires CI and the review verdict.
- **CI is the source of truth.** The `CI` workflow builds the app and runs every package's tests on a clean macOS runner for each PR. A PR is verified when CI is green, and the PR quotes the run. Local runs (Xcode MCP, previews, `xcodebuild`) are fast feedback while working; never quote them as verification.
- **Check locally at the end of each task, not per edit**: build + tests of the packages touched, and render the previews of changed views. If something can't run, say so.
- **Before a PR**: the `ios-reviewer` subagent reviews the branch; `/ship-phase` runs review → local check → log → commit → PR → CI. On GitHub, `ios-reviewer` reviews every push to the PR, and its verdict gates the merge: any critical or high finding blocks it, medium is Martín's call, low or nothing passes. The `review-override` label lets a blocked PR merge, for that commit only.
- **Log workflow changes** and what they improved in `docs/workflow-log.md`.

### Parallel sessions

Two sessions never share one checkout: each gets its own worktree, branch and PR (#9).

- **Create it from an up-to-date `main`:**
  - `git worktree add ../StreamIn-<task> -b <type>/<task> origin/main`
  - Then copy the gitignored `Secrets.xcconfig` (and `.claude/settings.local.json`) into it.
- **Each worktree is its own world:**
  - Open its `StreamIn.xcodeproj` in a separate Xcode window, and use only that window in the Xcode MCP (`XcodeListWindows`, match the path).
  - Use a different simulator per session, so installs don't overwrite each other.
  - `-derivedDataPath .build/xcode` already builds separately per worktree.
- **Project memory is keyed by path,** so a worktree session may not load it. Its kickoff prompt restates the essentials: `gh` path, no commits without approval, and the files the other session owns.
- **When the other PR merges,** `git fetch && git merge origin/main`, resolve conflicts, run the local check, and push.
- **When done:** `git worktree remove ../StreamIn-<task>` and delete the branch.

| Tool | What it's for |
|---|---|
| `localize` skill | Add/update a string in a package catalog (en + es) and regenerate symbols |
| `new-package` skill | Scaffold a package and register it in the Xcode project (never hand-edit `project.pbxproj` for this) |
| `start-issue` skill | Start work on a GitHub issue: read it, plan, branch |
| `ship-phase` skill | Finish a phase and open its PR, then wait for CI (only when Martín asks) |
| `commit` skill | Every commit Claude makes: gitmoji Conventional Commits title, at most two short body lines, and `Co-Authored-By: Claude <model> <noreply@anthropic.com>` so GitHub shows the pairing. One prompt where Martín approves or edits the message, then commit and push; specific branch names. Martín commits solo work himself, outside Claude |
| `ios-reviewer` subagent | Read-only review against these rules, with `swiftui-pro` (its Swift and hygiene checks on every Swift change, its SwiftUI checks on view code): locally before every PR, and on GitHub for every PR |
| `swiftui-pro` skill | Paul Hudson's SwiftUI review checklist (MIT), vendored at v1.1 in `.claude/skills/swiftui-pro/` (see its `SOURCE.md`); `ios-reviewer` applies it, and the project's rules win where they differ |
| Hooks (`.claude/settings.json`) | Block commits to `main`; protect generated and secret files; regenerate string symbols after catalog edits; lint `project.pbxproj` after edits |
| `xcode` MCP server (`.mcp.json`) | Xcode's `mcpbridge`: build, test, render previews, search Apple docs. Needs Xcode running with the project open |
| Path rules (`.claude/rules/`) | Swift/SwiftUI guide, localization, secrets — loaded only for matching files |
| GitHub CI (`ci.yml`) | macOS runner: builds the app and runs `StreamIn.xctestplan` (every package's tests) on each PR and push to `main`; per-package test results and line coverage in the job summary. Required to merge |
| GitHub, claude[bot] (`claude.yml`, `claude-code-review.yml`) | Answers or pushes fixes when Martín writes `@claude` in a PR or issue (a new comment, or an edit that adds the mention); implements an issue labeled `claude` and opens its PR; reviews every push to a PR: Sonnet follows `ios-reviewer.md` and posts one review (the summary, plus a comment with a one-click suggestion per finding), resolves the threads it finds fixed, and `.github/scripts/review-verdict.sh` turns its findings into the required "ios-reviewer verdict" check (`@claude review` re-runs it). Runs on Linux, so it can't build — CI does, and it reads CI's results |

## Decisions

Settled — surface it explicitly before challenging one.

- **TMDB as the only data source.** Streaming services have no public availability APIs; TMDB is free and JustWatch-backed (same data as the paid aggregators). The concurrency showcase lives in the Details fan-out (`async let`) and the search-row availability fan-out.
- **One package per layer**, so "features can't import TMDB" is impossible to violate rather than a convention.
- **Every local package is referenced at project level**, and the App target links the products it imports. This builds cleanly with Xcode 26.6; the old "only the outermost packages" rule came from a "multiple top-level packages named 'Domain'" error that no longer reproduces.
- **Composition root in `StreamInApp.init()`** is the only place concrete types are built (`LiveTMDBClient`, `TMDBMovieRepository`, `CachingMovieRepository`, `ProviderCatalog`). No DI container.
- **Typed `MovieError`** (offline, timeout, rateLimited, unauthorized, notFound, server, decoding, cancelled, unknown): views switch exhaustively; transport errors never leave the adapter.
- **Build-time secrets** via a Run Script that generates `GeneratedSecrets.swift` from `Secrets.xcconfig` — details in `.claude/rules/secrets.md`.
- **Previews** use a `private struct PreviewMovieRepository` at the bottom of the view's file. `fatalError` is fine only in methods the preview never reaches: a view's `.task` runs in previews too, so render the preview once to check. Test fakes must be complete.
- **SwiftData over Core Data, Swift Testing over XCTest, no Combine.** One SwiftData store (watchlist); search history was dropped from scope.
- **Localization per package** with committed generated symbols, and an in-app language picker that drives both UI and TMDB (restart required) — details in `.claude/rules/localization.md`.
- **Caching and reference data** — see the next section.
- **Rent/buy aren't shown in v1**: the audience is free / subscription / VPN viewers. The data stays in the domain.
- **iPhone and iPad, nothing else**: `TARGETED_DEVICE_FAMILY = "1,2"`, iOS platforms only, "Designed for iPhone/iPad" on Mac and Vision Pro disabled. iPad keeps all four orientations (required for multitasking) and uses the same adaptive layouts — App Store submission needs iPad screenshots too.

## Caching and reference data

Three mechanisms, one per kind of data:

- **Provider reference data** — `ProviderCatalog` (`ReferenceData`), a `@MainActor @Observable` class rather than an actor, so views read it synchronously and render complete on their first frame. `RootView` loads it at launch (worldwide + home region) and on region change; screens may call `load(region:)` too — a no-op for loaded scopes that shares in-flight requests. No expiry.
- **Response caching** — `CachingMovieRepository` (`TMDBClient`) wraps `TMDBMovieRepository`, backed by the generic `MemoryCache` actor, which stores in-flight *tasks* so concurrent callers share one request. Search (query + page + language) and movie detail (id + language) last the session; availability (id + region) expires after 30 min and is shared between `availability(for:in:)` and `availabilities(for:in:)`. Failures are never cached.
- **Logo images** — `RemoteImageStore` + `RemoteImage` (`DesignSystem`): `AsyncImage` always starts on its placeholder, so `ProviderLogo` uses `RemoteImage`, which renders synchronously from memory. `RootView` prefetches subscribed providers' logos.

`LiveTMDBClient` keeps `urlCache = nil`, so all caching is app-level and testable. Launch with `STREAMIN_DISABLE_CACHE=1` (scheme → Run → Environment Variables) to put every request on the wire for Proxyman.

**Watchlist storage** — `StreamInApp` opens the SwiftData store through `WatchlistPersistence.makeRepository`; if it can't, that launch keeps the watchlist in memory and logs why, rather than crashing. `RootView` loads `WatchlistStore` at launch. Launch with `STREAMIN_IN_MEMORY_WATCHLIST=1` to start with an empty, throwaway watchlist.

`SearchViewModel` remembers the request behind the results on screen: the results screen's `.task` re-fires whenever it reappears (e.g. Details popped), and a repeated request keeps the results, only retrying rows whose availability never arrived.

## Testing

- Unit tests with Swift Testing: Domain logic, view models against fake repositories, the TMDB adapter against a stubbed client, caches with an injected clock.
- `StreamIn.xctestplan` (the shared `StreamIn` scheme's test plan) runs every package's tests in one build — ⌘U in Xcode, and what CI runs: `xcodebuild test -project StreamIn.xcodeproj -scheme StreamIn -testPlan StreamIn -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`. A new package's test target must be added to the test plan.
- The packages are iOS-only, so `swift test` doesn't run them on macOS. One package alone, from its directory: `xcodebuild test -scheme <Package> -destination 'platform=iOS Simulator,name=<iPhone>'`.
- Not written yet: `URLProtocol` fixture tests for `LiveTMDBClient`, and one UI test for search → details → providers. The app-level test targets still hold Xcode's templates.

## TODO: onboarding trigger (Phase 6)

Onboarding is presented whenever `prefs.subscribedProviderIDs.isEmpty` — handy while testing, wrong for release. Before shipping:

1. Add `hasCompletedOnboarding: Bool` to `Preferences` (UserDefaults key `settings.hasCompletedOnboarding`, default `false`).
2. In `RootView`'s launch `.task`, trigger on `!prefs.hasCompletedOnboarding`.
3. Set it from `OnboardingView`'s Done (and any Skip) button. Done stays enabled with zero services picked.

To see onboarding today, launch with `-settings.subscribedProviders.ids none`.

## Non-goals

No auth, social features, video playback, analytics, iCloud sync or iPad-specific layouts. AI features inside the app only if they add real user value (candidate after 1.0: on-device Foundation Models for natural-language search).

## Setup

See `README.md` → Quick start. A free TMDB API key goes in `Secrets.xcconfig` (gitignored). For the Xcode MCP server, open the project in Xcode and allow external agents when Xcode asks.

## Working agreements

- Propose broad multi-file changes as a plan or diff before applying them.
- New packages copy an existing package's layout (`new-package` skill).
- Justify any new dependency in the PR description.
- Tests aren't optional: new behavior ships with tests in the same PR.
- Wanting to bypass a layer (e.g. importing TMDBClient from a feature) is a smell — stop and surface it.
