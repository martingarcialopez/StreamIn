//
//  StreamingServicesViewModel.swift
//  SettingsFeature
//
//  State behind the services picker and the Settings row that summarizes it.
//  Settings, the services sheet and Onboarding each own one.
//

import Observation
import Domain
import Preferences
import ReferenceData

@Observable
@MainActor
public final class StreamingServicesViewModel {

    private let catalog: ProviderCatalog
    private let prefs: Preferences

    /// User-flipped: false = home region, true = worldwide catalog.
    var showWorldwide = false
    var searchText = ""

    public init(catalog: ProviderCatalog, prefs: Preferences) {
        self.catalog = catalog
        self.prefs = prefs
    }

    /// Makes sure the home-region and worldwide catalogs are loaded. Both are
    /// needed: the "Your services" section resolves providers picked via
    /// the worldwide toggle, and flipping the toggle must be instant.
    ///
    /// The app preloads both at launch, so this normally returns immediately;
    /// it matters when that preload failed or the region just changed.
    public func load() async {
        await catalog.load(region: prefs.region)
    }

    // MARK: - Derived

    public var selectedCount: Int {
        prefs.subscribedProviderIDs.count
    }

    /// Selected providers, with metadata resolved from the catalog.
    /// **Not** filtered by `searchText`: the Settings row summary shows them
    /// all. The picker shows `visibleSelectedProviders`.
    public var selectedProviders: [WatchProvider] {
        prefs.subscribedProviderIDs
            .map { id in
                catalog.provider(id: id)
                    ?? WatchProvider(id: id, name: "Provider \(id.rawValue)", logoPath: nil, priority: Int.max)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The picker's "Your services": the selected providers that match the
    /// search, so a search narrows the whole grid.
    public var visibleSelectedProviders: [WatchProvider] {
        selectedProviders.filter(matchesSearch)
    }

    /// A search that matches nothing in either section.
    public var hasNoSearchMatches: Bool {
        !searchText.isEmpty && !isInitialLoad
            && visibleSelectedProviders.isEmpty && availableProviders.isEmpty
    }

    /// True once either catalog has loaded — i.e. the metadata in
    /// `selectedProviders` is real and not the `"Provider <id>"` placeholder.
    /// The Settings row uses this to choose between a count summary and the
    /// icon strip so the user never sees a row of gray placeholder squares.
    public var hasLoadedAnyCatalog: Bool {
        catalog.providers(in: prefs.region) != nil || catalog.providers(in: nil) != nil
    }

    /// The catalog behind the "Available" section hasn't arrived and nothing
    /// has failed yet: show a spinner rather than the empty-state text.
    public var isInitialLoad: Bool {
        scopedCatalog == nil && catalog.lastError == nil
    }

    /// Every service in the current scope is already picked, with no search
    /// narrowing it: "Available" says so instead of standing empty.
    public var hasPickedEveryService: Bool {
        searchText.isEmpty && scopedCatalog != nil && availableProviders.isEmpty
    }

    /// Why the "Available" section has nothing to show, when its catalog
    /// failed to load (e.g. a first launch offline). `load()` retries it.
    public var loadError: MovieError? {
        scopedCatalog == nil ? catalog.lastError : nil
    }

    /// Catalog under the current scope. Excludes already-selected providers
    /// (those live in the "Your services" section above to avoid
    /// duplicated tiles), leaves out free services (the picker is for the ones
    /// you pay for) and applies the search filter.
    public var availableProviders: [WatchProvider] {
        let selectedIDs = prefs.subscribedProviderIDs
        return (scopedCatalog ?? [])
            .filter { !selectedIDs.contains($0.id) && !FreeProviders.contains($0) }
            .filter(matchesSearch)
    }

    private var scopedCatalog: [WatchProvider]? {
        catalog.providers(in: showWorldwide ? nil : prefs.region)
    }

    public func isSubscribed(_ id: ProviderID) -> Bool {
        prefs.subscribedProviderIDs.contains(id)
    }

    public func toggle(_ id: ProviderID) {
        var ids = prefs.subscribedProviderIDs
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        prefs.subscribedProviderIDs = ids
    }

    private func matchesSearch(_ provider: WatchProvider) -> Bool {
        searchText.isEmpty || provider.name.localizedStandardContains(searchText)
    }
}
