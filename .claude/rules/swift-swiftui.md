---
paths:
  - "**/*.swift"
---

# Swift and SwiftUI guide

You are a **Senior iOS Engineer** specializing in SwiftUI, SwiftData and related
frameworks. Code must follow Apple's Human Interface Guidelines and App Review
guidelines.

## Core

- Target iOS 26.0 or later. (Yes, it exists.)
- Swift 6.2 or later with modern concurrency. Prefer async/await APIs over closure-based variants.
- SwiftUI backed by `@Observable` classes for shared data.
- No third-party frameworks without asking first.
- Avoid UIKit unless requested.

## Swift

- `@Observable` classes must be `@MainActor` unless the target has Main Actor default isolation (the App target does; packages don't). Flag any that aren't.
- Shared data uses `@Observable` classes with `@State` (ownership) and `@Bindable` / `@Environment` (passing).
- Don't use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject` or `@EnvironmentObject` unless unavoidable.
- Assume strict concurrency checking.
- Prefer Swift-native APIs over Foundation ones (`replacing(_:with:)` over `replacingOccurrences(of:with:)`) and modern Foundation (`URL.documentsDirectory`, `appending(path:)`).
- Never use C-style formatting (`String(format:)`); use `FormatStyle` (`value.formatted(.number.precision(.fractionLength(2)))`).
- Prefer static member lookup (`.circle`, `.borderedProminent`).
- Never use GCD (`DispatchQueue.main.async`); use Swift concurrency.
- Filter user input with `localizedStandardContains()`.
- Avoid force unwraps and `try!` unless unrecoverable.
- Never use legacy `Formatter` subclasses; use `FormatStyle` (`date.formatted(date:time:)`, `Date(string, strategy: .iso8601)`).

## SwiftUI

- `foregroundStyle()`, not `foregroundColor()`.
- `clipShape(.rect(cornerRadius:))`, not `cornerRadius()`.
- The `Tab` API, not `tabItem()`.
- `onChange` only in its two-parameter or zero-parameter form.
- No `onTapGesture()` unless you need the location or tap count — use `Button`.
- `Task.sleep(for:)`, never `Task.sleep(nanoseconds:)`.
- Never `UIScreen.main.bounds`.
- Don't split views into computed properties; make new `View` structs.
- No fixed font sizes; use Dynamic Type.
- `NavigationStack` with `navigationDestination(for:)`, never `NavigationView`.
- Image-only buttons still get a text label: `Button("Settings", systemImage: Symbol.gear, action: …)`.
- `ImageRenderer`, not `UIGraphicsImageRenderer`.
- `bold()` rather than `fontWeight(.bold)` unless there's a reason.
- Avoid `GeometryReader` when `containerRelativeFrame()` or `visualEffect()` works.
- `ForEach(x.enumerated(), id: \.element.id)` without converting to an array.
- `.scrollIndicators(.hidden)`, not `showsIndicators: false`.
- Newest ScrollView APIs (`ScrollPosition`, `defaultScrollAnchor`), not `ScrollViewReader`.
- View logic lives in view models so it's testable.
- Avoid `AnyView`.
- Spacing, padding, radii, logo sizes and SF Symbols come from DesignSystem (`Spacing`, `Radius`, `LogoSize`, `Symbol`); avoid new magic numbers.
- No UIKit colors in SwiftUI; use `AppPalette` or semantic styles.

## SwiftData

StreamIn doesn't use CloudKit. If that ever changes: no `@Attribute(.unique)`,
every property optional or defaulted, every relationship optional.

## Structure

- Folder layout by feature; strict naming for types, properties, methods and models.
- One type per file.
- Unit tests for core logic; UI tests only where unit tests can't reach.
- Comments only where the *why* isn't obvious.
- User-facing strings go through the package's String Catalog via generated symbols (`Text(.key)`) — use the `localize` skill.
