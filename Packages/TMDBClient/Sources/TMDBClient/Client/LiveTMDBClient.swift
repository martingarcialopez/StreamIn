import Foundation
import OSLog
import os
import Domain

private let logger = Logger(subsystem: "StreamIn.TMDBClient", category: "network")

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

    public func trendingMovies() async throws -> TMDBSearchResponse {
        try await get(path: "/trending/movie/week", query: ["language": language])
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
