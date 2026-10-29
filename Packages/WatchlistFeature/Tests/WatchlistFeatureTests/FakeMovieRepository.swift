import Foundation
import Domain
import Preferences

/// Answers availability with `bundles[id]` (seen from the requested region),
/// or nothing anywhere when it has none, and counts the requests.
actor FakeMovieRepository: MovieRepository {
    /// Movies whose next availability request fails, once.
    private var failAvailabilityOnce: Set<MovieID>
    private var bundles: [MovieID: @Sendable (Region) -> AvailabilityBundle]

    private(set) var availabilityCalls: [MovieID: Int] = [:]

    init(
        failAvailabilityOnce: Set<MovieID> = [],
        bundles: [MovieID: @Sendable (Region) -> AvailabilityBundle] = [:]
    ) {
        self.failAvailabilityOnce = failAvailabilityOnce
        self.bundles = bundles
    }

    /// What `id`'s next availability request answers.
    func set(_ id: MovieID, bundle: @escaping @Sendable (Region) -> AvailabilityBundle) {
        bundles[id] = bundle
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        availabilityCalls[id, default: 0] += 1
        if failAvailabilityOnce.remove(id) != nil {
            throw MovieError.timeout
        }
        return bundles[id]?(region) ?? .fixture(id, region: region)
    }

    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.unknown }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    /// The view model fetches the whole bundle instead.
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.unknown }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

/// Preferences on their own defaults suite, so tests don't share state.
@MainActor
func makePrefs(region: Region = .spain, subscribedTo providers: [WatchProvider] = []) -> Preferences {
    let suite = "WatchlistFeatureTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let prefs = Preferences(defaultRegion: region, defaults: defaults)
    prefs.region = region
    prefs.subscribedProviderIDs = Set(providers.map(\.id))
    return prefs
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
    static let hboMax = fixture(1899, "HBO Max")
    static let filmin = fixture(63, "Filmin")
    static let rtvePlay = fixture(541, "RTVE Play")

    static func fixture(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
    }
}
