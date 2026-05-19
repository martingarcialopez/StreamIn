//  Domain.swift
//  StreamIn
//
//  Domain layer — pure Swift, no Foundation networking, no UIKit/SwiftUI.
//  The language your app speaks; everything else (TMDB, SwiftData, the UI)
//  translates to/from these types.

import Foundation

// MARK: - Identifiers
//
// Decision: typed IDs over raw `Int` / `String`.
// Cost: a handful of trivial wrappers.
// Benefit: the compiler stops you mixing a MovieID with a ProviderID, and
// function signatures read like documentation.

public struct MovieID: Hashable, Sendable {
    public let rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }
}

public struct ProviderID: Hashable, Sendable {
    public let rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }
}

public struct PersonID: Hashable, Sendable {
    public let rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }
}

/// A relative path returned by TMDB (e.g. "/abc.jpg"). Kept opaque here;
/// the UI layer composes the absolute URL with the configured CDN base + size,
/// because *that* is a presentation concern (different sizes for thumb vs hero).
public struct ImagePath: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Region
//
// Watch providers are region-specific. Modeling region as a value type
// (rather than passing String "ES" around) makes it explicit in every signature
// and easy to extend later (currency, language preferences, etc.).

public struct Region: Identifiable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2 (e.g. "ES", "US", "GB").
    public let code: String

    public var id: String { code }

    public init(code: String) { self.code = code.uppercased() }

    public static let unitedStates  = Region(code: "US")
    public static let spain         = Region(code: "ES")
    public static let unitedKingdom = Region(code: "GB")
    public static let france        = Region(code: "FR")
    public static let germany       = Region(code: "DE")
    public static let denmark       = Region(code: "DK")

    /// Static catalog of regions the app exposes in its settings picker. Add
    /// to this list as we localize for new markets; each entry needs a TMDB
    /// presence (every entry here has one, but worth checking when extending).
    public static let allKnown: [Region] = [
        .unitedStates, .spain, .unitedKingdom, .france, .germany, .denmark
    ]

    /// Human-readable name in the user's *display* language. So a Spanish-
    /// locale user sees "Estados Unidos"; an English-locale user sees
    /// "United States". Falls back to the raw ISO code if the locale doesn't
    /// know the country (very rare).
    public var displayName: String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    /// Unicode flag emoji built from regional indicator symbols. The base
    /// offset `127397` is `0x1F1E6 - "A"` — adding each ASCII letter's
    /// codepoint to that base produces the regional indicator letter; two
    /// regional indicator letters together form the country flag.
    ///
    /// Falls back to the raw ISO code if the codepoint conversion fails
    /// (shouldn't happen for valid alpha-2 codes). Note that a few flags
    /// don't render in iOS (Taiwan, England, etc.) — in those cases the
    /// emoji string contains the regional indicator pair but the system
    /// glyph is blank.
    public var flag: String {
        let base: UInt32 = 127397
        var result = ""
        for scalar in code.uppercased().unicodeScalars {
            guard let new = UnicodeScalar(base + scalar.value) else { continue }
            result.unicodeScalars.append(new)
        }
        return result.isEmpty ? code : result
    }
}

// MARK: - Movie

public struct Movie: Equatable, Hashable, Identifiable, Sendable {
    public let id: MovieID
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let releaseDate: Date?
    public let posterPath: ImagePath?
    public let backdropPath: ImagePath?
    public let voteAverage: Double
    /// Nil from search results, populated by the detail fetch.
    public let runtime: Duration?
    /// Empty from search results, populated by the detail fetch.
    /// Most movies have one director; some have two or more (Coen brothers,
    /// Wachowskis, etc.) — hence a list rather than a single optional.
    public let directors: [Person]

    public init(
        id: MovieID,
        title: String,
        originalTitle: String,
        overview: String,
        releaseDate: Date?,
        posterPath: ImagePath?,
        backdropPath: ImagePath?,
        voteAverage: Double,
        runtime: Duration?,
        directors: [Person] = []
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.runtime = runtime
        self.directors = directors
    }
}

// MARK: - Person

public struct Person: Equatable, Hashable, Identifiable, Sendable {
    public let id: PersonID
    public let name: String
    public let profilePath: ImagePath?

    public init(id: PersonID, name: String, profilePath: ImagePath?) {
        self.id = id
        self.name = name
        self.profilePath = profilePath
    }
}

// MARK: - Watch Providers

public struct WatchProvider: Equatable, Hashable, Identifiable, Sendable {
    public let id: ProviderID
    public let name: String
    public let logoPath: ImagePath?
    /// TMDB-defined display ordering hint; lower = higher priority.
    public let priority: Int

    public init(id: ProviderID, name: String, logoPath: ImagePath?, priority: Int) {
        self.id = id
        self.name = name
        self.logoPath = logoPath
        self.priority = priority
    }
}

/// Availability of a single movie in a single region.
///
/// Notice the explicit empty arrays for missing categories — easier to render
/// than nested optionals, and makes "no providers anywhere" trivial to check.
public struct WatchAvailability: Equatable, Sendable {
    public let movieID: MovieID
    public let region: Region
    public let subscription: [WatchProvider]   // TMDB calls this "flatrate"
    public let rent: [WatchProvider]
    public let buy: [WatchProvider]
    public let free: [WatchProvider]
    /// JustWatch deep link (TMDB-provided), used as a fallback "open in browser" action.
    public let externalLink: URL?

    public var isEmpty: Bool {
        subscription.isEmpty && rent.isEmpty && buy.isEmpty && free.isEmpty
    }

    public init(
        movieID: MovieID,
        region: Region,
        subscription: [WatchProvider],
        rent: [WatchProvider],
        buy: [WatchProvider],
        free: [WatchProvider],
        externalLink: URL?
    ) {
        self.movieID = movieID
        self.region = region
        self.subscription = subscription
        self.rent = rent
        self.buy = buy
        self.free = free
        self.externalLink = externalLink
    }
}

/// One provider's availability across regions, for a single movie. Subscription-
/// only for v1 (rent/buy/free can be added as sibling fields later).
///
/// Used by the "Watch with your subscriptions" feature: given a film, list the
/// countries where each of the user's subscribed providers carries it.
public struct ProviderRegionalAvailability: Equatable, Hashable, Sendable {
    public let provider: WatchProvider
    /// Regions where `provider` offers this movie via subscription (TMDB's "flatrate").
    /// Sorted by localized display name at construction.
    public let regions: [Region]

    public init(provider: WatchProvider, regions: [Region]) {
        self.provider = provider
        self.regions = regions
    }
}

/// The whole region matrix for one film, distilled to subscription-only.
///
/// TMDB returns availability for every region in a single call — this is the
/// Domain-side shape of that data. Callers filter `subscription` by the user's
/// chosen providers to render the multi-region availability view.
public struct GlobalWatchAvailability: Equatable, Sendable {
    public let movieID: MovieID
    /// One entry per provider that appears in at least one region's flatrate.
    /// Sorted by TMDB display priority (lower = more prominent).
    public let subscription: [ProviderRegionalAvailability]

    public var isEmpty: Bool { subscription.isEmpty }

    public init(movieID: MovieID, subscription: [ProviderRegionalAvailability]) {
        self.movieID = movieID
        self.subscription = subscription
    }
}

/// Both region-scoped and cross-region availability for one film, derived from
/// a single TMDB request.
///
/// The reason this exists: TMDB's `/movie/{id}/watch/providers` returns the
/// full per-region matrix in one response. If callers fan-out separate
/// repository methods for "the regional view" and "the global view," they
/// end up making two identical HTTP calls. `AvailabilityBundle` collapses
/// that into one fetch and exposes both shapes.
public struct AvailabilityBundle: Equatable, Sendable {
    public let regional: WatchAvailability
    public let global: GlobalWatchAvailability

    public init(regional: WatchAvailability, global: GlobalWatchAvailability) {
        self.regional = regional
        self.global = global
    }
}

// MARK: - Search

public struct SearchPage: Equatable, Sendable {
    public let query: String
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
    public let results: [Movie]

    public var hasMore: Bool { page < totalPages }

    public init(query: String, page: Int, totalPages: Int, totalResults: Int, results: [Movie]) {
        self.query = query
        self.page = page
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.results = results
    }
}

// MARK: - Errors
//
// Decision: a typed domain error, NOT just `Error`.
//
// Each case is a state the UI must be able to render, named from the *user's*
// perspective, not the transport's. Network and decoding errors are mapped INTO
// this enum at the data-layer boundary — they never leak upward. The benefit:
// your view's error switch can be exhaustive on the enum, and you can't forget
// a case at compile time.

public enum MovieError: Error, Equatable, Sendable {
    case offline
    case timeout
    case rateLimited
    case unauthorized        // misconfigured/expired API key
    case notFound
    case server              // 5xx
    case decoding            // schema drift; surface to user as "something went wrong"
    case cancelled           // task cancellation; UI usually ignores this
    case unknown
}

public extension MovieError {
    /// Human-readable, end-user-facing description for each case. Routed
    /// through `String(localized:)` so the strings are extractable into the
    /// app's catalog when localization lands.
    var userMessage: String {
        switch self {
        case .offline:       String(localized: .errorOffline)
        case .timeout:       String(localized: .errorTimeout)
        case .rateLimited:   String(localized: .errorRateLimited)
        case .unauthorized:  String(localized: .errorUnauthorized)
        case .notFound:      String(localized: .errorNotFound)
        case .server:        String(localized: .errorServer)
        case .decoding:      String(localized: .errorDecoding)
        case .cancelled:     String(localized: .errorCancelled)
        case .unknown:       String(localized: .errorUnknown)
        }
    }
}

// MARK: - Repository (the boundary)
//
// THIS is the seam. Features depend on this protocol, never on TMDBClient
// directly. Tests substitute a fake. The implementation lives in the data layer
// (see TMDB.swift). Keep it small — every method here is something the UI
// genuinely needs. Don't preemptively expose endpoints "in case."

public protocol MovieRepository: Sendable {
    /// Full-text search, paginated.
    func searchMovies(query: String, page: Int) async throws -> SearchPage

    /// Full movie detail (richer than what `searchMovies` returns).
    func movie(id: MovieID) async throws -> Movie

    /// Streaming / rent / buy availability for a given region.
    /// Used by the search list, where only the regional view is needed.
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability

    /// Region-scoped *and* cross-region subscription availability from a single
    /// TMDB request. Used by the Details screen so we don't issue two identical
    /// `/movie/{id}/watch/providers` calls in parallel.
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle

    /// The list of watch providers TMDB knows about.
    ///
    /// - `region == nil`: every provider globally (used for VPN users who
    ///   subscribe to services outside their home region).
    /// - `region == .some(r)`: only providers TMDB lists as active in `r`
    ///   (the common case — shorter list, no search UI needed).
    ///
    /// Sorted by TMDB display priority.
    func allProviders(in region: Region?) async throws -> [WatchProvider]
}

// MARK: - Region helpers

public extension Region {
    /// Best-effort region from the device locale, *constrained to the catalog*
    /// of regions the app exposes. If the device locale isn't one we ship with
    /// (e.g. user is in Mexico, catalog only has Spain), falls back to a
    /// reasonable default rather than returning a region the picker can't show.
    static var currentLocale: Region {
        let code = Locale.current.region?.identifier ?? "ES"
        return allKnown.first(where: { $0.code == code }) ?? .spain
    }
}

// MARK: - Language
//
// Mirror of Region but for the `language=` parameter TMDB accepts on every
// localized call (search, movie detail). Driven from settings, defaults to the
// device locale (constrained to the catalog).

public struct Language: Identifiable, Hashable, Sendable {
    /// BCP-47 identifier, e.g. "en-US", "es-ES", "fr-FR".
    public let code: String

    public var id: String { code }

    public init(code: String) { self.code = code }

    public static let englishUS    = Language(code: "en-US")
    public static let spanishES    = Language(code: "es-ES")
    public static let frenchFR     = Language(code: "fr-FR")
    public static let germanDE     = Language(code: "de-DE")
    public static let italianIT    = Language(code: "it-IT")
    public static let portugueseBR = Language(code: "pt-BR")

    /// Catalog of languages exposed in the settings picker.
    public static let allKnown: [Language] = [
        .englishUS, .spanishES, .frenchFR, .germanDE, .italianIT, .portugueseBR
    ]

    /// Self-localized name — each language's name *in itself*: "English",
    /// "Español", "Français". This is the iOS / App Store convention for
    /// language pickers; users find their language even if the app's current
    /// display language is different.
    public var displayName: String {
        Locale(identifier: code).localizedString(forIdentifier: code) ?? code
    }

    /// Best-effort language from the device locale, constrained to the catalog.
    /// Tries an exact BCP-47 match, then a language-code prefix match, then
    /// falls back to Spanish (Spain) — matching the project's defaults.
    public static var currentLocale: Language {
        let lang = Locale.current.language.languageCode?.identifier ?? "es"
        let region = Locale.current.region?.identifier ?? "ES"
        let bcp47 = "\(lang)-\(region)"
        return allKnown.first(where: { $0.code == bcp47 })
            ?? allKnown.first(where: { $0.code.hasPrefix(lang + "-") })
            ?? .spanishES
    }
}

// MARK: - Image URLs
//
// Posters and provider logos live on a CDN whose URL format is transport-specific
// (TMDB has its own scheme; another data source would have a different one).
// Domain only declares the abstraction. The actual URL builder lives in the
// data layer and is injected into anything that needs it.

public enum ImageSize: Sendable, Hashable {
    case poster
    case backdrop
    case providerLogo
}

public protocol ImageURLBuilder: Sendable {
    func url(for path: ImagePath, size: ImageSize) -> URL?
}
