import Foundation
import Domain
import Preferences

/// Scriptable repository that counts the calls it receives. Availability
/// answers with `bundles[id]`, or nothing anywhere when it has none.
actor FakeMovieRepository: MovieRepository {
    private let searchResults: [Movie]
    private var searchError: MovieError?
    /// Movies whose next availability request fails, once.
    private var failAvailabilityOnce: Set<MovieID>
    private let bundles: [MovieID: AvailabilityBundle]
    private let trending: Result<[Movie], MovieError>
    private let providers: [WatchProvider]

    private(set) var searchCalls = 0
    private(set) var availabilityCalls: [MovieID: Int] = [:]

    init(
        results: [Movie] = [],
        searchError: MovieError? = nil,
        failAvailabilityOnce: Set<MovieID> = [],
        bundles: [MovieID: AvailabilityBundle] = [:],
        trending: Result<[Movie], MovieError> = .success([]),
        providers: [WatchProvider] = []
    ) {
        self.searchResults = results
        self.searchError = searchError
        self.failAvailabilityOnce = failAvailabilityOnce
        self.bundles = bundles
        self.trending = trending
        self.providers = providers
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

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        availabilityCalls[id, default: 0] += 1
        if failAvailabilityOnce.remove(id) != nil {
            throw MovieError.timeout
        }
        return bundles[id] ?? .fixture(id, region: region)
    }

    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    func trendingMovies() async throws -> [Movie] { try trending.get() }
    /// The view model fetches the whole bundle instead.
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.unknown }
    /// The same list worldwide and in every region.
    func allProviders(in region: Region?) async throws -> [WatchProvider] { providers }
}

struct NullImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}

/// Preferences on their own defaults suite, so tests don't share state.
@MainActor
func makePrefs(subscribedTo providers: [WatchProvider] = []) -> Preferences {
    let suite = "SearchFeatureTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let prefs = Preferences(defaults: defaults)
    prefs.subscribedProviderIDs = Set(providers.map(\.id))
    return prefs
}

extension Movie {
    static func fixture(_ id: Int, releaseDate: Date? = nil) -> Movie {
        Movie(
            id: MovieID(id),
            title: "Movie \(id)",
            originalTitle: "Movie \(id)",
            overview: "",
            releaseDate: releaseDate,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            runtime: nil
        )
    }
}

extension AvailabilityBundle {
    /// Availability of `id` seen from `region`: `subscription` and `free`
    /// there, and `global` for every region's subscriptions.
    static func fixture(
        _ id: MovieID,
        region: Region = .spain,
        subscription: [WatchProvider] = [],
        free: [WatchProvider] = [],
        global: [ProviderRegionalAvailability] = []
    ) -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: subscription, rent: [], buy: [], free: free, externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: global)
        )
    }
}

extension WatchProvider {
    static let netflix = fixture(8, "Netflix")
    static let primeVideo = fixture(119, "Prime Video")
    static let disneyPlus = fixture(337, "Disney Plus")
    static let filmin = fixture(63, "Filmin")
    static let rtvePlay = fixture(541, "RTVE Play")

    static func fixture(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
    }
}
