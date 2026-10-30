import Testing
import Foundation
import Domain
import Preferences
import Watchlist
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
    func trendingMovies() async throws -> [Movie] {
        throw MovieError.unknown
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

/// `watchlist` defaults to an empty store over an in-memory repository.
@MainActor
func makeModel(
    repository: FakeMovieRepository,
    prefs: Preferences,
    movie: Movie = sampleMovie,
    watchlist: WatchlistStore? = nil
) -> DetailsViewModel {
    DetailsViewModel(
        movie: movie, repository: repository,
        imageURLBuilder: NoopImageURLBuilder(), prefs: prefs,
        watchlist: watchlist ?? WatchlistStore(repository: InMemoryWatchlistRepository())
    )
}

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
        let model = makeModel(repository: repo, prefs: prefs)

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
        let model = makeModel(repository: repo, prefs: prefs)

        await model.load(region: .unitedStates)
        #expect(model.subscribedAvailability.isEmpty)
    }

    @Test func hasAnySubscriptionsReflectsPrefs() {
        let empty = makePrefs(subscribedTo: [])
        let populated = makePrefs(subscribedTo: [8])
        let repo = FakeMovieRepository()

        let modelEmpty = makeModel(repository: repo, prefs: empty)
        let modelPopulated = makeModel(repository: repo, prefs: populated)

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
        let model = makeModel(repository: repo, prefs: prefs)

        await model.load(region: .spain)

        // Only Prime carries it in ES.
        #expect(model.providersAvailableAtHome.map(\.id) == [ProviderID(9)])
    }

    @Test func providersAvailableElsewhereStripsHomeAndExcludesHomeOnlyProviders() async throws {
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
        let model = makeModel(repository: repo, prefs: prefs)

        await model.load(region: .spain)

        // Netflix is home-only → not in elsewhere. Prime's elsewhere list
        // excludes ES.
        #expect(model.providersAvailableElsewhere.count == 1)
        let primeElsewhere = try #require(
            model.providersAvailableElsewhere.first(where: { $0.provider.id == ProviderID(9) })
        )
        #expect(Set(primeElsewhere.regions.map(\.code)) == Set(["FR", "DE"]))
        #expect(!primeElsewhere.regions.contains(.spain))
    }


    /// Popular VPN locations lead; the rest follow by localized name.
    @Test func providersAvailableElsewhereLeadWithPopularRegions() async throws {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(
            bundle(
                movieID: sampleMovie.id, region: .spain,
                subscriptions: [
                    ProviderRegionalAvailability(
                        provider: provider(9, "Prime Video"),
                        regions: ["ZA", "AR", "MX", "GB", "AD", "US"].map(Region.init(code:))
                    )
                ]
            )
        )
        let prefs = makePrefs(subscribedTo: [9])
        prefs.region = .spain
        let model = makeModel(repository: repo, prefs: prefs)

        await model.load(region: .spain)

        let regions = try #require(model.providersAvailableElsewhere.first).regions
        #expect(regions.prefix(3).map(\.code) == ["US", "GB", "MX"])
        let rest = regions.dropFirst(3).map(\.displayName)
        #expect(rest.count == 3)
        #expect(rest == rest.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
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

    private func makeSpanishModel(_ repo: FakeMovieRepository, subscribedTo ids: [Int] = [8]) -> DetailsViewModel {
        let prefs = makePrefs(subscribedTo: ids)
        prefs.region = .spain
        return makeModel(repository: repo, prefs: prefs)
    }

    /// Before the first load finishes the card must spin, not claim the
    /// film isn't on the user's services.
    @Test func isLoadingBeforeTheFirstLoad() {
        let model = makeSpanishModel(FakeMovieRepository())

        #expect(model.verdict == .loading)
        #expect(model.reloadError == nil)
    }

    /// Offline must read as an error, never as "go read a book".
    @Test func failedLoadIsAFailureNotUnavailable() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeSpanishModel(repo)

        await model.load(region: .spain)

        #expect(model.verdict == .failed(.offline))
        #expect(model.reloadError == nil)
    }

    /// After a region change, the previous region's providers must not stay
    /// under "Where to watch" while the reload runs.
    @Test func providersFromThePreviousRegionAreHidden() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(netflixInSpain)
        let prefs = makePrefs(subscribedTo: [8])
        prefs.region = .spain
        let model = makeModel(repository: repo, prefs: prefs)
        await model.load(region: .spain)
        #expect(model.homeAvailability?.region == .spain)

        prefs.region = .unitedStates

        #expect(model.homeAvailability == nil)
        #expect(model.verdict == .loading)
    }

    @Test func retryAfterAFailureShowsTheResults() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeSpanishModel(repo)
        await model.load(region: .spain)

        repo.bundleResult = .success(netflixInSpain)
        await model.load(region: .spain)

        #expect(model.reloadError == nil)
        #expect(model.error == nil)
        #expect(model.verdict == .watchNow)
    }

    /// A failed reload keeps the earlier results on screen: the error shows
    /// below them instead of replacing them.
    @Test func failedReloadKeepsEarlierResults() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(netflixInSpain)
        let model = makeSpanishModel(repo)
        await model.load(region: .spain)

        repo.bundleResult = .failure(MovieError.timeout)
        await model.load(region: .spain)

        #expect(model.reloadError == .timeout)
        #expect(model.verdict == .watchNow)
    }

    /// After a region change there's nothing left to keep for the new
    /// region, so a failed reload replaces the card's content instead.
    @Test func failedReloadAfterARegionChangeIsAFailure() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(netflixInSpain)
        let prefs = makePrefs(subscribedTo: [8])
        prefs.region = .spain
        let model = makeModel(repository: repo, prefs: prefs)
        await model.load(region: .spain)

        prefs.region = .unitedStates
        repo.bundleResult = .failure(MovieError.offline)
        await model.load(region: .unitedStates)

        #expect(model.reloadError == nil)
        #expect(model.verdict == .failed(.offline))
    }

    /// A load cancelled by a newer one (region or language change) or by the
    /// screen going away must not surface "cancelled" as an error.
    @Test func cancelledLoadWritesNothing() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.availabilitiesWaitForCancellation = true
        let model = makeSpanishModel(repo)

        let load = Task { await model.load(region: .spain) }
        load.cancel()
        await load.value

        #expect(model.error == nil)
        #expect(model.reloadError == nil)
        #expect(model.globalAvailability == nil)
    }
}

// MARK: - Where to watch

@MainActor
@Suite struct WhereToWatchTests {

    private let netflix = provider(8, "Netflix")
    private let prime = provider(9, "Prime Video")
    private let disney = provider(337, "Disney+")
    private let rtve = provider(541, "RTVE Play")

    private func bundle(
        region: Region = .spain,
        subscription: [WatchProvider] = [],
        rent: [WatchProvider] = [],
        buy: [WatchProvider] = [],
        free: [WatchProvider] = [],
        global: [ProviderRegionalAvailability] = []
    ) -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: sampleMovie.id, region: region,
                subscription: subscription, rent: rent, buy: buy, free: free, externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: sampleMovie.id, subscription: global)
        )
    }

    private func loadedModel(
        _ bundle: AvailabilityBundle,
        subscribedTo ids: [Int] = []
    ) async -> DetailsViewModel {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .success(bundle)
        let prefs = makePrefs(subscribedTo: ids)
        prefs.region = .spain
        let model = makeModel(repository: repo, prefs: prefs)
        await model.load(region: .spain)
        return model
    }

    @Test func homeRegionLabelCombinesFlagAndName() {
        let prefs = makePrefs(subscribedTo: [])
        prefs.region = .spain
        let model = makeModel(repository: FakeMovieRepository(), prefs: prefs)

        #expect(model.homeRegionLabel == "\(Region.spain.flag) \(Region.spain.displayName)")
    }

    @Test func homeSubscriptionsOthersDropsSubscribedAndFreeAndKeepsOrder() async {
        let model = await loadedModel(
            bundle(
                subscription: [
                    disney, netflix, prime, provider(350, "Apple TV+"), provider(11, "Mubi")
                ],
                free: [prime],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.spain])]
            ),
            subscribedTo: [8]
        )

        #expect(model.homeSubscriptionsOthers.map(\.id) == [ProviderID(337), ProviderID(350), ProviderID(11)])
        #expect(model.homeFreeProviders.map(\.id) == [ProviderID(9)])
    }

    @Test func homeListsAreEmptyUntilHomeAvailabilityLoads() {
        let prefs = makePrefs(subscribedTo: [8])
        prefs.region = .spain
        let model = makeModel(repository: FakeMovieRepository(), prefs: prefs)

        #expect(model.homeFreeProviders.isEmpty)
        #expect(model.homeSubscriptionsOthers.isEmpty)
    }

    @Test func watchNowProvidersListYoursThenFreeWithoutDuplicates() async {
        let model = await loadedModel(
            bundle(
                subscription: [netflix, prime],
                free: [rtve, prime],
                global: [
                    ProviderRegionalAvailability(provider: netflix, regions: [.spain]),
                    ProviderRegionalAvailability(provider: prime, regions: [.spain]),
                ]
            ),
            subscribedTo: [8, 9]
        )

        #expect(model.watchNowProviders.map(\.id) == [ProviderID(8), ProviderID(9), ProviderID(541)])
    }

    // MARK: verdict

    /// No services picked, but a failed load shows the error, not the picker.
    @Test func failedLoadWinsOverThePicker() async {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(sampleMovie)
        repo.bundleResult = .failure(MovieError.offline)
        let model = makeModel(repository: repo, prefs: makePrefs(subscribedTo: []))

        await model.load(region: .spain)

        #expect(model.verdict == .failed(.offline))
    }

    /// Watchable at home on a service the user pays for: their services
    /// abroad don't matter, even when they carry it there too.
    @Test func watchNowWithYourServiceAtHomeEvenWhenAlsoAbroad() async {
        let model = await loadedModel(
            bundle(
                subscription: [netflix],
                global: [
                    ProviderRegionalAvailability(provider: netflix, regions: [.spain, .france]),
                    ProviderRegionalAvailability(provider: prime, regions: [.unitedStates]),
                ]
            ),
            subscribedTo: [8, 9]
        )

        #expect(model.verdict == .watchNow)
        #expect(model.offersServicePicker == false)
    }

    /// Free at home counts as much as the user's own services.
    @Test func watchNowWithFreeAtHomeHidesAbroad() async {
        let model = await loadedModel(
            bundle(
                free: [rtve],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.france])]
            ),
            subscribedTo: [8]
        )

        #expect(model.verdict == .watchNow)
        #expect(model.watchNowProviders.map(\.id) == [ProviderID(541)])
    }

    @Test func watchNowWithFreeAndNoServicesOffersThePicker() async {
        let model = await loadedModel(bundle(subscription: [disney], free: [rtve]))

        #expect(model.verdict == .watchNow)
        #expect(model.offersServicePicker)
    }

    @Test func abroadWhenOnlyYourServicesElsewhereCarryIt() async {
        let model = await loadedModel(
            bundle(
                subscription: [disney],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.france])]
            ),
            subscribedTo: [8]
        )

        #expect(model.verdict == .abroad)
        #expect(model.homeSubscriptionsOthers.map(\.id) == [ProviderID(337)])
    }

    @Test func chooseServicesWithoutServicesAndNothingFree() async {
        let model = await loadedModel(bundle(subscription: [disney]))

        #expect(model.verdict == .chooseServices)
        #expect(model.offersServicePicker == false)
    }

    @Test func unavailableWhenYourServicesCarryItNowhere() async {
        let model = await loadedModel(
            bundle(
                subscription: [netflix],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.spain])]
            ),
            subscribedTo: [337]
        )

        #expect(model.verdict == .unavailable)
        #expect(model.homeSubscriptionsOthers.map(\.id) == [ProviderID(8)])
    }

    /// Rent and buy aren't shown in v1, so they don't make it watchable.
    @Test func unavailableForRentAndBuyOnly() async {
        let model = await loadedModel(
            bundle(rent: [provider(2, "Apple TV")], buy: [provider(3, "Google Play")]),
            subscribedTo: [8]
        )

        #expect(model.verdict == .unavailable)
        #expect(model.homeSubscriptionsOthers.isEmpty)
    }
}
