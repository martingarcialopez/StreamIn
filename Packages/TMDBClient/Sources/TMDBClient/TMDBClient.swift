//  TMDBClient.swift
//  StreamIn
//
//  Data layer — knows about HTTP, JSON, TMDB's API shape, and how to translate
//  those things into the Domain layer's vocabulary. Nothing upstream of this
//  module sees a `TMDBMovieDTO` or constructs a URL.

import Foundation
import OSLog
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

// MARK: - Live Implementation

public final class LiveTMDBClient: TMDBClient {
    private let config: TMDBConfig
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(config: TMDBConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        // No keyDecodingStrategy: TMDB casing isn't perfectly snake_case across
        // endpoints, so we keep CodingKeys explicit per-DTO.
        self.decoder = JSONDecoder()
    }

    public func searchMovies(query: String, page: Int) async throws -> TMDBSearchResponse {
        try await get(
            path: "/search/movie",
            query: [
                "query": query,
                "page": String(page),
                "include_adult": "false",
                "language": config.language
            ]
        )
    }

    public func movieDetails(id: Int) async throws -> TMDBMovieDetailDTO {
        try await get(
            path: "/movie/\(id)",
            query: [
                "language": config.language,
                // Bundles the credits endpoint into the same response so we
                // get cast & crew (incl. director) without a second round trip.
                "append_to_response": "credits"
            ]
        )
    }

    public func watchProviders(movieID: Int) async throws -> TMDBWatchProvidersResponse {
        try await get(path: "/movie/\(movieID)/watch/providers", query: [:])
    }

    // MARK: - HTTP

    private func get<T: Decodable>(path: String, query: [String: String]) async throws -> T {
        let endpoint = config.baseURL.appending(path: path)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw MovieError.unknown
        }
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.append(URLQueryItem(name: "api_key", value: config.apiKey))
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
