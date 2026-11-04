//
//  FixtureMovieRepository.swift
//  StreamIn
//
//  Canned, offline data for UI tests (`STREAMIN_UI_TEST_FIXTURES=1`): CI has
//  no TMDB key. Two films, seen from Spain: one on Netflix at home, one only
//  on Netflix abroad.
//

#if DEBUG
import Foundation
import Domain

nonisolated struct FixtureMovieRepository: MovieRepository {

    private static let netflix = WatchProvider(id: ProviderID(8), name: "Netflix", logoPath: nil, priority: 1)

    private static let movies = [
        Movie(id: MovieID(1), title: "Inception", originalTitle: "Inception", overview: "A thief who steals secrets through dreams.",
              releaseDate: nil, posterPath: nil, backdropPath: nil, voteAverage: 8.4, runtime: .seconds(148 * 60)),
        Movie(id: MovieID(2), title: "Dune", originalTitle: "Dune", overview: "A noble family on a desert planet.",
              releaseDate: nil, posterPath: nil, backdropPath: nil, voteAverage: 7.8, runtime: .seconds(155 * 60)),
    ]

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        SearchPage(query: query, page: page, totalPages: 1, totalResults: Self.movies.count, results: Self.movies)
    }

    func movie(id: MovieID) async throws -> Movie {
        guard let movie = Self.movies.first(where: { $0.id == id }) else { throw MovieError.notFound }
        return movie
    }

    func trendingMovies() async throws -> [Movie] {
        Self.movies
    }

    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try await availabilities(for: id, in: region).regional
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        let atHome = id == MovieID(1) && region == .spain
        let abroad = ProviderRegionalAvailability(provider: Self.netflix, regions: [.unitedStates, .unitedKingdom])
        return AvailabilityBundle(
            regional: WatchAvailability(movieID: id, region: region, subscription: atHome ? [Self.netflix] : [],
                                        rent: [], buy: [], free: [], externalLink: nil),
            global: GlobalWatchAvailability(movieID: id, subscription: [abroad])
        )
    }

    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        [Self.netflix]
    }

    func watchRegions() async throws -> [Region] {
        [.spain, .unitedKingdom, .unitedStates]
    }
}
#endif
