# StreamIn

**Where can I stream this movie — here, or on the services I already pay for abroad?**

[![CI](https://github.com/martingarcialopez/StreamIn/actions/workflows/ci.yml/badge.svg)](https://github.com/martingarcialopez/StreamIn/actions/workflows/ci.yml)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2_strict_concurrency-F05138?logo=swift&logoColor=white)
![iOS 26](https://img.shields.io/badge/iOS-26-000000?logo=apple&logoColor=white)
![SwiftUI · SwiftData](https://img.shields.io/badge/SwiftUI-SwiftData-0A84FF)
![Built with Claude Code](https://img.shields.io/badge/built_with-Claude_Code-D97757)
![App Store](https://img.shields.io/badge/App_Store-coming_soon-lightgrey?logo=appstore&logoColor=white)

StreamIn is a native iPhone and iPad app. Search a movie and it tells you, at a
glance, whether you can watch it tonight: on your services or a free one at
home, or on *your* services in another country (the VPN use case). Every
country TMDB covers, in English and Spanish. **App Store release is the next
milestone.**

<p align="center">
  <img src="docs/screenshots/demo.gif" width="300" alt="A 20-second demo on an iPhone: the slot machine spins, a search for Spirited Away, its page says Watch now on Netflix, the heart saves it, and it shows up in the Watchlist tab">
</p>

<table>
  <tr>
    <th width="25%">🎰 Spin or search</th>
    <th width="25%">🔎 Results lead with where</th>
    <th width="25%">❤️ Your watchlist</th>
    <th width="25%">📺 Your services</th>
  </tr>
  <tr>
    <td width="25%" align="center"><img src="docs/screenshots/landing-slot-machine.png" width="200" alt="The search landing page: a slot machine whose three reels stopped on a movie poster, a streaming service and a flag, above the Streamin wordmark, its i dotted with a gold globe, and the search bar"></td>
    <td width="25%" align="center"><img src="docs/screenshots/search-results.png" width="200" alt="Search results for Night: each row shows its poster, year and where to watch it: Netflix at home, Netflix abroad behind a globe, Disney+, or Not streaming here"></td>
    <td width="25%" align="center"><img src="docs/screenshots/watchlist.png" width="200" alt="The Watchlist tab: Spirited Away, Whiplash and Greyhound with their posters, directors and the services that carry them, Whiplash&#39;s behind a globe"></td>
    <td width="25%" align="center"><img src="docs/screenshots/onboarding-services.png" width="200" alt="Onboarding: the Streamin wordmark over Pick the services you pay for, with Prime Video, Disney+ and Netflix picked and a grid of the other services available in the United Kingdom"></td>
  </tr>
</table>

Each movie's page leads with one verdict:

<table>
  <tr>
    <th width="33%">🍿 Watch now</th>
    <th width="33%">🌍 On your services abroad</th>
    <th width="33%">📖 Go read a book</th>
  </tr>
  <tr>
    <td width="33%" align="center"><img src="docs/screenshots/details-watch-now.png" width="250" alt="Details for Spirited Away: Watch now, on Netflix in the UK"></td>
    <td width="33%" align="center"><img src="docs/screenshots/details-abroad.png" width="250" alt="Details for Whiplash: on your services abroad, Netflix in the United States, the Netherlands, South Korea and three more countries"></td>
    <td width="33%" align="center"><img src="docs/screenshots/details-read-a-book.png" width="250" alt="Details for Greyhound: go read a book, not on your services here or abroad"></td>
  </tr>
  <tr>
    <td align="center">One of your services, or a free one, has it in your country.</td>
    <td align="center">Not at home, but your services carry it in other countries.</td>
    <td align="center">Not on your services, here or abroad.</td>
  </tr>
</table>

## In 30 seconds

StreamIn is two projects in one: **a production-quality SwiftUI app**, and **a
lab for building software with AI agents without lowering the bar.**

| | |
|---|---|
| 🏗️ **Architecture** | 11 Swift packages, one per layer. Features can't import the network client or SwiftData: it doesn't compile. |
| ⚡ **Swift concurrency** | Swift 6.2 strict concurrency, async/await end to end, no Combine. `async let` and task-group fan-outs, cancellation, actors. |
| 🧪 **Quality gates** | 353 Swift Testing tests. Every PR builds and tests on a clean macOS runner, gets an AI review whose verdict gates the merge, and a human review. |
| 🤖 **AI workflow** | Built with Claude Code: issue-driven, parallel agents in their own worktrees, a reviewer subagent, skills, hooks and an Xcode MCP server — all versioned in this repo. |
| 📏 **Measured, not claimed** | A [workflow log](docs/workflow-log.md) records every workflow change and what it actually improved, including what failed. |

## What's inside the app

- **A slot machine to start.** The search page spins three reels (a trending
  movie, a streaming service, a country) that stop on a winning line. Pull the
  lever or tap it to spin again. A dark "cinema" theme runs through every
  screen; with Reduce Motion the reels jump straight to their stop.
- **Search** where each result leads with where you can watch it: your services
  and free ones at home; otherwise yours abroad, behind a globe; otherwise the
  other services in your region. Rows fill in one by one as their answers
  arrive.
- **Details** that leads with one verdict, then shows where else it streams:
  a spinning globe and the countries that carry it for each of your services,
  popular VPN countries first.
- **An honest "abroad".** It only counts services whose catalogue follows your
  location (Netflix yes, Prime Video no). From an EU home it also skips the rest
  of the EU, where portability rules already show your home catalogue.
- **Watchlist** saved with SwiftData: tap the heart, swipe to delete. Each saved
  movie shows the same where-to-watch line as a search result, and opens
  complete even offline.
- **Onboarding and Settings:** a grid of app-icon logos to pick your services
  (at home or worldwide), every region TMDB covers (about 150), the app's
  language, and an About section with TMDB's attribution.
- **English and Spanish.** The app follows the device's language, and can be
  switched inside it. Spanish movie data follows your region: Latin American
  titles in the Americas, Spain's elsewhere.

## Engineering highlights

### One package per layer, enforced by the compiler

```mermaid
flowchart TD
    App["App target<br/>composition root, tabs"] --> Features
    App --> TMDBClient
    App --> Persistence
    subgraph Features["Feature packages · one screen each"]
        Search[SearchFeature]
        Details[DetailsFeature]
        WatchlistF[WatchlistFeature]
        Settings[SettingsFeature]
    end
    Features --> Domain
    Features --> DesignSystem
    Features --> Shared["Preferences · ReferenceData · Watchlist"]
    Shared --> Domain
    TMDBClient -- "implements MovieRepository" --> Domain
    Persistence -- "implements WatchlistRepository<br/>(the only SwiftData import)" --> Domain
```

**Features depend on Domain protocols, never on TMDBClient or SwiftData.** A
feature's `Package.swift` doesn't list them, so the rule can't be broken by
accident. The app is testable without a network and the data source is
swappable. `StreamInApp.init()` is the only place concrete types are built: no
DI framework, dependencies go through `init`.

| Package | Holds |
|---|---|
| `Domain` | Entities, value types (`Region`, `Language`, typed IDs), `MovieRepository`, `WatchlistRepository`, typed `MovieError`, `WatchOptions` (the one reading of where to watch) |
| `TMDBClient` | HTTP client, DTOs, the TMDB adapter and the caching decorator |
| `Persistence` | A versioned SwiftData schema behind a `@ModelActor` repository |
| `Watchlist` | `WatchlistStore`: optimistic updates, ordered writes, per-item rollback |
| `Preferences` · `ReferenceData` | User settings; the provider and region catalogs, loaded at launch |
| `DesignSystem` | Tokens, the cinema theme, `ProviderLogo`, `ProviderLine`, `RemoteImage`, `SpinningGlobe` |
| `SearchFeature` · `DetailsFeature` · `WatchlistFeature` · `SettingsFeature` | One screen each, with its `@MainActor @Observable` view model |

### Decisions worth a look

- **Concurrency where it pays.** Details loads the movie and its availability
  in parallel with `async let`. Search fans out one availability request per
  result in a task group. Screens re-run with `.task(id:)`, SwiftUI cancels the
  previous run, and view models drop results from a superseded one.
- **A cache that shares requests, not just responses.** `MemoryCache` is an
  actor that stores in-flight *tasks*, so concurrent callers share one request.
  Failures are never cached; availability expires after 30 minutes, tested with
  an injected clock.
- **Complete on the first frame.** Provider names and logos are reference data,
  read synchronously from a `@MainActor` catalog and an in-memory image store,
  because `AsyncImage` always starts on its placeholder.
- **Typed errors at the boundary.** Transport and decoding errors become
  `MovieError` inside the adapter, so views switch over it exhaustively.
- **One brand, one provider.** TMDB has several IDs per service (Netflix and its
  ad tier, regional Prime Video). `ProviderAliases` merges them so your
  subscription matches in every country.
- **One answer, three screens.** `WatchOptions` in Domain reads a movie's
  availability against your region and services once. Details' verdict and the
  Search and Watchlist rows all render that same reading, so they can't
  disagree.
- **"Abroad" only promises what a VPN unlocks.** `CatalogScope` records whether
  each service's catalogue follows your location or your account, with a source
  per service. EU portability (Regulation 2017/1128) is modelled too, so an EU
  user isn't sent to another EU country for the catalogue they already have.
- **A slot machine without a game engine.** Each reel is an `Animatable` drum,
  with symbols 45° apart on a cylinder. The reels stop left to right, the lever
  answers to a tap or a drag, and VoiceOver reads the whole machine as one
  button: "Dune, on Netflix, in Spain".
- **A watchlist that never loses a tap.** Changes show at once, writes are
  queued in order, and a failed write rolls back that movie and raises one
  app-wide alert. If the store can't open, the app keeps going in memory.
- **Localization per package**, with generated symbols (`Text(.searchPrompt)`),
  so a missing key fails the build.
- **TMDB as the data source.** Streaming services have no public availability
  APIs; TMDB is free and its watch data comes from JustWatch, the same source
  the paid aggregators use.

## Built with AI, reviewed like production

The goal isn't "AI wrote it". It's **more throughput with the same bar**: every
change goes through the gates a senior team would set, and agents do the
legwork inside them.

```mermaid
flowchart LR
    Issue["GitHub issue<br/>acceptance criteria"] --> Session["Claude Code session<br/>own worktree, simulator, Xcode"]
    Issue -. "label: claude" .-> Bot["claude[bot]<br/>on GitHub"]
    Session --> Plan["Plan mode<br/>approved by Martín"]
    Plan --> Build["Implement + tests<br/>previews via Xcode MCP"]
    Build --> Local["ios-reviewer subagent<br/>+ local check"]
    Local --> PR[Pull request]
    Bot --> PR
    PR --> CI["macOS CI<br/>build + full test plan"]
    PR --> Review["AI review<br/>verdict gates the merge"]
    CI --> Human["Martín's review"]
    Review --> Human
    Human --> Main[(main)]
```

- **Context as code.** [`CLAUDE.md`](CLAUDE.md) holds the architecture,
  conventions and settled decisions; [path-scoped rules](.claude/rules) load the
  Swift/SwiftUI guide, localization and secrets rules only when matching files
  are touched.
- **Skills that wrap tested scripts** ([`.claude/skills/`](.claude/skills)):
  `start-issue`, `parallel`, `localize` (en + es + regenerated symbols),
  `new-package` (scaffold and register in the Xcode project), `commit` and
  `ship-phase` (review → local check → PR → CI).
- **Parallel agents.** `/parallel <issue>` starts a session in its own git
  worktree with its own simulator; local builds queue behind a shared lock.
  Phases 3 and 4 were built side by side this way, with claude[bot] taking the
  small, well-specified issues.
- **A reviewer with teeth.** [`ios-reviewer`](.claude/agents/ios-reviewer.md)
  checks every change for concurrency bugs, layer violations, SwiftUI mistakes
  (with a vendored [SwiftUI checklist](.claude/skills/swiftui-pro)), missing
  tests and localization gaps — locally before the PR and on GitHub for every
  push. Its verdict is a required status: a critical or high finding blocks the merge.
- **CI is the source of truth.** Agents quote the CI run, never their own local
  runs. Branch protection applies to everyone, admins included.
- **Hooks for the boring guards**: protect generated and secret files,
  regenerate string symbols after catalog edits, lint `project.pbxproj`.
- **Translations reviewed like copy, not code.** A script exports every string
  to a Numbers workbook, one sheet per screen. A reviewer edits English and
  Spanish in place, previews them in the simulator, and the import writes the
  edits back to the String Catalogs, checking every placeholder.

**What it's caught.** In the Watchlist phase, `ios-reviewer` found 4 medium and
5 low issues across three PRs — one a real race where a swipe could delete the
wrong row — all fixed before the PR opened. Martín found no code bugs after
hand-off. The [workflow log](docs/workflow-log.md) has the per-phase scorecard
and the things that broke along the way.

**By the numbers:** 54 merged PRs, 6 of them written end to end by claude[bot]
from an issue. Every commit Claude makes carries a co-author trailer, and
Martín reviews every PR before it merges.

## Roadmap

| Phase | | |
|---|---|---|
| 1–2 | Design system, search, caching, provider catalog, iPhone + iPad | ✅ |
| 3 | Watchlist with SwiftData | ✅ |
| 4 | Details redesign: one verdict first | ✅ |
| 5 | Design and UX pass on every screen: slot machine, cinema theme, where-to-watch rows | ✅ |
| 6 | App Store: privacy manifest, TMDB attribution, every region, icon, launch screen and logo, store screenshots ✅; TestFlight and submission next | 🔄 |

After 1.0: French, and on-device Foundation Models for natural-language search
("a feel-good 90s comedy") if it earns its place. Full plan in
[`docs/roadmap.md`](docs/roadmap.md).

## Quick start

Requires Xcode 26 (built with 26.6) and an iOS 26.2 or later simulator.

1. Clone the repo and get a free TMDB API key at <https://developer.themoviedb.org/>.
2. Create the local secrets files (gitignored) and enable the git hooks, then
   put your key in `Secrets.xcconfig`:

   ```bash
   scripts/setup.sh
   ```

3. Open `StreamIn.xcodeproj`, pick the `StreamIn` scheme and run it on an iPhone
   or iPad simulator.

**Tests:** ⌘U runs every package's tests in one build (`StreamIn.xctestplan`).
The same run CI makes:

```bash
xcodebuild test -project StreamIn.xcodeproj -scheme StreamIn -testPlan StreamIn -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

<details>
<summary>More: testing, debugging and project layout</summary>

**What's tested** (Swift Testing, in every package)

- **Domain:** provider alias groups and merging, where-to-watch ranking,
  catalogue scope and EU portability, region flags and defaults, language
  matching.
- **TMDBClient:** the HTTP client against a stubbed `URLProtocol`, DTO-to-domain
  mapping and errors, the cache's request sharing, expiry and failure handling.
- **Persistence and Watchlist:** the SwiftData repository, the store's ordering,
  rollback and failure reporting.
- **View models** against fake repositories: search (repeated requests, partial
  retries, region and language changes), details (verdicts, load states,
  cancellation), the services picker.

CI reports per-package results and line coverage in each run's summary. Views
are checked with previews at standard and large Dynamic Type sizes (the app is
dark only). Still to come: one UI test for search → details → providers.

**Launch flags** (scheme → Run → Environment Variables)

- `STREAMIN_DISABLE_CACHE=1` puts every request on the wire, for a proxy such as
  Proxyman.
- `STREAMIN_IN_MEMORY_WATCHLIST=1` starts with an empty, throwaway watchlist.

The packages are iOS-only, so `swift test` doesn't run them on macOS. A build
step turns `Secrets.xcconfig` into `StreamIn/Secrets/GeneratedSecrets.swift`
on every build, so after changing the key just build again.

**Layout**

```
StreamIn/
├── StreamIn/        App target: composition root, tabs, resources
├── Packages/        Domain, TMDBClient, Persistence, Watchlist, Preferences,
│                    ReferenceData, DesignSystem and the four *Feature packages
├── .claude/         Claude Code setup: skills, rules, the reviewer subagent
├── .github/         CI, Claude workflows, the review verdict script
├── scripts/         Setup, per-worktree simulators, the build lock, translations
├── site/            Privacy and support pages (GitHub Pages)
└── docs/            Roadmap, workflow log, screenshots
```

</details>

## Non-goals

No accounts, social features, video playback, analytics, iCloud sync or
iPad-specific layouts. Rent and buy prices stay out of v1: the audience watches
on free and subscription services.

## Acknowledgements

Movie data and watch-provider data courtesy of
[The Movie Database (TMDB)](https://www.themoviedb.org/). This product uses the
TMDB API but is not endorsed or certified by TMDB. Streaming availability data is
provided by [JustWatch](https://www.justwatch.com/).
