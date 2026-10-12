import Testing
import Foundation
import Domain
import Preferences
import Watchlist
@testable import DetailsFeature

@MainActor
@Suite struct WatchlistToggleTests {

    private let summary = Movie(
        id: MovieID(1), title: "Inception", originalTitle: "Inception", overview: "",
        releaseDate: nil, posterPath: nil, backdropPath: nil, voteAverage: 8.4, runtime: nil
    )

    private var detailed: Movie {
        Movie(
            id: summary.id, title: summary.title, originalTitle: summary.originalTitle,
            overview: "A thief who steals secrets through dreams.",
            releaseDate: nil, posterPath: nil, backdropPath: nil, voteAverage: 8.4,
            runtime: .seconds(148 * 60),
            directors: [Person(id: PersonID(525), name: "Christopher Nolan", profilePath: nil)]
        )
    }

    private func prefs() -> Preferences {
        let suite = "WatchlistToggleTests.\(UUID().uuidString)"
        return Preferences(defaults: UserDefaults(suiteName: suite)!)
    }

    /// A movie repository whose detail and availability loads succeed.
    private func loadingRepository() -> FakeMovieRepository {
        let repo = FakeMovieRepository()
        repo.movieResult = .success(detailed)
        repo.bundleResult = .success(AvailabilityBundle(
            regional: WatchAvailability(
                movieID: summary.id, region: .spain,
                subscription: [], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: summary.id, subscription: [])
        ))
        return repo
    }

    @Test func toggleAddsThenRemoves() async {
        let watchlist = WatchlistStore(repository: InMemoryWatchlistRepository())
        let model = makeModel(repository: FakeMovieRepository(), prefs: prefs(), movie: summary, watchlist: watchlist)
        #expect(!model.isSaved)

        await model.toggleWatchlist()
        #expect(model.isSaved)
        #expect(watchlist.contains(summary.id))

        await model.toggleWatchlist()
        #expect(!model.isSaved)
        #expect(watchlist.items.isEmpty)
    }

    @Test func isSavedFollowsTheStore() async {
        let watchlist = WatchlistStore(repository: InMemoryWatchlistRepository())
        let model = makeModel(repository: FakeMovieRepository(), prefs: prefs(), movie: summary, watchlist: watchlist)

        await watchlist.add(summary)
        #expect(model.isSaved)

        await watchlist.remove(summary.id)
        #expect(!model.isSaved)
    }

    /// The heart was tapped on the summary; the detail load fills in the rest.
    @Test func loadRefreshesASavedSnapshot() async {
        let saved = WatchlistItem(movie: summary, addedAt: Date(timeIntervalSinceReferenceDate: 100))
        let storage = InMemoryWatchlistRepository(stored: [saved])
        let watchlist = WatchlistStore(repository: storage)
        let model = makeModel(repository: loadingRepository(), prefs: prefs(), movie: summary, watchlist: watchlist)

        await model.load(region: .spain)

        let expected = WatchlistItem(movie: detailed, addedAt: saved.addedAt)
        #expect(watchlist.items == [expected])
        #expect(await storage.stored == [expected])
    }

    @Test func loadNeverAddsAnUnsavedMovie() async {
        let storage = InMemoryWatchlistRepository()
        let watchlist = WatchlistStore(repository: storage)
        let model = makeModel(repository: loadingRepository(), prefs: prefs(), movie: summary, watchlist: watchlist)

        await model.load(region: .spain)

        #expect(!model.isSaved)
        #expect(watchlist.items.isEmpty)
        #expect(await storage.stored.isEmpty)
    }

    /// After the load, the heart saves the full movie, not the summary.
    @Test func toggleAfterLoadSavesTheDetail() async {
        let watchlist = WatchlistStore(repository: InMemoryWatchlistRepository())
        let model = makeModel(repository: loadingRepository(), prefs: prefs(), movie: summary, watchlist: watchlist)
        await model.load(region: .spain)

        await model.toggleWatchlist()

        #expect(watchlist.items.map(\.movie) == [detailed])
    }
}
