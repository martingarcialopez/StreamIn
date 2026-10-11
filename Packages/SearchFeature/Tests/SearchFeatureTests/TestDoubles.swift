import Foundation
import Domain

/// Scriptable repository that counts the calls it receives.
actor FakeMovieRepository: MovieRepository {
    private let searchResults: [Movie]
    private var searchError: MovieError?
    /// Movies whose next availability request fails, once.
    private var failAvailabilityOnce: Set<MovieID>

    private(set) var searchCalls = 0
    private(set) var availabilityCalls: [MovieID: Int] = [:]

    init(
        results: [Movie],
        searchError: MovieError? = nil,
        failAvailabilityOnce: Set<MovieID> = []
    ) {
        self.searchResults = results
        self.searchError = searchError
        self.failAvailabilityOnce = failAvailabilityOnce
    }

    func setSearchError(_ error: MovieError?) {
        searchError = error
    }

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        searchCalls += 1
        if let searchError { throw searchError }
        return SearchPage(
            query: query,
            page: page,
            totalPages: 1,
            totalResults: searchResults.count,
            results: searchResults
        )
    }

    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        availabilityCalls[id, default: 0] += 1
        if failAvailabilityOnce.remove(id) != nil {
            throw MovieError.timeout
        }
        return WatchAvailability(
            movieID: id, region: region,
            subscription: [], rent: [], buy: [], free: [], externalLink: nil
        )
    }

    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle { throw MovieError.unknown }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

struct NullImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}

extension Movie {
    static func fixture(_ id: Int) -> Movie {
        Movie(
            id: MovieID(id),
            title: "Movie \(id)",
            originalTitle: "Movie \(id)",
            overview: "",
            releaseDate: nil,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            runtime: nil
        )
    }
}
