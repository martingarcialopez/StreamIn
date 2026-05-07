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
- ***Feature** (depends on Domain + DesignSystem) — one package per screen, e.g. `SearchFeature`, `MovieDetailFeature`. PascalCase suffix style for consistency with the other packages.
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

`Domain`, `TMDBClient`, `Persistence`, `DesignSystem`, one `*Feature` per screen (e.g. `SearchFeature`), App target on top. Boundaries enforced at *build time* by package separation, not just convention. Cost: a few minutes per new package. Benefit: the rule "features can't import TMDB" is physically impossible to violate.

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
- When adding a new feature package, copy the structure of an existing one (`SearchFeature`) — don't invent a new layout.
- When adding a dependency, justify it in the PR description.
- Tests are not optional; new behavior ships with tests in the same PR.
- If you find yourself wanting to bypass a layer (e.g. importing `TMDBClient` from a feature), stop and surface it — it's almost always a smell.




# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Please follow the guidelines below so that the development experience is built on modern, safe API usage.


## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.


## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.


## Swift instructions

- `@Observable` classes must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless they are unavoidable, or if they exist in legacy/integration contexts when changing architecture would be complicated.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`. Always use the modern `FormatStyle` API instead. For example, to format a date, use `myDate.formatted(date: .abbreviated, time: .shortened)`. To parse a date from a string, use `Date(inputString, strategy: .iso8601)`. For numbers, use `myNumber.formatted(.number)` or custom format styles.

## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Use the newest ScrollView APIs for item scrolling and positioning (e.g. `ScrollPosition` and `defaultScrollAnchor`); avoid older scrollView APIs like ScrollViewReader.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.


## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.


## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols such as  `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.


## PR instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.


## Xcode MCP

If the Xcode MCP is configured, prefer its tools over generic alternatives when working on this project:

- `DocumentationSearch` — verify API availability and correct usage before writing code
- `BuildProject` — build the project after making changes to confirm compilation succeeds
- `GetBuildLog` — inspect build errors and warnings
- `RenderPreview` — visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` — check for issues visible in the Xcode Issue Navigator
- `ExecuteSnippet` — test a code snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, `XcodeUpdate` — prefer these over generic file tools when working with Xcode project files
