import Foundation

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
