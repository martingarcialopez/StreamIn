//
//  FixtureMovieRepository.swift
//  StreamIn
//
//  Canned, offline data for UI tests (`STREAMIN_UI_TEST_FIXTURES=1`), so the
//  accessibility audit sees every screen filled in on CI, which has no TMDB
//  key. Seen from Spain with Netflix subscribed, the four films give each
//  verdict on Details and each kind of search row.
//

#if DEBUG
import Foundation
import Domain

nonisolated struct FixtureMovieRepository: MovieRepository {

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
        let offer = Self.offers[id] ?? Offer()
        let isHome = region == .spain
        return AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id,
                region: region,
                subscription: isHome ? offer.subscription : [],
                rent: [],
                buy: [],
                free: isHome ? offer.free : [],
                externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: offer.global)
        )
    }

    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        [.netflix, .primeVideo, .disneyPlus, .movistarPlus, .rtvePlay]
    }

    func watchRegions() async throws -> [Region] {
        [.spain, .unitedKingdom, .unitedStates, .france, .germany, Region(code: "JP"), Region(code: "MX")]
    }

    // MARK: - Data

    private struct Offer {
        var subscription: [WatchProvider] = []
        var free: [WatchProvider] = []
        var global: [ProviderRegionalAvailability] = []
    }

    /// Watch now (Netflix at home), on your services abroad, free at home,
    /// and nowhere.
    static let movies: [Movie] = [
        movie(1, "Inception", year: 2010, rating: 8.4, minutes: 148, director: "Christopher Nolan"),
        movie(2, "Dune", year: 2021, rating: 7.8, minutes: 155, director: "Denis Villeneuve"),
        movie(3, "Paddington", year: 2014, rating: 7.2, minutes: 95, director: "Paul King"),
        movie(4, "Amélie", year: 2001, rating: 7.9, minutes: 122, director: "Jean-Pierre Jeunet"),
    ]

    private static let offers: [MovieID: Offer] = [
        MovieID(1): Offer(
            subscription: [.netflix, .movistarPlus],
            global: [ProviderRegionalAvailability(provider: .netflix, regions: [.spain, .unitedStates])]
        ),
        MovieID(2): Offer(
            subscription: [.disneyPlus],
            global: [
                ProviderRegionalAvailability(
                    provider: .netflix,
                    regions: [.unitedStates, .unitedKingdom, Region(code: "JP"), Region(code: "MX")]
                ),
            ]
        ),
        MovieID(3): Offer(free: [.rtvePlay]),
        MovieID(4): Offer(),
    ]

    private static func movie(_ id: Int, _ title: String, year: Int, rating: Double, minutes: Int, director: String) -> Movie {
        Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "\(title) is a fixture film for UI tests: its overview runs to two sentences so the page has body text.",
            releaseDate: DateComponents(calendar: .init(identifier: .gregorian), year: year, month: 6, day: 1).date,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: rating,
            runtime: .seconds(minutes * 60),
            directors: [Person(id: PersonID(id), name: director, profilePath: nil)]
        )
    }
}

private nonisolated extension WatchProvider {
    static let netflix = fixture(8, "Netflix")
    static let primeVideo = fixture(119, "Prime Video")
    static let disneyPlus = fixture(337, "Disney Plus")
    static let movistarPlus = fixture(149, "Movistar Plus+")
    static let rtvePlay = fixture(541, "RTVE Play")

    static func fixture(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: id)
    }
}
#endif
