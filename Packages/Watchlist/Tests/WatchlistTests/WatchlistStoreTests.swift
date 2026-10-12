import Testing
import Foundation
import Domain
@testable import Watchlist

/// Time-limited: a regression that never reaches the repository would
/// otherwise hang the tests that wait for a held load.
@MainActor
@Suite(.timeLimit(.minutes(1))) struct WatchlistStoreLoadTests {

    @Test func startsIdleAndEmpty() {
        let store = WatchlistStore(repository: FakeWatchlistRepository())
        #expect(store.loadState == .idle)
        #expect(store.items.isEmpty)
    }

    @Test func loadsNewestFirst() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 300), .item(3, at: 200)])
        let store = WatchlistStore(repository: repository)

        await store.load()

        #expect(store.loadState == .loaded)
        #expect(store.items.map(\.id.rawValue) == [2, 3, 1])
    }

    @Test func failedLoadIsReported() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(loadError: .loadFailed)
        let store = WatchlistStore(repository: repository)

        await store.load()

        #expect(store.loadState == .failed(.loadFailed))
        #expect(store.items.isEmpty)
    }

    @Test func loadingAgainAfterAFailureRetries() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(loadError: .loadFailed)
        let store = WatchlistStore(repository: repository)
        await store.load()

        await repository.set(loadError: nil)
        await store.load()

        #expect(store.loadState == .loaded)
        #expect(store.items.map(\.id.rawValue) == [1])
    }

    @Test func loadingTwiceAfterSuccessHitsTheRepositoryOnce() async {
        let repository = FakeWatchlistRepository()
        let store = WatchlistStore(repository: repository)

        await store.load()
        await store.load()

        #expect(await repository.loadCount == 1)
    }

    @Test func concurrentLoadsShareOneRequest() async {
        let repository = FakeWatchlistRepository()
        await repository.holdLoads()
        let store = WatchlistStore(repository: repository)

        async let first: Void = store.load()
        while await !repository.isHoldingLoad { await Task.yield() }
        #expect(store.loadState == .loading)
        async let second: Void = store.load()
        for _ in 0..<10 { await Task.yield() }
        #expect(await repository.loadCount == 1)

        await repository.releaseLoad()
        _ = await (first, second)

        #expect(await repository.loadCount == 1)
        #expect(store.loadState == .loaded)
    }

    /// After a failed load, a write can be queued when the retry starts; the
    /// retry must read after it, or the fetched list drops the new movie.
    @Test func aRetriedLoadWaitsForQueuedWrites() async {
        let repository = FakeWatchlistRepository()
        await repository.set(loadError: .loadFailed)
        await repository.set(saveDelay: .milliseconds(50))
        let store = WatchlistStore(repository: repository)
        await store.load()

        let adding = Task { await store.add(.movie(1)) }
        while !store.contains(MovieID(1)) { await Task.yield() }
        await repository.set(loadError: nil)
        await store.load()
        await adding.value

        #expect(store.loadState == .loaded)
        #expect(store.items.map(\.id.rawValue) == [1])
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1))) struct WatchlistStoreWriteTests {

    @Test func addPutsTheMovieFirstAndPersistsIt() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        let store = WatchlistStore(repository: repository, now: { .at(500) })

        await store.add(.movie(2))

        #expect(store.items.map(\.id.rawValue) == [2, 1])
        #expect(store.items.first?.addedAt == .at(500))
        #expect(store.contains(MovieID(2)))
        #expect(await repository.stored.map(\.id.rawValue).sorted() == [1, 2])
    }

    @Test func addingASavedMovieAgainChangesNothing() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        let store = WatchlistStore(repository: repository, now: { .at(500) })

        await store.add(.movie(1))

        #expect(store.items == [.item(1, at: 100)])
        #expect(await repository.writes.isEmpty)
    }

    @Test func removeDropsTheMovieAndPersists() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 200)])
        let store = WatchlistStore(repository: repository)

        await store.remove(MovieID(1))

        #expect(store.items.map(\.id.rawValue) == [2])
        #expect(!store.contains(MovieID(1)))
        #expect(await repository.stored.map(\.id.rawValue) == [2])
    }

    @Test func toggleAddsThenRemoves() async {
        let repository = FakeWatchlistRepository()
        let store = WatchlistStore(repository: repository)

        await store.toggle(.movie(1))
        #expect(store.contains(MovieID(1)))

        await store.toggle(.movie(1))
        #expect(!store.contains(MovieID(1)))
        #expect(await repository.writes == ["save 1", "remove 1"])
    }

    @Test func failedAddIsUndone() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(saveError: .saveFailed)
        let store = WatchlistStore(repository: repository)

        await store.add(.movie(2))

        #expect(store.items.map(\.id.rawValue) == [1])
        #expect(store.lastWriteError == .saveFailed)
    }

    @Test func failedRemovePutsTheMovieBackInItsPlace() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100), .item(2, at: 200), .item(3, at: 300)])
        await repository.set(removeError: .saveFailed)
        let store = WatchlistStore(repository: repository)

        await store.remove(MovieID(2))

        #expect(store.items.map(\.id.rawValue) == [3, 2, 1])
        #expect(store.lastWriteError == .saveFailed)
    }

    @Test func aSuccessfulWriteClearsTheLastError() async {
        let repository = FakeWatchlistRepository()
        await repository.set(saveError: .saveFailed)
        let store = WatchlistStore(repository: repository)
        await store.add(.movie(1))

        await repository.set(saveError: nil)
        await store.add(.movie(1))

        #expect(store.lastWriteError == nil)
        #expect(store.contains(MovieID(1)))
    }

    /// The first save is slow; without the queue, the remove would reach the
    /// repository first and the movie would end up saved.
    @Test func aDoubleTapPersistsInOrder() async {
        let repository = FakeWatchlistRepository()
        await repository.set(saveDelay: .milliseconds(50))
        let store = WatchlistStore(repository: repository)
        await store.load()

        let first = Task { await store.toggle(.movie(1)) }
        let second = Task { await store.toggle(.movie(1)) }
        await first.value
        await second.value

        #expect(await repository.writes == ["save 1", "remove 1"])
        #expect(await repository.stored.isEmpty)
        #expect(store.items.isEmpty)
    }

    /// Remove then re-add, both failing: the repository still holds the
    /// original, so the screen must too.
    @Test func twoFailedWritesShowWhatIsStored() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(removeError: .saveFailed)
        await repository.set(saveError: .saveFailed)
        let store = WatchlistStore(repository: repository, now: { .at(500) })
        await store.load()

        let first = Task { await store.toggle(.movie(1)) }
        let second = Task { await store.toggle(.movie(1)) }
        await first.value
        await second.value

        #expect(store.items == [.item(1, at: 100)])
        #expect(store.lastWriteError == .saveFailed)
    }

    /// Add then remove, both failing: nothing was ever stored.
    @Test func twoFailedWritesOnAnUnsavedMovieLeaveItUnsaved() async {
        let repository = FakeWatchlistRepository()
        await repository.set(removeError: .saveFailed)
        await repository.set(saveError: .saveFailed)
        let store = WatchlistStore(repository: repository)
        await store.load()

        let first = Task { await store.toggle(.movie(1)) }
        let second = Task { await store.toggle(.movie(1)) }
        await first.value
        await second.value

        #expect(store.items.isEmpty)
    }

    /// A failed write followed by a successful one for the same movie: the
    /// later write decides what's shown.
    @Test func aLaterSuccessfulWriteWinsOverAnEarlierFailure() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(removeError: .saveFailed)
        let store = WatchlistStore(repository: repository, now: { .at(500) })
        await store.load()

        let first = Task { await store.toggle(.movie(1)) }
        let second = Task { await store.toggle(.movie(1)) }
        await first.value
        await second.value

        #expect(store.items == [.item(1, at: 500)])
        #expect(await repository.stored == [.item(1, at: 500)])
    }

    @Test func aWriteDuringTheInitialLoadWaitsForIt() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.holdLoads()
        let store = WatchlistStore(repository: repository, now: { .at(500) })

        async let loading: Void = store.load()
        while await !repository.isHoldingLoad { await Task.yield() }
        async let adding: Void = store.add(.movie(2))
        await Task.yield()
        #expect(store.items.isEmpty)

        await repository.releaseLoad()
        _ = await (loading, adding)

        #expect(store.items.map(\.id.rawValue) == [2, 1])
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1))) struct WatchlistStoreRefreshTests {

    @Test func refreshUpdatesASavedMovieAndKeepsWhenItWasAdded() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        let store = WatchlistStore(repository: repository, now: { .at(999) })
        let detailed = Movie.movie(1, title: "Detailed", directors: ["Christopher Nolan"])

        await store.refresh(detailed)

        #expect(store.items == [WatchlistItem(movie: detailed, addedAt: .at(100))])
        #expect(await repository.stored == [WatchlistItem(movie: detailed, addedAt: .at(100))])
    }

    @Test func refreshIgnoresAMovieThatIsNotSaved() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        let store = WatchlistStore(repository: repository)

        await store.refresh(.movie(2))

        #expect(store.items.map(\.id.rawValue) == [1])
        #expect(await repository.writes.isEmpty)
    }

    @Test func refreshWithTheSameDataDoesNotWrite() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        let store = WatchlistStore(repository: repository)

        await store.refresh(.movie(1))

        #expect(await repository.writes.isEmpty)
    }

    @Test func failedRefreshKeepsTheEarlierSnapshot() async {
        let repository = FakeWatchlistRepository(stored: [.item(1, at: 100)])
        await repository.set(saveError: .saveFailed)
        let store = WatchlistStore(repository: repository)

        await store.refresh(.movie(1, title: "Detailed"))

        #expect(store.items == [.item(1, at: 100)])
        #expect(store.lastWriteError == .saveFailed)
    }
}

// MARK: - Fixtures

extension Date {
    static func at(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }
}

extension Movie {
    static func movie(_ id: Int, title: String = "Movie", directors: [String] = []) -> Movie {
        Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "",
            releaseDate: nil,
            posterPath: nil,
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
