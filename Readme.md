# StreamFinder

> Search any movie, see where you can stream, rent, or buy it in your country.

<!-- Replace with a 5–10s gif of the search → detail → providers flow. -->
![demo](docs/demo.gif)

---

## What it does

Type a film, pick the right one from the search results, see at a glance which streaming services have it in your country (subscription / rent / buy / free with ads). Search history and a personal watchlist are stored locally.

## Status

Portfolio project. Single developer, ~2 weeks of work. Not in the App Store.

## Quick start

1. Clone the repo.
2. Get a free TMDB API key at <https://developer.themoviedb.org/>.
3. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and fill in `TMDB_API_KEY = your-key`. (`Secrets.xcconfig` is gitignored.)
4. Open `StreamFinder.xcworkspace`, select the `App` scheme, run.
5. Tests: `⌘U` on the `StreamFinderTests` scheme, or `make test`.

Requires Xcode 16+, iOS 17+ deployment target.

## Architecture

Three layers, hard boundaries enforced by Swift Package separation.

```
┌──────────────────────────────────────────┐
│  App target                              │
│  - Composition root, DI wiring           │
│  - Routing                               │
└──────────────────────────────────────────┘
            │ depends on
            ▼
┌──────────────────────────────────────────┐  ┌────────────────┐
│  Feature_Search / Feature_Detail / ...   │  │  DesignSystem  │
│  - SwiftUI views + view models           │  │  - Reusable UI │
└──────────────────────────────────────────┘  └────────────────┘
            │ depends only on
            ▼
┌──────────────────────────────────────────┐
│  Domain                                  │
│  - Entities, value types, errors         │
│  - Repository protocols (the boundaries) │
│  - NO Foundation networking, NO UI       │
└──────────────────────────────────────────┘
            ▲ implemented by
            │
┌──────────────────────────────────────────┐  ┌────────────────┐
│  TMDBClient                              │  │  Persistence   │
│  - HTTP, JSON, DTOs                      │  │  - SwiftData   │
│  - Adapter to Domain.MovieRepository     │  │  - History,    │
└──────────────────────────────────────────┘  │    watchlist   │
                                              └────────────────┘
```

The single most important rule: **Features depend on Domain protocols, never on TMDB or SwiftData directly.** That's what makes the app testable without a network and swappable if TMDB ever disappears or gets paywalled.

### Module layout

| Package        | Depends on                | Purpose                                                |
| -------------- | ------------------------- | ------------------------------------------------------ |
| `Domain`       | (nothing)                 | Pure types, repository protocols, errors               |
| `TMDBClient`   | `Domain`                  | HTTP client + DTOs + adapter to `MovieRepository`      |
| `Persistence`  | `Domain`                  | SwiftData stores for history and watchlist             |
| `DesignSystem` | (nothing)                 | Reusable views, colors, typography                     |
| `Feature_*`    | `Domain`, `DesignSystem`  | A single screen + its view model                       |
| `App`          | all of the above          | Composition root, app entry point                      |

## Key decisions and tradeoffs

### TMDB instead of "calling Netflix / HBO / Disney+ in parallel"

The streaming services don't expose public availability APIs. The realistic options are aggregator APIs: TMDB (free, JustWatch-backed), Watchmode (paid), or RapidAPI's Streaming Availability (paid trial). I picked **TMDB** because it's free, well-documented, and the data is sourced from JustWatch — the same source the paid options use. The "fan-out concurrency" exercise survived the pivot: it now lives in the detail screen, where movie details, providers, and similar movies are fetched in parallel with `async let`.

### SwiftUI primary, Swift Concurrency end-to-end

`async/await` everywhere, including networking, persistence, and view models. No Combine in feature code — a personal taste call: it adds a parallel mental model to what `AsyncSequence` and `Observable` already cover, and the scope here doesn't justify both. UIKit nowhere; the multi-paradigm flex isn't worth the readability cost on a project this size.

### SwiftData over Core Data

Two stores (history, watchlist), zero migrations needed during the project's lifetime — SwiftData's ergonomics win. If this grew to need iCloud sync at scale or richer querying, I'd revisit Core Data. The `Persistence` package wraps SwiftData behind protocols so the app code doesn't import SwiftData; that swap stays cheap.

### Hand-rolled DI

A composition root in the App target wires everything up. No DI framework. With this much surface area, a container would be vanity.

### Typed errors at the domain boundary

`MovieError` enumerates user-visible failure states (offline, rate limited, not found, etc.). Network and decoding errors are mapped into this enum at the data-layer adapter — feature code never sees a `URLError`. The benefit is that every view's error state can switch exhaustively on the enum, so we can't forget a case at compile time.

### Region as a first-class value type

Watch availability is region-specific. `Region` is a value type passed through every relevant call. A user-visible setting controls it; the default is the device locale.

### Search: debounce + task cancellation, not buttons

Search-as-you-type with 300 ms debounce. Each keystroke creates a new `Task` and cancels the prior one via `.task(id: query)`. This is where the concurrency exercise really pays for itself — and it's tested with a virtual clock.

## Testing

Pyramid, weighted toward unit tests for fast feedback.

| Layer                            | Test type    | What's verified                                         |
| -------------------------------- | ------------ | ------------------------------------------------------- |
| `Domain`                         | Unit         | Pure logic, value semantics                             |
| TMDB adapter                     | Unit         | DTO → domain mapping, error mapping, with stubs         |
| `LiveTMDBClient`                 | Integration  | Real HTTP against recorded fixtures via `URLProtocol`   |
| View models                      | Unit         | State transitions, given a fake `MovieRepository`       |
| Search debounce / cancellation   | Unit         | Behavior over time using a virtual clock                |
| Critical UI flow                 | UI test      | Search → detail → see providers                         |

Anything network-heavy is faked at the `MovieRepository` boundary. The `TMDBClient` itself is tested separately with `URLProtocol` stubs against fixture JSON in `Tests/Fixtures/`.

## Non-goals (deliberately scoped out)

- **No authentication or user accounts.** Watchlist is local-only.
- **No social features** (sharing, comments, ratings).
- **No video playback** — we link out to providers' apps when possible, otherwise the JustWatch web link.
- **No iPad or macOS adaptations** beyond what SwiftUI gives for free.
- **English and Spanish only.** Region picker covers US, ES, UK, FR, DE.
- **No iCloud sync.** Watchlist stays on device.
- **No analytics or crash reporting.** I'd add Sentry or Firebase Crashlytics if this were going to ship.

## What I'd do with more time

- **Result caching.** Today every search hits TMDB. A simple in-memory + SwiftData cache keyed by `(query, page)` with TTL would cut latency on the second search.
- **Watchlist availability change notifications.** A weekly background fetch checks the watchlist and notifies "*Inception* is now on Netflix US."
- **Provider deep links.** Today the link goes to JustWatch; ideally we open the provider's app directly when installed.
- **Snapshot tests** for the major view states (loading, empty, populated, error).
- **A small CI matrix** running tests on iOS 17 and 18 simulators.
- **Modularize Persistence per feature** if the data model grows.

## Tech stack

- Swift 6, Swift Concurrency strict mode
- SwiftUI, `Observable`, `NavigationStack`
- SwiftData
- Swift Testing (`@Test`) for unit tests, XCTest for UI tests
- GitHub Actions for CI (build + test on PR)

## Project structure

```
StreamFinder/
├── App/                        # App target (composition root)
├── Packages/
│   ├── Domain/
│   ├── TMDBClient/
│   ├── Persistence/
│   ├── DesignSystem/
│   └── Features/
│       ├── Search/
│       ├── MovieDetail/
│       ├── History/
│       └── Settings/
├── Tests/
│   └── Fixtures/               # Recorded TMDB JSON
├── docs/
│   └── demo.gif
├── Secrets.example.xcconfig
└── README.md
```

## Acknowledgements

Movie data and watch provider data courtesy of [The Movie Database (TMDB)](https://www.themoviedb.org/). This product uses the TMDB API but is not endorsed or certified by TMDB.
