# StreamFinder — context for Claude

Portfolio iOS app: search a movie, see where you can stream / rent / buy it in your region.
Built to demonstrate senior-level architecture, testability, and concurrency patterns.

## Stack

- Swift 6, strict concurrency
- SwiftUI + `@Observable` + `NavigationStack`
- async/await throughout (no Combine in feature code)
- SwiftData for local persistence
- Swift Testing for unit tests, XCTest for UI
- iOS 17+ deployment target

## Architecture

Three layers, hard boundaries enforced by Swift Package separation. See `README.md` for the full diagram.

- **Domain** (no deps) — entities, value types, errors, `MovieRepository` protocol.
- **TMDBClient** (depends on Domain) — HTTP, DTOs, adapter to `MovieRepository`.
- **Persistence** (depends on Domain) — SwiftData stores for history and watchlist.
- **DesignSystem** (no deps) — reusable views, colors, typography.
- **Feature_*** (depends on Domain + DesignSystem) — one package per screen.
- **App** (depends on all) — composition root that wires concrete implementations.

The single most important rule: **Features depend on Domain protocols, never on TMDB or SwiftData directly.**

## Conventions

- One feature = one Swift Package. Don't share view code across features; promote it to `DesignSystem`.
- DTOs (Decodable types) live only in `TMDBClient` and never leak.
- Errors at the Domain boundary are mapped to `MovieError`; `URLError` and decoding errors die in the adapter.
- Typed IDs (`MovieID`, `ProviderID`) over raw `Int`.
- `Region` is a value type, never a String.
- View models are `@Observable` classes that depend on `MovieRepository` injected via init. Never construct dependencies inside view models.
- Search-as-you-type uses 300 ms debounce + Task cancellation via `.task(id:)`.
- New work goes on a feature branch; PR titles follow Conventional Commits.

## Decisions made so far

Captured so future Claude sessions don't relitigate settled questions. If you want to challenge one, surface it explicitly — there's reasoning behind each.

### Data source: TMDB, not per-service APIs

Netflix / Disney+ / HBO / etc. don't expose public availability APIs. The realistic options were aggregators: **TMDB** (free, JustWatch-backed), Watchmode (paid), RapidAPI Streaming Availability (paid trial). Picked TMDB for price + data quality (JustWatch-sourced, same as the paid options). The "fan-out concurrency" exercise the project promises lives now in the detail screen — `async let` over movie details, providers, similar movies — not in calls to N different services.

### One Swift Package per layer

`Domain`, `TMDBClient`, `Persistence`, `DesignSystem`, one `Feature_*` per screen, App target on top. Boundaries enforced at *build time* by package separation, not just convention. Cost: a few minutes per new package. Benefit: the rule "features can't import TMDB" is physically impossible to violate.

### Local packages: only outermost ones added at project level

Adding both `Domain` and `TMDBClient` as project-level local packages collides with `TMDBClient`'s `.package(path: "../Domain")` declaration, producing "multiple top-level packages named 'Domain'" SPM errors. Rule: only packages the App target *directly* uses get added at the project level; transitive deps resolve through their parent's `Package.swift`. The App target still adds both as frameworks in `General → Frameworks, Libraries, and Embedded Content`.

### Composition root in the App target

`StreamFinderApp.init()` is the **only** place concrete implementations (`LiveTMDBClient`, `TMDBMovieRepository`) are constructed. Everything downstream depends on `MovieRepository`, the protocol from Domain. No DI container — at this size, a framework would be vanity.

### Typed domain errors mapped at the boundary

`MovieError` enumerates user-visible failure states (offline, timeout, rateLimited, unauthorized, notFound, server, decoding, cancelled, unknown). `URLError`, `DecodingError`, `CancellationError` die inside `TMDBMovieRepository.mapErrors` and never reach feature code. View error states can switch exhaustively over `MovieError`.

### Build-time secrets via Run Script Phase, not Info.plist

`Secrets.xcconfig` defines `TMDB_API_KEY` (gitignored). The App target has a "Generate Secrets" Run Script Phase before "Compile Sources" that writes `StreamFinder/GeneratedSecrets.swift` containing the value as a Swift constant. `AppConfig.tmdbAPIKey` reads from `GeneratedSecrets`, guards against the sentinel string `your_tmdb_api_key_here`, and `preconditionFailure`s with actionable instructions on misconfiguration.

Why not `INFOPLIST_KEY_TMDB_API_KEY = $(TMDB_API_KEY)`? Apple's `INFOPLIST_KEY_<name>` mechanism only honors recognized Info.plist keys when `GENERATE_INFOPLIST_FILE = YES`. Arbitrary custom keys are silently dropped — confirmed empirically. The Run Script approach is more reliable and more flexible.

The placeholder string `your_tmdb_api_key_here` is the canonical "not configured" sentinel: same value in `Secrets.example.xcconfig`, in the bash `${TMDB_API_KEY:-...}` fallback, and in the AppConfig guard. One sentinel, one fix message.

The Run Script Phase declares `$(SRCROOT)/StreamFinder/GeneratedSecrets.swift` as an Output File so Xcode's build sandbox permits the write. Optional Input File `$(SRCROOT)/Secrets.xcconfig` lets dependency analysis re-run the script when the key changes.

### `#Preview` uses a private fake repository

ContentView is init-injected with a `MovieRepository`, so previews need an instance. A `private struct PreviewMovieRepository` at the bottom of `ContentView.swift` provides minimal answers; methods not exercised by the preview just `fatalError`. Acceptable in preview-only code; **not** acceptable in test fakes (those need full implementations or explicit XCTUnimplemented patterns).

### SwiftData over Core Data, Swift Testing over XCTest, no Combine in features

Two SwiftData stores (history, watchlist) with no expected migrations — ergonomics win. Swift Testing (`@Test`) for unit tests because iOS 17+ supports it and Apple is steering us there. UI tests stay on XCTest because Swift Testing doesn't cover that surface yet. Combine deliberately absent in feature code: `async/await` + `@Observable` covers our needs without adding a parallel reactive mental model.

## Testing

- Domain logic: unit tests, no fakes needed.
- View models: unit tests against a fake `MovieRepository`.
- TMDB adapter: unit tests with a stubbed `TMDBClient`.
- `LiveTMDBClient`: integration tests with `URLProtocol` against fixture JSON in `Tests/Fixtures/`.
- Critical UI flow: one UI test (search → detail → providers).
- Before opening a PR, run `swift test` in each package and `⌘U` on the App scheme.

## Non-goals (do not add without discussing first)

No auth, no social features, no video playback, no analytics, no iCloud sync, no iPad-specific layouts.

## Setup

See `README.md` "Quick start". A free TMDB API key is required and goes in `Secrets.xcconfig` (gitignored).

## Working agreements with Claude

- Always propose the change as a diff before applying broad edits across multiple files.
- When adding a new feature package, copy the structure of an existing one (`Feature_Search`) — don't invent a new layout.
- When adding a dependency, justify it in the PR description.
- Tests are not optional; new behavior ships with tests in the same PR.
- If you find yourself wanting to bypass a layer (e.g. importing `TMDBClient` from a feature), stop and surface it — it's almost always a smell.
