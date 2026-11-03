import Testing
import Domain
@testable import ReferenceData

// MARK: - Test double

/// Returns a fixed region list and counts calls.
private actor FakeRegionRepository: MovieRepository {
    private let regions: [Region]
    private var failure: MovieError?
    private(set) var watchRegionsCalls = 0

    init(regions: [Region] = [], failure: MovieError? = nil) {
        self.regions = regions
        self.failure = failure
    }

    func succeed() { failure = nil }

    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.unknown }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    func trendingMovies() async throws -> [Movie] { throw MovieError.unknown }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.unknown }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle { throw MovieError.unknown }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { throw MovieError.unknown }

    func watchRegions() async throws -> [Region] {
        watchRegionsCalls += 1
        if let failure { throw failure }
        return regions
    }
}

// MARK: - Tests

@MainActor
@Suite("RegionCatalog")
struct RegionCatalogTests {

    /// Countries whose names sort the same in English and Spanish, so the test
    /// doesn't depend on the simulator's language.
    private let unsorted = ["IT", "AR", "CA", "BR"].map(Region.init(code:))

    @Test func isEmptyBeforeLoad() {
        let catalog = RegionCatalog(repository: FakeRegionRepository())
        #expect(catalog.regions == nil)
        #expect(!catalog.isLoading)
    }

    @Test func loadSortsRegionsByName() async {
        let catalog = RegionCatalog(repository: FakeRegionRepository(regions: unsorted))

        await catalog.load()

        #expect(catalog.regions?.map(\.code) == ["AR", "BR", "CA", "IT"])
        #expect(catalog.lastError == nil)
    }

    @Test func loadedListIsNotRefetched() async {
        let repo = FakeRegionRepository(regions: unsorted)
        let catalog = RegionCatalog(repository: repo)

        await catalog.load()
        await catalog.load()

        #expect(await repo.watchRegionsCalls == 1)
    }

    @Test func concurrentLoadsShareOneRequest() async {
        let repo = FakeRegionRepository(regions: unsorted)
        let catalog = RegionCatalog(repository: repo)

        async let first: Void = catalog.load()
        async let second: Void = catalog.load()
        _ = await (first, second)

        #expect(await repo.watchRegionsCalls == 1)
        #expect(catalog.regions?.count == 4)
    }

    @Test func failedLoadIsRetriedOnNextCall() async {
        let repo = FakeRegionRepository(regions: unsorted, failure: .offline)
        let catalog = RegionCatalog(repository: repo)

        await catalog.load()
        #expect(catalog.lastError == .offline)
        #expect(catalog.regions == nil)
        #expect(!catalog.isLoading)

        await repo.succeed()
        await catalog.load()

        #expect(catalog.lastError == nil)
        #expect(catalog.regions?.count == 4)
    }
}
