//
//  CachingMovieRepository.swift
//  TMDBClient
//
//  Decorator that adds session-scoped caching in front of any
//  `MovieRepository`. The composition root wraps the live TMDB repository in
//  it; features never know it exists.
//
//  What's cached, and for how long:
//
//  | Call                        | Key                         | Lifetime   |
//  |-----------------------------|-----------------------------|------------|
//  | `searchMovies`              | query + page + language     | session    |
//  | `movie(id:)`                | movie + language            | session    |
//  | `availability(ies)(for:in:)`| movie + region              | 30 minutes |
//  | `allProviders(in:)`         | not cached here — `ProviderCatalog` holds it |
//
//  Search results and movie details don't meaningfully change within a
//  session. Streaming availability does (titles join and leave services), so
//  it expires. Language is part of the key wherever TMDB localizes the
//  response, so switching language never serves stale titles or overviews.
//
//  Skipping this decorator entirely (see `AppConfig.isResponseCachingEnabled`)
//  puts every request back on the wire for Proxyman.
//

import Domain

public struct CachingMovieRepository: MovieRepository {

    private struct SearchKey: Hashable, Sendable {
        let query: String
        let page: Int
        let language: String
    }

    private struct MovieKey: Hashable, Sendable {
        let id: MovieID
        let language: String
    }

    private struct AvailabilityKey: Hashable, Sendable {
        let id: MovieID
        let region: Region
    }

    public static let defaultAvailabilityTimeToLive: Duration = .seconds(30 * 60)

    private let upstream: MovieRepository
    private let currentLanguage: @Sendable () -> String
    private let searchCache: MemoryCache<SearchKey, SearchPage>
    private let movieCache: MemoryCache<MovieKey, Movie>
    private let availabilityCache: MemoryCache<AvailabilityKey, AvailabilityBundle>

    /// - Parameters:
    ///   - upstream: The repository that actually fetches data.
    ///   - currentLanguage: The language the upstream is currently requesting
    ///     in, read on every call so a runtime language change starts a fresh
    ///     set of entries.
    ///   - availabilityTimeToLive: How long streaming availability stays valid.
    public init(
        upstream: MovieRepository,
        currentLanguage: @escaping @Sendable () -> String,
        availabilityTimeToLive: Duration = defaultAvailabilityTimeToLive
    ) {
        self.upstream = upstream
        self.currentLanguage = currentLanguage
        self.searchCache = MemoryCache()
        self.movieCache = MemoryCache()
        self.availabilityCache = MemoryCache(timeToLive: availabilityTimeToLive)
    }

    public func searchMovies(query: String, page: Int) async throws -> SearchPage {
        // TMDB search is case-insensitive, so "inception" and "Inception"
        // share an entry.
        let key = SearchKey(query: query.lowercased(), page: page, language: currentLanguage())
        return try await searchCache.value(for: key) { [upstream] in
            try await upstream.searchMovies(query: query, page: page)
        }
    }

    public func movie(id: MovieID) async throws -> Movie {
        let key = MovieKey(id: id, language: currentLanguage())
        return try await movieCache.value(for: key) { [upstream] in
            try await upstream.movie(id: id)
        }
    }

    /// Served from the same entry as `availabilities(for:in:)`: TMDB returns
    /// every region's providers in one response, so fetching the bundle costs
    /// nothing extra, and a movie seen in search results opens on Details
    /// without another request.
    public func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try await availabilities(for: id, in: region).regional
    }

    public func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        let key = AvailabilityKey(id: id, region: region)
        return try await availabilityCache.value(for: key) { [upstream] in
            try await upstream.availabilities(for: id, in: region)
        }
    }

    public func allProviders(in region: Region?) async throws -> [WatchProvider] {
        try await upstream.allProviders(in: region)
    }
}
