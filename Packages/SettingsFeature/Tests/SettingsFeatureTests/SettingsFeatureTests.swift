import Testing
import Foundation
import Domain
import Preferences
import ReferenceData
@testable import SettingsFeature

// MARK: - Test double

/// Repository whose `allProviders` returns different lists depending on the
/// requested scope. Use `setProviders(_:for:)` per-region (or `for: nil` for
/// worldwide) before exercising the view model.
final class FakeMovieRepository: MovieRepository, @unchecked Sendable {
    private var providersByRegion: [String: [WatchProvider]] = [:]
    private let worldwideKey = "_worldwide"

    func setProviders(_ providers: [WatchProvider], for region: Region?) {
        providersByRegion[region?.code ?? worldwideKey] = providers
    }

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        throw MovieError.unknown
    }
    func movie(id: MovieID) async throws -> Movie {
        throw MovieError.unknown
    }
    func trendingMovies() async throws -> [Movie] {
        throw MovieError.unknown
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        throw MovieError.unknown
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        throw MovieError.unknown
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        providersByRegion[region?.code ?? worldwideKey] ?? []
    }

    /// What `watchRegions()` returns, unless `regionsFailure` is set.
    var regions: [Region] = []
    var regionsFailure: MovieError?

    func watchRegions() async throws -> [Region] {
        if let regionsFailure { throw regionsFailure }
        return regions
    }
}

@MainActor
private func makePrefs(region: Region = .spain) -> Preferences {
    let suite = "SettingsFeatureTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let prefs = Preferences(defaults: defaults)
    prefs.region = region
    return prefs
}

private func provider(_ id: Int, _ name: String, priority: Int = 1) -> WatchProvider {
    WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: priority)
}

@MainActor
@Suite struct StreamingServicesViewModelTests {

    @Test func toggleAddsAndRemoves() {
        let prefs = makePrefs()
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: FakeMovieRepository()), prefs: prefs)

        model.toggle(ProviderID(8))
        #expect(prefs.subscribedProviderIDs == [ProviderID(8)])
        #expect(model.isSubscribed(ProviderID(8)))

        model.toggle(ProviderID(8))
        #expect(prefs.subscribedProviderIDs.isEmpty)
        #expect(!model.isSubscribed(ProviderID(8)))
    }

    @Test func selectedCountReflectsPrefs() {
        let prefs = makePrefs()
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: FakeMovieRepository()), prefs: prefs)
        #expect(model.selectedCount == 0)

        prefs.subscribedProviderIDs = [ProviderID(8), ProviderID(9)]
        #expect(model.selectedCount == 2)
    }

    @Test func availableProvidersExcludesSelected() async {
        let repo = FakeMovieRepository()
        repo.setProviders([
            provider(8, "Netflix", priority: 1),
            provider(9, "Prime Video", priority: 2),
            provider(337, "Disney+", priority: 3)
        ], for: .spain)
        repo.setProviders([], for: nil)

        let prefs = makePrefs(region: .spain)
        prefs.subscribedProviderIDs = [ProviderID(8)]
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: repo), prefs: prefs)
        await model.load()

        // Netflix is selected → only Prime Video + Disney+ in the available list.
        #expect(model.availableProviders.map(\.id) == [ProviderID(9), ProviderID(337)])
    }

    @Test func availableProvidersSwitchesOnWorldwideToggle() async {
        let repo = FakeMovieRepository()
        repo.setProviders([provider(8, "Netflix")], for: .spain)
        repo.setProviders([
            provider(8, "Netflix"),
            provider(11, "MUBI", priority: 50)
        ], for: nil)
        let prefs = makePrefs(region: .spain)
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: repo), prefs: prefs)
        await model.load()

        // Home-scope: only Spain catalog (Netflix).
        #expect(model.availableProviders.map(\.id) == [ProviderID(8)])

        model.showWorldwide = true
        // Worldwide-scope: both Netflix and MUBI.
        #expect(Set(model.availableProviders.map(\.id)) == Set([ProviderID(8), ProviderID(11)]))
    }

    @Test func selectedProvidersResolvesMetadataFromEitherCatalog() async {
        let repo = FakeMovieRepository()
        // Regional doesn't have MUBI; worldwide does.
        repo.setProviders([provider(8, "Netflix")], for: .spain)
        repo.setProviders([
            provider(8, "Netflix"),
            provider(11, "MUBI")
        ], for: nil)

        let prefs = makePrefs(region: .spain)
        prefs.subscribedProviderIDs = [ProviderID(11)]
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: repo), prefs: prefs)
        await model.load()

        // MUBI's name comes from worldwide even though regional doesn't carry it.
        #expect(model.selectedProviders.map(\.id) == [ProviderID(11)])
        #expect(model.selectedProviders.first?.name == "MUBI")
    }

    @Test func searchFiltersAvailableButNotSelected() async {
        let repo = FakeMovieRepository()
        repo.setProviders([
            provider(8, "Netflix"),
            provider(11, "MUBI"),
            provider(283, "Crunchyroll")
        ], for: .spain)
        repo.setProviders([], for: nil)

        let prefs = makePrefs(region: .spain)
        prefs.subscribedProviderIDs = [ProviderID(8)]
        let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: repo), prefs: prefs)
        await model.load()

        model.searchText = "mubi"
        // Selected list IS NOT filtered by search — Netflix stays visible so
        // the Settings row's icon strip doesn't lose icons while the user
        // types in the picker.
        #expect(model.selectedProviders.map(\.id) == [ProviderID(8)])
        // Available list IS filtered — only MUBI matches.
        #expect(model.availableProviders.map(\.id) == [ProviderID(11)])
    }

    @Test func hasLoadedAnyCatalogFlipsAfterLoad() async {
        let repo = FakeMovieRepository()
        repo.setProviders([provider(8, "Netflix")], for: .spain)
        repo.setProviders([], for: nil)
        let model = StreamingServicesViewModel(
            catalog: ProviderCatalog(repository: repo),
            prefs: makePrefs(region: .spain)
        )

        #expect(model.hasLoadedAnyCatalog == false)
        await model.load()
        #expect(model.hasLoadedAnyCatalog == true)
    }

    /// The Settings flicker fix: with the catalog preloaded at launch, a
    /// freshly opened Settings screen has everything on its first render —
    /// no "N selected" placeholder that later flips to the logo strip.
    @Test func preloadedCatalogIsCompleteWithoutLoading() async {
        let repo = FakeMovieRepository()
        repo.setProviders([provider(8, "Netflix")], for: .spain)
        repo.setProviders([provider(8, "Netflix")], for: nil)
        let catalog = ProviderCatalog(repository: repo)
        await catalog.load(region: .spain)

        let prefs = makePrefs(region: .spain)
        prefs.subscribedProviderIDs = [ProviderID(8)]
        let model = StreamingServicesViewModel(catalog: catalog, prefs: prefs)

        #expect(model.hasLoadedAnyCatalog)
        #expect(!model.isInitialLoad)
        #expect(model.selectedProviders.first?.name == "Netflix")
    }

    @Test func isInitialLoadUntilScopedCatalogArrives() async {
        let repo = FakeMovieRepository()
        repo.setProviders([provider(8, "Netflix")], for: .spain)
        repo.setProviders([], for: nil)
        let model = StreamingServicesViewModel(
            catalog: ProviderCatalog(repository: repo),
            prefs: makePrefs(region: .spain)
        )

        #expect(model.isInitialLoad)
        await model.load()
        #expect(!model.isInitialLoad)
    }
}

@MainActor
@Suite struct RegionPickerViewModelTests {

    /// Names that read alike in English and Spanish, so the tests don't depend
    /// on the simulator's language.
    private func makeModel(
        region: Region = .spain,
        repo: FakeMovieRepository = FakeMovieRepository()
    ) -> (RegionPickerViewModel, Preferences) {
        repo.regions = ["IT", "CA", "AR", "ES", "US"].map(Region.init(code:))
        let prefs = makePrefs(region: region)
        return (RegionPickerViewModel(catalog: RegionCatalog(repository: repo), prefs: prefs), prefs)
    }

    @Test func failedLoadShowsTheErrorUntilARetrySucceeds() async {
        let repo = FakeMovieRepository()
        repo.regionsFailure = .offline
        let (model, _) = makeModel(repo: repo)

        await model.load()
        #expect(model.loadError == .offline)
        #expect(!model.isInitialLoad)

        repo.regionsFailure = nil
        await model.load()
        #expect(model.loadError == nil)
        #expect(model.matchingRegions.count == 5)
    }

    /// The model outlives the pushed picker: picking a region must not leave
    /// the next visit filtered.
    @Test func selectingClearsTheSearch() async {
        let (model, _) = makeModel()
        await model.load()

        model.searchText = "ita"
        model.select(Region(code: "IT"))

        #expect(model.searchText.isEmpty)
        #expect(model.showsSelectedRegion)
    }

    @Test func isInitialLoadUntilTheListArrives() async {
        let (model, _) = makeModel()

        #expect(model.isInitialLoad)
        #expect(model.matchingRegions.isEmpty)
        await model.load()
        #expect(!model.isInitialLoad)
        #expect(model.loadError == nil)
        #expect(model.matchingRegions.count == 5)
    }

    @Test func searchMatchesNamesIgnoringCaseAndAccents() async {
        let (model, _) = makeModel()
        await model.load()

        model.searchText = "ital"
        #expect(model.matchingRegions == [Region(code: "IT")])
        // "Canadá" in Spanish.
        model.searchText = "CANADA"
        #expect(model.matchingRegions == [Region(code: "CA")])
    }

    @Test func searchMatchesAnExactCountryCode() async {
        let (model, _) = makeModel()
        await model.load()

        model.searchText = "us"
        #expect(model.matchingRegions.contains(.unitedStates))
    }

    @Test func selectedRegionIsPinnedOnlyWithoutSearch() async {
        let (model, _) = makeModel()
        await model.load()

        #expect(model.showsSelectedRegion)
        model.searchText = "ar"
        #expect(!model.showsSelectedRegion)
    }

    @Test func selectingSetsTheHomeRegion() async {
        let (model, prefs) = makeModel()
        await model.load()

        model.select(Region(code: "AR"))

        #expect(prefs.region == Region(code: "AR"))
        #expect(model.selectedRegion == Region(code: "AR"))
    }
}
