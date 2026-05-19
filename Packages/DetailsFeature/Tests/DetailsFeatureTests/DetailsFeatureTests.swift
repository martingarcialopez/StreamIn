import Testing
import Foundation
import Domain
import Preferences
@testable import DetailsFeature

// MARK: - Test doubles

/// In-memory repository whose responses are dictated by the test. Throws by
/// default to flush out unexpected calls — only methods exercised in the test
/// suite need useful return values.
final class FakeMovieRepository: MovieRepository, @unchecked Sendable {
    var bundleResult: Result<AvailabilityBundle, Error> = .failure(MovieError.unknown)
    var availabilityResult: Result<WatchAvailability, Error> = .failure(MovieError.unknown)
    var movieResult: Result<Movie, Error> = .failure(MovieError.unknown)

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        throw MovieError.unknown
    }
    func movie(id: MovieID) async throws -> Movie {
        try movieResult.get()
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try availabilityResult.get()
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        try bundleResult.get()
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

struct NoopImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}

@MainActor
private func makePrefs(subscribedTo ids: [Int]) -> Preferences {
    let suite = "DetailsFeatureTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let prefs = Preferences(defaults: defaults)
    prefs.subscribedProviderIDs = Set(ids.map(ProviderID.init))
    return prefs
}

private let sampleMovie = Movie(
    id: MovieID(1),
    title: "Inception",
    originalTitle: "Inception",
    overview: "",
    releaseDate: nil,
    posterPath: nil,
    backdropPath: nil,
    voteAverage: 8.4,
    runtime: nil
)

private func provider(_ id: Int, _ name: String) -> WatchProvider {
    WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
}

// MARK: - subscribedAvailability filtering

@MainActor
@Suite struct SubscribedAvailabilityTests {

    private func bundle(
        movieID: MovieID,
        region: Region,
        subscriptions: [ProviderRegionalAvailability]
    ) -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: movieID, region: region,
                subscription: [], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: movieID, subscription: subscriptions)
        )
    }

    @Test func filtersToUserProviders() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .unitedStates,
                subscriptions: [
                    ProviderRegionalAvailability(provider: provider(8, "Netflix"), regions: [.unitedStates]),
                    ProviderRegionalAvailability(provider: provider(337, "Disney+"), regions: [.unitedKingdom])
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [8])  // Netflix only
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )

        await model.load(region: .unitedStates)
        #expect(model.subscribedAvailability.count == 1)
        #expect(model.subscribedAvailability.first?.provider.id == ProviderID(8))
    }

    @Test func emptyWhenNoMatches() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .unitedStates,
                subscriptions: [
                    ProviderRegionalAvailability(provider: provider(8, "Netflix"), regions: [.unitedStates])
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [337])  // Disney+ only — no overlap
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )

        await model.load(region: .unitedStates)
        #expect(model.subscribedAvailability.isEmpty)
    }

    @Test func hasAnySubscriptionsReflectsPrefs() {
        let empty = makePrefs(subscribedTo: [])
        let populated = makePrefs(subscribedTo: [8])
        let repo = FakeMovieRepository()

        let modelEmpty = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: empty
        )
        let modelPopulated = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: populated
        )

        #expect(modelEmpty.hasAnySubscriptions == false)
        #expect(modelPopulated.hasAnySubscriptions == true)
    }

    // MARK: - Home / elsewhere partitioning

    @Test func providersAvailableAtHomeMatchesHomeRegion() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .spain,
                subscriptions: [
                    // Prime in ES + FR — both home and elsewhere
                    ProviderRegionalAvailability(provider: provider(9, "Prime Video"),
                                                  regions: [.spain, .france]),
                    // Netflix only in JP — elsewhere only
                    ProviderRegionalAvailability(provider: provider(8, "Netflix"),
                                                  regions: [Region(code: "JP")])
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [8, 9])
        prefs.region = .spain
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )

        await model.load(region: .spain)

        // Only Prime carries it in ES.
        #expect(model.providersAvailableAtHome.map(\.id) == [ProviderID(9)])
    }

    @Test func providersAvailableElsewhereStripsHomeAndExcludesHomeOnlyProviders() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .spain,
                subscriptions: [
                    // Prime in ES + FR + DE → elsewhere shows FR, DE
                    ProviderRegionalAvailability(provider: provider(9, "Prime Video"),
                                                  regions: [.spain, .france, .germany]),
                    // Netflix only in ES → excluded from elsewhere (no other regions)
                    ProviderRegionalAvailability(provider: provider(8, "Netflix"),
                                                  regions: [.spain])
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [8, 9])
        prefs.region = .spain
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )

        await model.load(region: .spain)

        // Netflix is home-only → not in elsewhere. Prime's elsewhere list
        // excludes ES.
        #expect(model.providersAvailableElsewhere.count == 1)
        let primeElsewhere = try! #require(
            model.providersAvailableElsewhere.first(where: { $0.provider.id == ProviderID(9) })
        )
        #expect(Set(primeElsewhere.regions.map(\.code)) == Set(["FR", "DE"]))
        #expect(!primeElsewhere.regions.contains(.spain))
    }

    @Test func providersAvailableElsewhereSortsAlphabeticallyByLocalizedName() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        // Put regions in deliberately-bad order: ZA, AR, MX. Sorted by
        // localized name in en-US: Argentina, Mexico, South Africa.
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .spain,
                subscriptions: [
                    ProviderRegionalAvailability(provider: provider(9, "Prime Video"),
                                                  regions: [Region(code: "ZA"), Region(code: "AR"), Region(code: "MX")])
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [9])
        prefs.region = .spain
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )

        await model.load(region: .spain)

        let elsewhere = model.providersAvailableElsewhere.first!
        // Whatever Locale.current returns for the names, they should be
        // sorted in increasing order.
        let names = elsewhere.regions.map(\.displayName)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }
}
