//  Domain.swift
//  StreamFinder
//
//  Domain layer — pure Swift, no Foundation networking, no UIKit/SwiftUI.
//
//  In a real project this would live in its own Swift Package called `Domain`
//  with NO dependency on TMDB, networking, or persistence. The whole point of
//  this layer is: it's the language your app speaks. Everything else (TMDB,
//  SwiftData, the UI) translates to/from these types.
//
//  Read this top-to-bottom before touching anything else: every other module
//  is an adapter to or consumer of what's in here.

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

public struct Region: Hashable, Sendable {
    /// ISO 3166-1 alpha-2 (e.g. "ES", "US", "GB").
    public let code: String

    public init(code: String) { self.code = code.uppercased() }

    public static let unitedStates  = Region(code: "US")
    public static let spain         = Region(code: "ES")
    public static let unitedKingdom = Region(code: "GB")
    public static let france        = Region(code: "FR")
    public static let germany       = Region(code: "DE")
}

// MARK: - Movie

public struct Movie: Equatable, Identifiable, Sendable {
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

    public init(
        id: MovieID,
        title: String,
        originalTitle: String,
        overview: String,
        releaseDate: Date?,
        posterPath: ImagePath?,
        backdropPath: ImagePath?,
        voteAverage: Double,
        runtime: Duration?
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
    }
}

// MARK: - Watch Providers

public struct WatchProvider: Equatable, Hashable, Sendable {
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
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability
}
