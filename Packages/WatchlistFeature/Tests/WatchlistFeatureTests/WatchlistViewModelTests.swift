import Foundation
import Testing
import Domain
import Watchlist
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
        let model = WatchlistViewModel(store: store, imageURLBuilder: StubImageURLBuilder())
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
        let model = WatchlistViewModel(store: store, imageURLBuilder: StubImageURLBuilder())
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

    // MARK: - Helpers

    private func makeModel(_ repository: FakeWatchlistRepository) -> WatchlistViewModel {
        WatchlistViewModel(store: WatchlistStore(repository: repository), imageURLBuilder: StubImageURLBuilder())
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
