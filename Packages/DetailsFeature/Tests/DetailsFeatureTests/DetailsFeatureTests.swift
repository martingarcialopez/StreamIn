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
    /// Makes `availabilities` wait until its task is cancelled, then throw
    /// the way the live repository does.
    var availabilitiesWaitForCancellation = false

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
        if availabilitiesWaitForCancellation {
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                throw MovieError.cancelled
            }
        }
        return try bundleResult.get()
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

// MARK: - Load states

@MainActor
@Suite struct LoadStateTests {

    private let netflixInSpain = AvailabilityBundle(
        regional: WatchAvailability(
            movieID: sampleMovie.id, region: .spain,
            subscription: [provider(8, "Netflix")], rent: [], buy: [], free: [], externalLink: nil
        ),
        global: GlobalWatchAvailability(
            movieID: sampleMovie.id,
            subscription: [ProviderRegionalAvailability(provider: provider(8, "Netflix"), regions: [.spain])]
        )
    )

    private func makeModel(_ repo: FakeMovieRepository, subscribedTo ids: [Int] = [8]) -> DetailsViewModel {
        let prefs = makePrefs(subscribedTo: ids)
        prefs.region = .spain
        return DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )
    }

    /// Before the first load finishes the section must spin, not claim the
    /// film isn't on the user's services.
    @Test func isLoadingBeforeTheFirstLoad() {
        let model = makeModel(FakeMovieRepository())

        #expect(model.subscriptionsState == .loading)
        #expect(model.availabilityFailure == nil)
    }

    @Test func offersThePickerWithoutSubscriptions() {
        let model = makeModel(FakeMovieRepository(), subscribedTo: [])

        #expect(model.subscriptionsState == .needsSubscriptions)
    }

    /// Offline must read as an error, never as "not available with your
    /// subscriptions".
    @Test func failedLoadIsAFailureNotANoMatch() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeModel(repo)

        await model.load(region: .spain)

        #expect(model.availabilityFailure == .offline)
        #expect(model.subscriptionsState == .failed(.offline))
    }

    /// The picker works offline (the provider catalog loads at launch), so a
    /// failed load must not hide it.
    @Test func failedLoadWithoutServicesStillOffersThePicker() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeModel(repo, subscribedTo: [])

        await model.load(region: .spain)

        #expect(model.subscriptionsState == .needsSubscriptions)
        #expect(model.availabilityFailure == .offline)
    }

    /// After a region change, the previous region's providers must not stay
    /// under "Where to watch" while the reload runs.
    @Test func providersFromThePreviousRegionAreHidden() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(netflixInSpain)
        let prefs = makePrefs(subscribedTo: [8])
        prefs.region = .spain
        let model = DetailsViewModel(
            movie: sampleMovie, repository: repo,
            imageURLBuilder: NoopImageURLBuilder(), prefs: prefs
        )
        await model.load(region: .spain)
        #expect(model.homeAvailability?.region == .spain)

        prefs.region = .unitedStates

        #expect(model.homeAvailability == nil)
    }

    @Test func retryAfterAFailureShowsTheResults() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeModel(repo)
        await model.load(region: .spain)

        repo.bundleResult = .success(netflixInSpain)
        await model.load(region: .spain)

        #expect(model.availabilityFailure == nil)
        #expect(model.error == nil)
        #expect(model.subscriptionsState == .available)
    }

    /// A failed reload keeps the earlier results on screen: the error shows
    /// below them instead of replacing them.
    @Test func failedReloadKeepsEarlierResults() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(netflixInSpain)
        let model = makeModel(repo)
        await model.load(region: .spain)

        repo.bundleResult = .failure(MovieError.timeout)
        await model.load(region: .spain)

        #expect(model.error == .timeout)
        #expect(model.availabilityFailure == nil)
        #expect(model.subscriptionsState == .available)
    }

    /// A load cancelled by a newer one (region or language change) or by the
    /// screen going away must not surface "cancelled" as an error.
    @Test func cancelledLoadWritesNothing() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.availabilitiesWaitForCancellation = true
        let model = makeModel(repo)

        let load = Task { await model.load(region: .spain) }
        load.cancel()
        await load.value

        #expect(model.error == nil)
        #expect(model.availabilityFailure == nil)
        #expect(model.globalAvailability == nil)
    }
}
