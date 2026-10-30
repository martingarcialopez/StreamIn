import Testing
import Foundation
import Domain
import Preferences
@testable import SearchFeature

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeModel(_ repository: FakeMovieRepository, prefs: Preferences = makePrefs()) -> SearchViewModel {
        SearchViewModel(repository: repository, imageURLBuilder: NullImageURLBuilder(), prefs: prefs)
    }

    @Test func hasNoLoadedResultsBeforeFirstSearch() {
        let model = makeModel(FakeMovieRepository(results: []))

        #expect(!model.hasLoadedResults)
        #expect(!model.isLoading)
    }

    @Test func searchLoadsResultsAndAvailability() async {
        let repo = FakeMovieRepository(results: [.fixture(1), .fixture(2)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)

        #expect(model.hasLoadedResults)
        #expect(model.results.map(\.id) == [MovieID(1), MovieID(2)])
        #expect(Set(model.availability.keys) == [MovieID(1), MovieID(2)])
        #expect(model.error == nil)
        #expect(!model.isLoading)
    }

    /// "Nothing found" must be distinguishable from "not searched yet", or
    /// the results screen would spin forever on an empty result.
    @Test func emptyResultStillCountsAsLoaded() async {
        let model = makeModel(FakeMovieRepository(results: []))

        await model.search(query: "zzzzzz", region: .spain, language: .englishUS)

        #expect(model.hasLoadedResults)
        #expect(model.results.isEmpty)
    }

    /// Details → back: the results screen's `.task` fires again with the same
    /// inputs. Nothing may be refetched or cleared.
    @Test func repeatingTheSameSearchKeepsResultsWithoutRefetching() async {
        let repo = FakeMovieRepository(results: [.fixture(1), .fixture(2)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: "Inception", region: .spain, language: .englishUS)

        #expect(await repo.searchCalls == 1)
        #expect(await repo.availabilityCalls[MovieID(1)] == 1)
        #expect(await repo.availabilityCalls[MovieID(2)] == 1)
        #expect(model.results.map(\.id) == [MovieID(1), MovieID(2)])
    }

    @Test func repeatingTheSameSearchRetriesOnlyMissingAvailability() async {
        let repo = FakeMovieRepository(
            results: [.fixture(1), .fixture(2)],
            failAvailabilityOnce: [MovieID(2)]
        )
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        #expect(Set(model.availability.keys) == [MovieID(1)])

        await model.search(query: "Inception", region: .spain, language: .englishUS)

        #expect(await repo.searchCalls == 1)
        #expect(await repo.availabilityCalls[MovieID(1)] == 1)
        #expect(await repo.availabilityCalls[MovieID(2)] == 2)
        #expect(Set(model.availability.keys) == [MovieID(1), MovieID(2)])
    }

    @Test func surroundingWhitespaceDoesNotCountAsANewQuery() async {
        let repo = FakeMovieRepository(results: [.fixture(1)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: " Inception ", region: .spain, language: .englishUS)

        #expect(await repo.searchCalls == 1)
    }

    @Test func differentQueryRunsANewSearch() async {
        let repo = FakeMovieRepository(results: [.fixture(1)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: "Dune", region: .spain, language: .englishUS)

        #expect(await repo.searchCalls == 2)
    }

    @Test func regionChangeRunsANewSearch() async {
        let repo = FakeMovieRepository(results: [.fixture(1)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: "Inception", region: .france, language: .englishUS)

        #expect(await repo.searchCalls == 2)
        #expect(await repo.availabilityCalls[MovieID(1)] == 2)
    }

    @Test func languageChangeRunsANewSearch() async {
        let repo = FakeMovieRepository(results: [.fixture(1)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: "Inception", region: .spain, language: .spanishES)

        #expect(await repo.searchCalls == 2)
    }

    @Test func failedSearchIsRetriedOnTheNextCall() async {
        let repo = FakeMovieRepository(results: [.fixture(1)], searchError: .offline)
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        #expect(model.error == .offline)
        #expect(model.results.isEmpty)
        #expect(!model.hasLoadedResults)
        #expect(!model.isLoading)

        await repo.setSearchError(nil)
        await model.search(query: "Inception", region: .spain, language: .englishUS)

        #expect(await repo.searchCalls == 2)
        #expect(model.error == nil)
        #expect(model.results.map(\.id) == [MovieID(1)])
    }

    @Test func blankQueryClearsResults() async {
        let repo = FakeMovieRepository(results: [.fixture(1)])
        let model = makeModel(repo)

        await model.search(query: "Inception", region: .spain, language: .englishUS)
        await model.search(query: "   ", region: .spain, language: .englishUS)

        #expect(model.results.isEmpty)
        #expect(model.availability.isEmpty)
        #expect(await repo.searchCalls == 1)
    }

    // MARK: - Failed rows

    @Test func failedAvailabilityShowsAsFailedNotLoading() async {
        let repo = FakeMovieRepository(
            results: [.fixture(1), .fixture(2)],
            failAvailabilityOnce: [MovieID(2)]
        )
        let model = makeModel(repo)

        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)

        #expect(model.rowProviders(for: .fixture(1)) == .loaded(.notStreamingHere))
        #expect(model.rowProviders(for: .fixture(2)) == .failed)
    }

    /// Pull to refresh runs the same search: the failed row is retried and
    /// its failure cleared.
    @Test func repeatingTheSearchRetriesAFailedRow() async {
        let repo = FakeMovieRepository(results: [.fixture(1)], failAvailabilityOnce: [MovieID(1)])
        let model = makeModel(repo)

        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)
        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)

        #expect(model.failedAvailability.isEmpty)
        #expect(model.rowProviders(for: .fixture(1)) == .loaded(.notStreamingHere))
    }

    /// The new search fetches no rows (it fails), so only the reset in
    /// `search` can clear the old failure.
    @Test func aNewSearchClearsFailures() async {
        let repo = FakeMovieRepository(results: [.fixture(1)], failAvailabilityOnce: [MovieID(1)])
        let model = makeModel(repo)

        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)
        #expect(model.failedAvailability == [MovieID(1)])

        await repo.setSearchError(.offline)
        await model.search(query: "Hook", region: .spain, language: .englishUS)

        #expect(model.failedAvailability.isEmpty)
    }

    @Test func rowIsLoadingBeforeItsAvailabilityArrives() {
        let model = makeModel(FakeMovieRepository(results: []))

        #expect(model.rowProviders(for: .fixture(1)) == .loading)
    }
}

// MARK: - Row providers

@MainActor
@Suite("SearchViewModel row providers")
struct SearchRowProvidersTests {

    private let movie = Movie.fixture(1)

    private func rowProviders(
        _ bundle: AvailabilityBundle,
        subscribedTo providers: [WatchProvider]
    ) async -> SearchRowProviders {
        let model = SearchViewModel(
            repository: FakeMovieRepository(results: [movie], bundles: [movie.id: bundle]),
            imageURLBuilder: NullImageURLBuilder(),
            prefs: makePrefs(subscribedTo: providers)
        )
        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)
        return model.rowProviders(for: movie)
    }

    @Test func yoursAtHomeThenFree() async {
        let bundle = AvailabilityBundle.fixture(
            movie.id,
            subscription: [.filmin, .netflix],
            free: [.rtvePlay, .netflix],
            global: [ProviderRegionalAvailability(provider: .netflix, regions: [.spain, .france])]
        )

        let row = await rowProviders(bundle, subscribedTo: [.netflix])

        #expect(row == .loaded(.atHome([.netflix, .rtvePlay])))
    }

    @Test func freeAtHomeWithoutServices() async {
        let row = await rowProviders(.fixture(movie.id, free: [.rtvePlay]), subscribedTo: [])

        #expect(row == .loaded(.atHome([.rtvePlay])))
    }

    /// Like Details: your services abroad count only without anything of
    /// yours or free at home.
    @Test func freeAtHomeWinsOverYoursAbroad() async {
        let bundle = AvailabilityBundle.fixture(
            movie.id,
            free: [.rtvePlay],
            global: [ProviderRegionalAvailability(provider: .netflix, regions: [.unitedStates])]
        )

        let row = await rowProviders(bundle, subscribedTo: [.netflix])

        #expect(row == .loaded(.atHome([.rtvePlay])))
    }

    @Test func yoursAbroadInTMDBOrder() async {
        let bundle = AvailabilityBundle.fixture(
            movie.id,
            subscription: [.filmin],
            global: [
                ProviderRegionalAvailability(provider: .primeVideo, regions: [Region(code: "JP")]),
                ProviderRegionalAvailability(provider: .disneyPlus, regions: [.unitedStates]),
                ProviderRegionalAvailability(provider: .netflix, regions: [.france]),
            ]
        )

        let row = await rowProviders(bundle, subscribedTo: [.netflix, .primeVideo])

        #expect(row == .loaded(.abroad([.primeVideo, .netflix])))
    }

    @Test func otherServicesWhenOnlyOthersStreamItHere() async {
        let bundle = AvailabilityBundle.fixture(
            movie.id,
            subscription: [.filmin],
            global: [ProviderRegionalAvailability(provider: .filmin, regions: [.spain])]
        )

        let row = await rowProviders(bundle, subscribedTo: [.netflix])

        #expect(row == .loaded(.othersAtHome([.filmin])))
    }

    @Test func notStreamingHereWhenNothingCarriesIt() async {
        let bundle = AvailabilityBundle.fixture(
            movie.id,
            global: [ProviderRegionalAvailability(provider: .filmin, regions: [.france])]
        )

        let row = await rowProviders(bundle, subscribedTo: [.netflix])

        #expect(row == .loaded(.notStreamingHere))
    }

    /// Subscriptions are read live: a change in Settings updates the rows
    /// already on screen, without fetching again.
    @Test func subscriptionChangeUpdatesTheRow() async {
        let repo = FakeMovieRepository(
            results: [movie],
            bundles: [movie.id: .fixture(
                movie.id,
                subscription: [.filmin],
                global: [ProviderRegionalAvailability(provider: .filmin, regions: [.spain])]
            )]
        )
        let prefs = makePrefs(subscribedTo: [.netflix])
        let model = SearchViewModel(repository: repo, imageURLBuilder: NullImageURLBuilder(), prefs: prefs)
        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)
        #expect(model.rowProviders(for: movie) == .loaded(.othersAtHome([.filmin])))

        prefs.subscribedProviderIDs.insert(WatchProvider.filmin.id)

        #expect(model.rowProviders(for: movie) == .loaded(.atHome([.filmin])))
        #expect(await repo.availabilityCalls[movie.id] == 1)
    }
}

// MARK: - Display strings

@MainActor
@Suite("SearchViewModel display strings")
struct SearchRowDisplayTests {

    @Test func accessibilityLabelReadsTitleYearAndEveryProvider() async {
        let movie = Movie.fixture(1, releaseDate: DateComponents(calendar: .current, year: 2003, month: 12, day: 18).date)
        let repo = FakeMovieRepository(
            results: [movie],
            bundles: [movie.id: .fixture(
                movie.id,
                global: [.netflix, .primeVideo, .disneyPlus, .filmin].map {
                    ProviderRegionalAvailability(provider: $0, regions: [.spain])
                }
            )]
        )
        let model = SearchViewModel(
            repository: repo,
            imageURLBuilder: NullImageURLBuilder(),
            prefs: makePrefs(subscribedTo: [.netflix, .primeVideo, .disneyPlus, .filmin])
        )
        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)

        let label = model.accessibilityLabel(for: movie)

        #expect(label.hasPrefix("Movie 1, \(model.releaseYear(for: movie) ?? "")"))
        // All four, although the row shows three logos and "+1".
        for name in ["Netflix", "Prime Video", "Disney Plus", "Filmin"] {
            #expect(label.contains(name))
        }
    }

    @Test func noReleaseDateMeansNoYear() {
        let model = SearchViewModel(
            repository: FakeMovieRepository(results: []),
            imageURLBuilder: NullImageURLBuilder(),
            prefs: makePrefs()
        )

        #expect(model.releaseYear(for: .fixture(1)) == nil)
    }

    @Test func accessibilityLabelSaysOtherServicesArentYours() async {
        let movie = Movie.fixture(1)
        let repo = FakeMovieRepository(
            results: [movie],
            bundles: [movie.id: .fixture(movie.id, subscription: [.filmin, .disneyPlus])]
        )
        let model = SearchViewModel(
            repository: repo,
            imageURLBuilder: NullImageURLBuilder(),
            prefs: makePrefs(subscribedTo: [.netflix])
        )
        await model.search(query: "Peter Pan", region: .spain, language: .englishUS)

        let names = [WatchProvider.filmin, .disneyPlus].map(\.name).formatted(.list(type: .and))
        #expect(model.accessibilityLabel(for: movie).hasSuffix("Not on your services, on \(names)"))
    }
}
