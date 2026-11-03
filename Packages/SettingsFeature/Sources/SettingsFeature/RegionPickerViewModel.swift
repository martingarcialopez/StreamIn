//
//  RegionPickerViewModel.swift
//  SettingsFeature
//
//  State behind the home-region picker: the region list from `RegionCatalog`,
//  the search filter, and the selection in `Preferences`.
//

import Foundation
import Observation
import Domain
import Preferences
import ReferenceData

@Observable
@MainActor
public final class RegionPickerViewModel {

    private let catalog: RegionCatalog
    private let prefs: Preferences

    var searchText = ""

    public init(catalog: RegionCatalog, prefs: Preferences) {
        self.catalog = catalog
        self.prefs = prefs
    }

    /// Normally a no-op: the app loads the list at launch. It recovers from a
    /// failed launch load.
    public func load() async {
        await catalog.load()
    }

    var selectedRegion: Region {
        prefs.region
    }

    /// No list yet and nothing has failed: show a spinner.
    var isInitialLoad: Bool {
        catalog.regions == nil && catalog.lastError == nil
    }

    /// Why the list couldn't load, while there's no list to show.
    var loadError: MovieError? {
        catalog.regions == nil ? catalog.lastError : nil
    }

    /// The selected region is pinned above the list, except while searching.
    var showsSelectedRegion: Bool {
        searchText.isEmpty
    }

    /// Every region, by name, narrowed by the search: a name containing the
    /// text (ignoring case and accents), or an exact ISO code ("US").
    var matchingRegions: [Region] {
        let regions = catalog.regions ?? []
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return regions }
        return regions.filter { region in
            region.displayName.localizedStandardContains(query)
                || region.code.caseInsensitiveCompare(query) == .orderedSame
        }
    }

    func select(_ region: Region) {
        prefs.region = region
    }
}
