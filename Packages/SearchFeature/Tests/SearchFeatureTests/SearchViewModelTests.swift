import Testing
import Domain
@testable import SearchFeature

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeModel(_ repository: FakeMovieRepository) -> SearchViewModel {
        SearchViewModel(repository: repository, imageURLBuilder: NullImageURLBuilder())
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
}
