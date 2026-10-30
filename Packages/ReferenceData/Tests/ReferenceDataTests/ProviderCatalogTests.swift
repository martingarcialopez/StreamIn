import Testing
import Domain
@testable import ReferenceData

// MARK: - Test double

/// Returns a fixed list per scope and counts calls, so tests can assert that
/// the catalog doesn't refetch scopes it already holds.
private actor FakeProviderRepository: MovieRepository {
    private var providersByScope: [Region?: [WatchProvider]]
    private var failure: MovieError?
    private(set) var allProvidersCalls: [Region?] = []

    init(providers: [Region?: [WatchProvider]] = [:], failure: MovieError? = nil) {
        self.providersByScope = providers
        self.failure = failure
    }

    func succeed() { failure = nil }

    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.unknown }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    func trendingMovies() async throws -> [Movie] { throw MovieError.unknown }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.unknown }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle { throw MovieError.unknown }

    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        allProvidersCalls.append(region)
        if let failure { throw failure }
        return providersByScope[region] ?? []
    }
}

private func provider(_ id: Int, _ name: String) -> WatchProvider {
    WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
}

// MARK: - Tests

@MainActor
@Suite("ProviderCatalog")
struct ProviderCatalogTests {

    @Test func isEmptyBeforeLoad() {
        let catalog = ProviderCatalog(repository: FakeProviderRepository())
        #expect(catalog.providers(in: nil) == nil)
        #expect(catalog.providers(in: .spain) == nil)
        #expect(catalog.provider(id: ProviderID(8)) == nil)
    }

    @Test func loadFetchesWorldwideAndRegion() async {
        let repo = FakeProviderRepository(providers: [
            nil: [provider(8, "Netflix"), provider(11, "MUBI")],
            .spain: [provider(8, "Netflix")],
        ])
        let catalog = ProviderCatalog(repository: repo)

        await catalog.load(region: .spain)

        #expect(catalog.providers(in: nil)?.map(\.id) == [ProviderID(8), ProviderID(11)])
        #expect(catalog.providers(in: .spain)?.map(\.id) == [ProviderID(8)])
        let requestedScopes = await repo.allProvidersCalls
        #expect(Set(requestedScopes) == [nil, .spain])
    }

    @Test func loadedScopesAreNotRefetched() async {
        let repo = FakeProviderRepository(providers: [nil: [provider(8, "Netflix")]])
        let catalog = ProviderCatalog(repository: repo)

        await catalog.load(region: .spain)
        await catalog.load(region: .spain)
        await catalog.load(region: .france)

        // Worldwide + Spain once each, then only France is new.
        #expect(await repo.allProvidersCalls.count == 3)
    }

    @Test func concurrentLoadsShareOneRequestPerScope() async {
        let repo = FakeProviderRepository(providers: [nil: [provider(8, "Netflix")]])
        let catalog = ProviderCatalog(repository: repo)

        async let first: Void = catalog.load(region: .spain)
        async let second: Void = catalog.load(region: .spain)
        _ = await (first, second)

        #expect(await repo.allProvidersCalls.count == 2)
    }

    @Test func providerLookupFindsEntriesFromAnyScope() async {
        let repo = FakeProviderRepository(providers: [
            nil: [provider(11, "MUBI")],
            .spain: [provider(8, "Netflix")],
        ])
        let catalog = ProviderCatalog(repository: repo)

        await catalog.load(region: .spain)

        #expect(catalog.provider(id: ProviderID(11))?.name == "MUBI")
        #expect(catalog.provider(id: ProviderID(8))?.name == "Netflix")
    }

    @Test func worldwideMetadataWinsOverRegional() async {
        let repo = FakeProviderRepository(providers: [
            nil: [provider(9, "Amazon Prime Video")],
            .spain: [provider(9, "Prime Video ES")],
        ])
        let catalog = ProviderCatalog(repository: repo)

        await catalog.load(region: .spain)

        #expect(catalog.provider(id: ProviderID(9))?.name == "Amazon Prime Video")
    }

    @Test func failedLoadIsRetriedOnNextCall() async {
        let repo = FakeProviderRepository(
            providers: [nil: [provider(8, "Netflix")]],
            failure: .offline
        )
        let catalog = ProviderCatalog(repository: repo)

        await catalog.load(region: .spain)
        #expect(catalog.lastError == .offline)
        #expect(catalog.providers(in: nil) == nil)

        await repo.succeed()
        await catalog.load(region: .spain)

        #expect(catalog.lastError == nil)
        #expect(catalog.providers(in: nil)?.map(\.id) == [ProviderID(8)])
    }
}
