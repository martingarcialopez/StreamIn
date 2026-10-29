import Foundation
import Testing
import Domain
import Watchlist
import Preferences
@testable import WatchlistFeature

@MainActor
@Suite("WatchlistViewModel")
struct WatchlistViewModelTests {

    // MARK: - Items

    @Test func itemsComeThroughFromTheStoreNewestFirst() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(3, at: 300), .item(2, at: 200)])
        let model = makeModel(repository)

        await model.load()

        #expect(model.items.map(\.id.rawValue) == [3, 2, 1])
        #expect(model.isLoaded)
        #expect(model.loadError == nil)
    }

    /// The heart on Details writes to the same store.
    @Test func aMovieSavedElsewhereShowsUpWithoutReloading() async {
        let store = WatchlistStore(repository: FakeWatchlistRepository(stored: [.item(1, at: 100)]))
        let model = makeModel(store)
        await model.load()

        await store.add(.movie(2))

        #expect(model.items.map(\.id.rawValue) == [2, 1])
    }

    @Test func notLoadedBeforeTheFirstLoad() {
        let model = makeModel(FakeWatchlistRepository())

        #expect(!model.isLoaded)
    }

    // MARK: - Rows

    @Test func rowDetails() {
        let model = makeModel(FakeWatchlistRepository())
        let item = WatchlistItem(
            movie: .movie(
                1,
                releaseYear: 2012,
                posterPath: "/atlas.jpg",
                directors: ["Lana Wachowski", "Lilly Wachowski", "Tom Tykwer"]
            ),
            addedAt: .at(100)
        )

        #expect(model.posterURL(for: item) == URL(string: "https://image.test/poster/atlas.jpg"))
        #expect(model.year(for: item) == Date.year(2012).formatted(.dateTime.year()))
        #expect(model.directorsLine(for: item) == "Lana Wachowski, Lilly Wachowski & 1 more")
    }

    @Test func rowWithoutPosterYearOrDirectors() {
        let model = makeModel(FakeWatchlistRepository())
        let item = WatchlistItem.item(1, at: 100)

        #expect(model.posterURL(for: item) == nil)
        #expect(model.year(for: item) == nil)
        #expect(model.directorsLine(for: item) == nil)
    }

    // MARK: - Remove

    @Test func removeAtOffsetsRemovesThatRow() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 200), .item(3, at: 300)])
        let model = makeModel(repository)
        await model.load()

        await model.remove(atOffsets: IndexSet(integer: 1))

        #expect(model.items.map(\.id.rawValue) == [3, 1])
        #expect(await repository.stored.map(\.id.rawValue).sorted() == [1, 3])
    }

    @Test func removeAtSeveralOffsets() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 200), .item(3, at: 300)])
        let model = makeModel(repository)
        await model.load()

        await model.remove(atOffsets: IndexSet([0, 2]))

        #expect(model.items.map(\.id.rawValue) == [2])
        #expect(await repository.stored.map(\.id.rawValue) == [2])
    }

    /// The view reads the IDs when the swipe happens; a row that moves before
    /// the removal runs must not change which movie goes.
    @Test func idsTakenBeforeTheListChangesRemoveThoseMovies() async {
        let store = WatchlistStore(repository: FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 200)]))
        let model = makeModel(store)
        await model.load()

        let ids = model.ids(atOffsets: IndexSet(integer: 1))
        await store.add(.movie(3))
        await model.remove(ids)

        #expect(ids == [MovieID(1)])
        #expect(model.items.map(\.id.rawValue) == [3, 2])
    }

    // MARK: - Load failure and retry

    @Test func aFailedLoadIsAnError() async {
        let model = makeModel(FakeWatchlistRepository(stored: [.item(1, at: 100)], loadError: .loadFailed))

        await model.load()

        #expect(model.loadError == .loadFailed)
        #expect(!model.isLoaded)
        #expect(model.items.isEmpty)
    }

    @Test func retryAfterAFailedLoadShowsTheItems() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)], loadError: .loadFailed)
        let model = makeModel(repository)
        await model.load()

        await repository.set(loadError: nil)
        await model.retry()

        #expect(model.loadError == nil)
        #expect(model.isLoaded)
        #expect(model.items.map(\.id.rawValue) == [1])
    }

    // MARK: - Where to watch

    @Test func rowsLoadUntilAvailabilityArrives() async {
        let (model, _) = await loadedModel([1], movies: FakeMovieRepository(), prefs: makePrefs())

        #expect(row(1, in: model) == .loading)
    }

    /// Details' answer, per row: yours and free at home, else yours abroad,
    /// else why there's nothing.
    @Test func eachRowShowsDetailsAnswer() async {
        let movies = FakeMovieRepository(bundles: [
            MovieID(1): { .fixture(MovieID(1), region: $0, free: [.rtvePlay], global: [.init(provider: .netflix, regions: [$0])]) },
            MovieID(2): { .fixture(MovieID(2), region: $0, global: [.init(provider: .primeVideo, regions: [.france])]) },
            MovieID(3): { .fixture(MovieID(3), region: $0, subscription: [.filmin]) },
        ])
        let (model, _) = await loadedModel([1, 2, 3, 4], movies: movies, prefs: makePrefs(subscribedTo: [.netflix, .primeVideo]))

        await model.loadAvailability()

        #expect(row(1, in: model) == .loaded(.atHome([.netflix, .rtvePlay])))
        #expect(row(2, in: model) == .loaded(.abroad([.primeVideo])))
        #expect(row(3, in: model) == .loaded(.notOnYourServices))
        #expect(row(4, in: model) == .loaded(.notStreamingHere))
    }

    @Test func aFailedRowIsRetriedOnTheNextLoad() async {
        let movies = FakeMovieRepository(failAvailabilityOnce: [MovieID(1)])
        let (model, _) = await loadedModel([1, 2], movies: movies, prefs: makePrefs())

        await model.loadAvailability()
        #expect(row(1, in: model) == .failed)
        #expect(row(2, in: model) == .loaded(.notStreamingHere))

        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.notStreamingHere))
        #expect(await movies.availabilityCalls == [MovieID(1): 2, MovieID(2): 1])
    }

    /// A heart tapped on Details adds a row; only that one is fetched.
    @Test func aMovieSavedLaterIsFetchedAlone() async {
        let movies = FakeMovieRepository()
        let (model, store) = await loadedModel([1], movies: movies, prefs: makePrefs())
        await model.loadAvailability()
        let before = model.availabilityTrigger

        await store.add(.movie(2))
        await model.loadAvailability()

        #expect(model.availabilityTrigger != before)
        #expect(row(2, in: model) == .loaded(.notStreamingHere))
        #expect(await movies.availabilityCalls == [MovieID(1): 1, MovieID(2): 1])
    }

    @Test func aRegionChangeRefetchesEveryRow() async {
        let movies = FakeMovieRepository(bundles: [
            MovieID(1): { .fixture(MovieID(1), region: $0, free: $0 == .france ? [.rtvePlay] : []) },
        ])
        let prefs = makePrefs(region: .spain)
        let (model, _) = await loadedModel([1], movies: movies, prefs: prefs)
        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.notStreamingHere))
        let before = model.availabilityTrigger

        prefs.region = .france
        // The old region's answer isn't shown as the new one's.
        #expect(row(1, in: model) == .loading)
        #expect(model.availabilityTrigger != before)

        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.atHome([.rtvePlay])))
        #expect(await movies.availabilityCalls == [MovieID(1): 2])
    }

    /// The model lives as long as the app, so pull to refresh asks again for
    /// rows that already have an answer, keeping it until the new one lands.
    @Test func refreshRefetchesLoadedRows() async {
        let movies = FakeMovieRepository()
        let (model, _) = await loadedModel([1], movies: movies, prefs: makePrefs())
        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.notStreamingHere))

        await movies.set(MovieID(1)) { .fixture(MovieID(1), region: $0, free: [.rtvePlay]) }
        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.notStreamingHere))

        await model.loadAvailability(refetchingLoaded: true)
        #expect(row(1, in: model) == .loaded(.atHome([.rtvePlay])))
        #expect(await movies.availabilityCalls == [MovieID(1): 2])
    }

    /// The old region's answer, landing after the new region's, isn't kept.
    @Test func anAnswerForTheOldRegionIsDropped() async {
        let movies = GatedMovieRepository(gatedRegion: .spain)
        let prefs = makePrefs(region: .spain)
        let (model, _) = await loadedModel([1], movies: movies, prefs: prefs)

        let spainLoad = Task { await model.loadAvailability() }
        await movies.waitForGatedRequest()
        prefs.region = .france
        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.atHome([.rtvePlay])))

        await movies.release()
        await spainLoad.value

        #expect(row(1, in: model) == .loaded(.atHome([.rtvePlay])))
    }

    @Test func aSubscriptionChangeUpdatesRowsWithoutRefetching() async {
        let movies = FakeMovieRepository(bundles: [
            MovieID(1): { .fixture(MovieID(1), region: $0, subscription: [.filmin], global: [.init(provider: .filmin, regions: [$0])]) },
        ])
        let prefs = makePrefs()
        let (model, _) = await loadedModel([1], movies: movies, prefs: prefs)
        await model.loadAvailability()
        #expect(row(1, in: model) == .loaded(.notOnYourServices))

        prefs.subscribedProviderIDs = [WatchProvider.filmin.id]

        #expect(row(1, in: model) == .loaded(.atHome([.filmin])))
        #expect(await movies.availabilityCalls == [MovieID(1): 1])
    }

    @Test func voiceOverReadsTheRowAndNamesEveryProvider() async {
        let providers: [WatchProvider] = [.netflix, .primeVideo, .hboMax, .disneyPlus, .filmin]
        let movies = FakeMovieRepository(bundles: [
            MovieID(1): { region in
                .fixture(MovieID(1), region: region, global: providers.map { .init(provider: $0, regions: [region]) })
            },
        ])
        let store = WatchlistStore(repository: FakeWatchlistRepository(stored: [
            WatchlistItem(movie: .movie(1, releaseYear: 2010, directors: ["Christopher Nolan"]), addedAt: .at(100)),
        ]))
        let model = makeModel(store, movies: movies, prefs: makePrefs(subscribedTo: providers))
        await model.load()
        let item = model.items[0]
        #expect(model.accessibilityLabel(for: item).hasSuffix("Checking availability"))

        await model.loadAvailability()

        let year = Date.year(2010).formatted(.dateTime.year())
        let names = providers.map(\.name).formatted(.list(type: .and))
        #expect(model.accessibilityLabel(for: item) == "Movie 1, \(year), Christopher Nolan, On \(names)")
    }

    // MARK: - Helpers

    private func makeModel(_ repository: FakeWatchlistRepository) -> WatchlistViewModel {
        makeModel(WatchlistStore(repository: repository))
    }

    private func makeModel(
        _ store: WatchlistStore,
        movies: any MovieRepository = FakeMovieRepository(),
        prefs: Preferences? = nil
    ) -> WatchlistViewModel {
        WatchlistViewModel(
            store: store,
            repository: movies,
            imageURLBuilder: StubImageURLBuilder(),
            prefs: prefs ?? makePrefs()
        )
    }

    /// A loaded model whose watchlist holds `ids`, newest first.
    private func loadedModel(
        _ ids: [Int],
        movies: any MovieRepository,
        prefs: Preferences
    ) async -> (WatchlistViewModel, WatchlistStore) {
        let items = ids.enumerated().map { index, id in WatchlistItem.item(id, at: TimeInterval(1000 - index)) }
        let store = WatchlistStore(repository: FakeWatchlistRepository(stored: items))
        let model = makeModel(store, movies: movies, prefs: prefs)
        await model.load()
        return (model, store)
    }

    private func row(_ id: Int, in model: WatchlistViewModel) -> WatchlistRowProviders {
        model.rowProviders(for: model.items.first { $0.id == MovieID(id) }!)
    }
}

// MARK: - Fixtures

private struct StubImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? {
        URL(string: "https://image.test/\(size)\(path.rawValue)")
    }
}

extension Date {
    static func at(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    /// Mid-year, so it's the same year in every time zone.
    static func year(_ year: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: 6, day: 15))!
    }
}

extension Movie {
    static func movie(
        _ id: Int,
        releaseYear: Int? = nil,
        posterPath: String? = nil,
        directors: [String] = []
    ) -> Movie {
        Movie(
            id: MovieID(id),
            title: "Movie \(id)",
            originalTitle: "Movie \(id)",
            overview: "",
            releaseDate: releaseYear.map(Date.year),
            posterPath: posterPath.map(ImagePath.init),
            backdropPath: nil,
            voteAverage: 7,
            runtime: nil,
            directors: directors.enumerated().map { index, name in
                Person(id: PersonID(index), name: name, profilePath: nil)
            }
        )
    }
}

extension WatchlistItem {
    static func item(_ id: Int, at seconds: TimeInterval) -> WatchlistItem {
        WatchlistItem(movie: .movie(id), addedAt: .at(seconds))
    }
}
