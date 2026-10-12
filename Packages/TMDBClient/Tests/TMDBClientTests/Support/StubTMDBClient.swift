import Foundation
import Domain
@testable import TMDBClient

/// Simple in-memory TMDBClient. Each method returns whatever the test puts
/// into its `result` property; if untouched, the methods throw to flush out
/// accidental unexpected calls. Arguments are recorded for assertions.
final class StubTMDBClient: TMDBClient, @unchecked Sendable {
    var searchResult: Result<TMDBSearchResponse, Error> = .failure(MovieError.unknown)
    var movieDetailsResult: Result<TMDBMovieDetailDTO, Error> = .failure(MovieError.unknown)
    var watchProvidersResult: Result<TMDBWatchProvidersResponse, Error> = .failure(MovieError.unknown)
    var providerListResult: Result<TMDBProviderListResponse, Error> = .failure(MovieError.unknown)

    var searchLastQuery: String?
    var searchLastPage: Int?
    var movieDetailsLastID: Int?
    var watchProvidersLastMovieID: Int?
    var providerListCallCount = 0
    var providerListLastWatchRegion: String?

    func searchMovies(query: String, page: Int) async throws -> TMDBSearchResponse {
        searchLastQuery = query
        searchLastPage = page
        return try searchResult.get()
    }
    func movieDetails(id: Int) async throws -> TMDBMovieDetailDTO {
        movieDetailsLastID = id
        return try movieDetailsResult.get()
    }
    func watchProviders(movieID: Int) async throws -> TMDBWatchProvidersResponse {
        watchProvidersLastMovieID = movieID
        return try watchProvidersResult.get()
    }
    func providerList(watchRegion: String?) async throws -> TMDBProviderListResponse {
        providerListCallCount += 1
        providerListLastWatchRegion = watchRegion
        return try providerListResult.get()
    }
}
