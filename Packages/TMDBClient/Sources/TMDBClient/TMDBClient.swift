//  TMDBClient.swift
//  StreamIn
//
//  Data layer — knows about HTTP, JSON, TMDB's API shape, and how to translate
//  those things into the Domain layer's vocabulary. Nothing upstream of this
//  module sees a `TMDBMovieDTO` or constructs a URL.

import Foundation
import OSLog
import os
import Domain

private let logger = Logger(subsystem: "StreamIn.TMDBClient", category: "network")

// MARK: - Configuration

public struct TMDBConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String
    /// Default language sent as `language=` (e.g. "en-US", "es-ES").
    public let language: String

    public init(
        baseURL: URL = URL(string: "https://api.themoviedb.org/3")!,
        apiKey: String,
        language: String = "en-US"
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.language = language
    }
}

// MARK: - Client Protocol
//
// Why a protocol instead of a concrete struct?
//   - Tests want to inject a fake.
//   - We may later wrap it in a logging or caching decorator.
//
// Keep the surface small: one method per logical endpoint, returning DTOs.

public protocol TMDBClient: Sendable {
    func searchMovies(query: String, page: Int) async throws -> TMDBSearchResponse
    func movieDetails(id: Int) async throws -> TMDBMovieDetailDTO
    func watchProviders(movieID: Int) async throws -> TMDBWatchProvidersResponse
    /// `/watch/providers/movie?watch_region=XX` if `watchRegion != nil`,
    /// `/watch/providers/movie` otherwise (every provider globally).
    func providerList(watchRegion: String?) async throws -> TMDBProviderListResponse
}

// MARK: - DTOs (transport types)
//
// DTOs mirror TMDB's JSON exactly. They are NOT used outside this module.
// This is what protects the rest of the app from TMDB's quirks (dates as
// strings, paths starting with "/", optional fields that are sometimes empty
// strings instead of null).

public struct TMDBSearchResponse: Decodable, Sendable {
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
    public let results: [TMDBMovieDTO]

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct TMDBMovieDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let releaseDate: String?       // "YYYY-MM-DD" or sometimes ""
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
}

public struct TMDBMovieDetailDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let releaseDate: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double
    public let runtime: Int?              // minutes
    /// Populated when the request asked for `append_to_response=credits`.
    public let credits: TMDBCreditsDTO?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, credits
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
}

public struct TMDBCreditsDTO: Decodable, Sendable {
    public let cast: [TMDBCastMemberDTO]?
    public let crew: [TMDBCrewMemberDTO]?
}

public struct TMDBCastMemberDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let character: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}

public struct TMDBCrewMemberDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let job: String          // e.g. "Director", "Director of Photography"
    public let department: String   // e.g. "Directing", "Camera"

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}

public struct TMDBWatchProvidersResponse: Decodable, Sendable {
    public let id: Int
    /// Keyed by ISO country code: "US", "ES", ...
    public let results: [String: TMDBWatchProvidersRegionDTO]
}

public struct TMDBWatchProvidersRegionDTO: Decodable, Sendable {
    public let link: String?
    public let flatrate: [TMDBProviderDTO]?
    public let rent: [TMDBProviderDTO]?
    public let buy: [TMDBProviderDTO]?
    public let free: [TMDBProviderDTO]?
}

public struct TMDBProviderDTO: Decodable, Sendable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?
    public let displayPriority: Int

    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }
}

// MARK: - Provider catalog DTOs
//
// `/watch/providers/movie` returns the list of every streaming service TMDB
// knows about (optionally filtered by `watch_region`). The shape includes a
// `display_priorities` dictionary per provider for region-specific ordering;
// we don't need that yet, but it's left here as a TODO marker so we can sort
// per-region without a wire-format change.

public struct TMDBProviderListResponse: Decodable, Sendable {
    public let results: [TMDBProviderListItemDTO]
}

public struct TMDBProviderListItemDTO: Decodable, Sendable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?
    /// Aggregate priority TMDB uses when no region filter is applied.
    public let displayPriority: Int

    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }
}

// MARK: - Live Implementation

public final class LiveTMDBClient: TMDBClient {
    private let baseURL: URL
    private let apiKey: String
    /// Language is read fresh on every request, and `updateLanguage(_:)` is
    /// called from the App's composition root when the user changes their
    /// preference in Settings. This avoids rebuilding the client (and the
    /// repository wrapping it) at runtime, which led to fragile interactions
    /// between SwiftUI's `@State` reset semantics and `.id`-based identity
    /// invalidation. The lock guarantees memory safety; reads/writes are short.
    private let lockedLanguage: OSAllocatedUnfairLock<String>
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(config: TMDBConfig, session: URLSession? = nil) {
        self.baseURL = config.baseURL
        self.apiKey = config.apiKey
        self.lockedLanguage = OSAllocatedUnfairLock(initialState: config.language)
        // Use the caller's session if provided (tests inject a URLProtocol-
        // backed one), otherwise build a non-caching default. Caching lives
        // one level up, in `CachingMovieRepository`, where keys and lifetimes
        // are explicit and the whole layer can be switched off for Proxyman.
        // A URLCache here would silently serve responses from disk instead.
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
        // No keyDecodingStrategy: TMDB casing isn't perfectly snake_case across
        // endpoints, so we keep CodingKeys explicit per-DTO.
        self.decoder = JSONDecoder()
    }

    /// Update the language sent on subsequent requests. Safe to call from
    /// any actor.
    public func updateLanguage(_ language: String) {
        lockedLanguage.withLock { $0 = language }
    }

    /// The language sent with localized requests right now.
    public var language: String {
        lockedLanguage.withLock { $0 }
    }

    public func searchMovies(query: String, page: Int) async throws -> TMDBSearchResponse {
        try await get(
            path: "/search/movie",
            query: [
                "query": query,
                "page": String(page),
                "include_adult": "false",
                "language": language
            ]
        )
    }

    public func movieDetails(id: Int) async throws -> TMDBMovieDetailDTO {
        try await get(
            path: "/movie/\(id)",
            query: [
                "language": language,
                // Bundles the credits endpoint into the same response so we
                // get cast & crew (incl. director) without a second round trip.
                "append_to_response": "credits"
            ]
        )
    }

    public func watchProviders(movieID: Int) async throws -> TMDBWatchProvidersResponse {
        try await get(path: "/movie/\(movieID)/watch/providers", query: [:])
    }

    public func providerList(watchRegion: String?) async throws -> TMDBProviderListResponse {
        var query: [String: String] = ["language": language]
        if let watchRegion {
            query["watch_region"] = watchRegion
        }
        return try await get(path: "/watch/providers/movie", query: query)
    }

    // MARK: - HTTP

    private func get<T: Decodable>(path: String, query: [String: String]) async throws -> T {
        let endpoint = baseURL.appending(path: path)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw MovieError.unknown
        }
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = items

        guard let url = components.url else { throw MovieError.unknown }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MovieError.unknown }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                // Surface the underlying decoding cause so schema drift is
                // debuggable in the field — the user-facing enum still hides it.
                logger.error("Decoding \(T.self) failed: \(String(describing: error), privacy: .public)")
                throw MovieError.decoding
            }
        case 401:    throw MovieError.unauthorized
        case 404:    throw MovieError.notFound
        case 429:    throw MovieError.rateLimited
        case 500...: throw MovieError.server
        default:     throw MovieError.unknown
        }
    }
}

// MARK: - Adapter: TMDBClient -> MovieRepository
//
// This is where TMDB's vocabulary is translated into the Domain's vocabulary.
// Anything Domain code shouldn't have to know about (snake_case, nullable
// fields that are actually empty strings, the magic word "flatrate") dies here.

public struct TMDBMovieRepository: MovieRepository {
    private let client: TMDBClient

    // No caching here: every call reaches the client. Caching is layered on
    // by `CachingMovieRepository` so this adapter stays a pure translation.

    /// TMDB returns release dates as plain `yyyy-MM-dd` strings (no time, no zone).
    /// We parse them in UTC so a date doesn't shift by a day depending on where
    /// the device is. Modern `Date.ISO8601FormatStyle` covers this exactly: the
    /// builder `.year().month().day()` accepts the date-only form, and the
    /// default `timeZone: .gmt` makes the assumed midnight unambiguous.
    private static let releaseDateStrategy = Date.ISO8601FormatStyle(timeZone: .gmt)
        .year().month().day()

    public init(client: TMDBClient) {
        self.client = client
    }

    public func searchMovies(query: String, page: Int) async throws -> SearchPage {
        let response = try await mapErrors {
            try await client.searchMovies(query: query, page: page)
        }
        return SearchPage(
            query: query,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: response.results.map(map(dto:))
        )
    }

    public func movie(id: MovieID) async throws -> Movie {
        let dto = try await mapErrors {
            try await client.movieDetails(id: id.rawValue)
        }
        return Movie(
            id: MovieID(dto.id),
            title: dto.title,
            originalTitle: dto.originalTitle,
            overview: dto.overview,
            releaseDate: parseDate(dto.releaseDate),
            posterPath: dto.posterPath.map(ImagePath.init),
            backdropPath: dto.backdropPath.map(ImagePath.init),
            voteAverage: dto.voteAverage,
            runtime: dto.runtime.map { Duration.seconds($0 * 60) },
            directors: extractDirectors(from: dto.credits)
        )
    }

    public func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        let response = try await mapErrors {
            try await client.watchProviders(movieID: id.rawValue)
        }
        return mapRegional(response: response, id: id, region: region)
    }

    public func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        // One HTTP call. The response contains the full per-region matrix, so
        // we derive both the regional view and the cross-region aggregation
        // from the same payload.
        let response = try await mapErrors {
            try await client.watchProviders(movieID: id.rawValue)
        }
        return AvailabilityBundle(
            regional: mapRegional(response: response, id: id, region: region),
            global: aggregateGlobal(response: response, id: id)
        )
    }

    public func allProviders(in region: Region?) async throws -> [WatchProvider] {
        let response = try await mapErrors {
            try await client.providerList(watchRegion: region?.code)
        }
        // Map to Domain types, then dedupe by canonical id so aliased variants
        // (e.g. Prime Video ids 9 / 119 / 2100) collapse into a single row.
        //
        // When two DTOs reduce to the same canonical id, we prefer the one
        // whose original id IS the canonical — that's almost always the entry
        // with the "main" name (e.g. "Amazon Prime Video" rather than "Amazon
        // Prime Video with Ads"). Priority is taken as the lower of the two.
        var byCanonical: [ProviderID: WatchProvider] = [:]
        for dto in response.results {
            let originalID = ProviderID(dto.providerId)
            let canonicalID = ProviderAliases.canonical(originalID)
            let candidate = WatchProvider(
                id: canonicalID,
                name: dto.providerName,
                logoPath: dto.logoPath.map(ImagePath.init),
                priority: dto.displayPriority
            )
            if let existing = byCanonical[canonicalID] {
                // Tie-breaker: prefer the candidate whose original id was
                // canonical. Detect that by comparing original id and
                // canonical — but `existing` no longer remembers its original
                // id. The heuristic that works in practice: if `candidate`'s
                // original was canonical AND `existing` wasn't generated from
                // the canonical original (we can't fully tell), bias toward
                // it. The simpler rule below is "lower priority wins; ties
                // broken by canonical-originality of this candidate."
                let candidateIsCanonicalOriginal = (originalID == canonicalID)
                if candidate.priority < existing.priority ||
                    (candidate.priority == existing.priority && candidateIsCanonicalOriginal) {
                    byCanonical[canonicalID] = WatchProvider(
                        id: canonicalID,
                        name: candidate.name,
                        logoPath: candidate.logoPath,
                        priority: min(existing.priority, candidate.priority)
                    )
                } else {
                    byCanonical[canonicalID] = WatchProvider(
                        id: canonicalID,
                        name: existing.name,
                        logoPath: existing.logoPath,
                        priority: min(existing.priority, candidate.priority)
                    )
                }
            } else {
                byCanonical[canonicalID] = candidate
            }
        }
        return byCanonical.values.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - Private mapping

    private func map(dto: TMDBMovieDTO) -> Movie {
        Movie(
            id: MovieID(dto.id),
            title: dto.title,
            originalTitle: dto.originalTitle,
            overview: dto.overview,
            releaseDate: parseDate(dto.releaseDate),
            posterPath: dto.posterPath.map(ImagePath.init),
            backdropPath: dto.backdropPath.map(ImagePath.init),
            voteAverage: dto.voteAverage,
            runtime: nil
        )
    }

    private func map(dto: TMDBProviderDTO) -> WatchProvider {
        WatchProvider(
            id: ProviderID(dto.providerId),
            name: dto.providerName,
            logoPath: dto.logoPath.map(ImagePath.init),
            priority: dto.displayPriority
        )
    }

    // MARK: - Watch-providers response mapping
    //
    // Both helpers consume the same raw TMDB response. Pulled out so the single-
    // call `availabilities(...)` and the still-supported `availability(...)`
    // share their logic without duplicating mapping code.

    private func mapRegional(
        response: TMDBWatchProvidersResponse,
        id: MovieID,
        region: Region
    ) -> WatchAvailability {
        let regional = response.results[region.code]
        return WatchAvailability(
            movieID: id,
            region: region,
            subscription: regional?.flatrate?.map(map(dto:)) ?? [],
            rent: regional?.rent?.map(map(dto:)) ?? [],
            buy: regional?.buy?.map(map(dto:)) ?? [],
            free: regional?.free?.map(map(dto:)) ?? [],
            externalLink: regional?.link.flatMap(URL.init(string:))
        )
    }

    /// Walk every region's flatrate list; accumulate per-provider region sets.
    /// Keyed by *canonical* provider id so aliased TMDB variants (Prime Video
    /// ids 9 / 119 / 2100) merge into a single entry whose `regions` covers
    /// every country where the brand appears under any variant.
    ///
    /// When two variants of the same brand appear, we keep the metadata
    /// (name, logo) from whichever DTO had the canonical id originally — the
    /// "Amazon Prime Video" entry beats "Amazon Prime Video with Ads" — and
    /// fall back to the first-seen DTO if no canonical-id DTO ever shows up.
    /// Lowest TMDB priority across regions wins for the per-provider sort key.
    private func aggregateGlobal(
        response: TMDBWatchProvidersResponse,
        id: MovieID
    ) -> GlobalWatchAvailability {
        struct Accumulator {
            var provider: WatchProvider
            /// True once we've seen a DTO whose original id matched the
            /// canonical — locks the metadata so a later variant-only DTO
            /// can't downgrade the name to e.g. "with Ads".
            var hasCanonicalMetadata: Bool
            var regions: Set<Region> = []
            var bestPriority: Int
        }
        var byCanonical: [ProviderID: Accumulator] = [:]

        for (regionCode, regional) in response.results {
            guard let flatrate = regional.flatrate, !flatrate.isEmpty else { continue }
            let region = Region(code: regionCode)
            for dto in flatrate {
                let originalID = ProviderID(dto.providerId)
                let canonicalID = ProviderAliases.canonical(originalID)
                let isCanonicalOriginal = (originalID == canonicalID)
                let provider = WatchProvider(
                    id: canonicalID,
                    name: dto.providerName,
                    logoPath: dto.logoPath.map(ImagePath.init),
                    priority: dto.displayPriority
                )
                if var existing = byCanonical[canonicalID] {
                    existing.regions.insert(region)
                    existing.bestPriority = min(existing.bestPriority, dto.displayPriority)
                    if isCanonicalOriginal && !existing.hasCanonicalMetadata {
                        existing.provider = provider
                        existing.hasCanonicalMetadata = true
                    }
                    byCanonical[canonicalID] = existing
                } else {
                    byCanonical[canonicalID] = Accumulator(
                        provider: provider,
                        hasCanonicalMetadata: isCanonicalOriginal,
                        regions: [region],
                        bestPriority: dto.displayPriority
                    )
                }
            }
        }

        let subscription: [ProviderRegionalAvailability] = byCanonical.values
            .sorted { lhs, rhs in
                if lhs.bestPriority != rhs.bestPriority {
                    return lhs.bestPriority < rhs.bestPriority
                }
                return lhs.provider.name.localizedStandardCompare(rhs.provider.name) == .orderedAscending
            }
            .map { acc in
                let regions = acc.regions.sorted { a, b in
                    a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
                }
                return ProviderRegionalAvailability(provider: acc.provider, regions: regions)
            }

        return GlobalWatchAvailability(movieID: id, subscription: subscription)
    }

    private func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return try? Date(raw, strategy: Self.releaseDateStrategy)
    }

    /// Pulls people whose `job == "Director"` out of the crew. Excludes
    /// related-but-different roles like "Director of Photography" or
    /// "Co-Director" — adjust the predicate here if you want a broader set.
    private func extractDirectors(from credits: TMDBCreditsDTO?) -> [Person] {
        (credits?.crew ?? [])
            .filter { $0.job == "Director" }
            .map { dto in
                Person(
                    id: PersonID(dto.id),
                    name: dto.name,
                    profilePath: dto.profilePath.map(ImagePath.init)
                )
            }
    }

    /// Translates URLError / cancellation / unknown errors into our domain enum
    /// so the repository surfaces only `MovieError`. View models depend on this.
    private func mapErrors<T>(_ block: () async throws -> T) async throws -> T {
        do {
            return try await block()
        } catch is CancellationError {
            throw MovieError.cancelled
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed: throw MovieError.offline
            case .timedOut: throw MovieError.timeout
            case .cancelled: throw MovieError.cancelled
            default: throw MovieError.unknown
            }
        } catch let movieError as MovieError {
            throw movieError
        } catch {
            throw MovieError.unknown
        }
    }
}

// MARK: - Image URL Builder
//
// Concrete `ImageURLBuilder` for TMDB's CDN. Lives in this layer because the
// URL scheme (`https://image.tmdb.org/t/p/<size>/<path>`) is TMDB-specific.
// Features import only the `ImageURLBuilder` protocol from Domain and receive
// this implementation through the composition root.

public struct TMDBImageURLBuilder: ImageURLBuilder {
    private let baseURL: String

    public init(baseURL: String = "https://image.tmdb.org/t/p/") {
        self.baseURL = baseURL
    }

    public func url(for path: ImagePath, size: ImageSize) -> URL? {
        // TMDB image paths arrive with a leading slash, e.g. "/abc.jpg".
        // The size segments are TMDB's standard sizes; see
        // https://developers.themoviedb.org/3/configuration/get-api-configuration
        let sizeSegment: String
        switch size {
        case .poster:        sizeSegment = "w342"
        case .backdrop:      sizeSegment = "w780"
        case .providerLogo:  sizeSegment = "w92"
        }
        return URL(string: "\(baseURL)\(sizeSegment)\(path.rawValue)")
    }
}
