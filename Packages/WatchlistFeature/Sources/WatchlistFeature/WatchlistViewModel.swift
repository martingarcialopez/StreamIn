//
//  WatchlistViewModel.swift
//  WatchlistFeature
//
//  The Watchlist tab's view of the shared `WatchlistStore`: the saved movies
//  as rows, each with where you can watch it now, and swipe to delete. The
//  store owns the data, so a heart tapped on Details shows up here without a
//  reload.
//

import Foundation
import Observation
import Domain
import Preferences
import Watchlist

@Observable
@MainActor
public final class WatchlistViewModel {

    private let store: WatchlistStore
    private let repository: MovieRepository
    private let imageURLBuilder: ImageURLBuilder
    private let prefs: Preferences

    public init(
        store: WatchlistStore,
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder,
        prefs: Preferences
    ) {
        self.store = store
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        self.prefs = prefs
    }

    // MARK: - State

    /// Newest first.
    public var items: [WatchlistItem] { store.items }

    /// Set when the saved movies couldn't be read; `retry()` clears it.
    public var loadError: WatchlistError? {
        if case .failed(let error) = store.loadState { error } else { nil }
    }

    /// False until the first load lands, so the empty state doesn't flash
    /// before the saved movies arrive.
    public var isLoaded: Bool { store.loadState == .loaded }

    /// Streaming availability per saved movie, fetched for `availabilityRegion`.
    /// A missing key means "not fetched yet" or, with the ID in
    /// `failedAvailability`, "failed".
    private(set) var availability: [MovieID: AvailabilityBundle] = [:]
    private(set) var failedAvailability: Set<MovieID> = []
    private var availabilityRegion: Region?

    /// What availability depends on: the view reloads it whenever this
    /// changes, so a movie saved on Details gets its line too.
    var availabilityTrigger: AvailabilityTrigger {
        AvailabilityTrigger(region: prefs.region, movieIDs: items.map(\.id))
    }

    struct AvailabilityTrigger: Hashable {
        let region: Region
        let movieIDs: [MovieID]
    }

    // MARK: - Rows

    public func posterURL(for item: WatchlistItem) -> URL? {
        item.movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func providerLogoURL(for provider: WatchProvider) -> URL? {
        provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
    }

    public func year(for item: WatchlistItem) -> String? {
        item.movie.releaseDate?.formatted(.dateTime.year())
    }

    public func directorsLine(for item: WatchlistItem) -> String? {
        WatchlistDirectorsFormatter.line(for: item.movie.directors.map(\.name))
    }

    /// What `item`'s row shows, read live from the user's services so a
    /// change in Settings updates the rows without refetching. Bundles
    /// fetched for another region show as loading until the new ones land.
    func rowProviders(for item: WatchlistItem) -> WatchlistRowProviders {
        guard availabilityRegion == prefs.region else { return .loading }
        guard let bundle = availability[item.id] else {
            return failedAvailability.contains(item.id) ? .failed : .loading
        }
        let options = WatchOptions(bundle: bundle, home: prefs.region, subscribed: prefs.subscribedProviderIDs)
        return .loaded(options.summary)
    }

    /// What VoiceOver reads for the whole row: "Inception, 2010, Christopher
    /// Nolan, On Netflix and Max". Every provider is named, including those
    /// behind "+N".
    func accessibilityLabel(for item: WatchlistItem) -> String {
        let providers = switch rowProviders(for: item) {
        case .loading: String(localized: .watchlistRowCheckingAvailability)
        case .failed: String(localized: .watchlistRowAvailabilityFailed)
        case .loaded(.atHome(let providers)): String(localized: .watchlistRowOnProviders(Self.names(providers)))
        case .loaded(.abroad(let providers)): String(localized: .watchlistRowAbroadProviders(Self.names(providers)))
        case .loaded(.othersAtHome(let providers)): String(localized: .watchlistRowOthersProviders(Self.names(providers)))
        case .loaded(.notStreamingHere): String(localized: .watchlistRowNotStreamingHere)
        }
        return [item.movie.title, year(for: item), directorsLine(for: item), providers]
            .compactMap(\.self)
            .joined(separator: ", ")
    }

    private static func names(_ providers: [WatchProvider]) -> String {
        providers.map(\.name).formatted(.list(type: .and))
    }

    // MARK: - Actions

    /// A no-op once the store has loaded (`RootView` loads it at launch).
    public func load() async {
        await store.load()
    }

    public func retry() async {
        await store.load()
    }

    /// Fetches where to watch every saved movie without an answer for the
    /// home region yet, in parallel: new movies, failed ones, and all of them
    /// after a region change. `refetchingLoaded` (pull to refresh) asks again
    /// for every row, since this model lives as long as the app; each keeps
    /// its answer on screen until the new one lands. The same TMDB request
    /// and cache entry as Search and Details, so a movie seen there costs
    /// nothing here, and a refresh within the cache's lifetime neither.
    public func loadAvailability(refetchingLoaded: Bool = false) async {
        let region = prefs.region
        if region != availabilityRegion {
            availability = [:]
            failedAvailability = []
            availabilityRegion = region
        }
        let ids = items.map(\.id)
        let requested = refetchingLoaded ? ids : ids.filter { availability[$0] == nil }
        // Retried rows show loading again until their answer lands.
        failedAvailability.subtract(requested)
        await withTaskGroup(of: (MovieID, AvailabilityBundle?).self) { group in
            for id in requested {
                group.addTask { [repository] in
                    (id, try? await repository.availabilities(for: id, in: region))
                }
            }
            for await (id, value) in group {
                // The region changed meanwhile; a newer load owns the state.
                guard availabilityRegion == region else { break }
                if let value {
                    availability[id] = value
                } else if !Task.isCancelled {
                    failedAvailability.insert(id)
                }
            }
        }
    }

    /// The movies at `offsets` in `items` right now. Read synchronously where
    /// the offsets come from: once anything else has run on the main actor
    /// (a rolled-back write, say), they may point at other rows.
    public func ids(atOffsets offsets: IndexSet) -> [MovieID] {
        offsets.map { items[$0].id }
    }

    public func remove(atOffsets offsets: IndexSet) async {
        await remove(ids(atOffsets: offsets))
    }

    /// The rows leave the screen at once; a failed write puts its row back
    /// and the app-wide alert says so.
    public func remove(_ ids: [MovieID]) async {
        let store = store
        // Concurrently, so each row goes now rather than after the previous
        // write; the store still persists them one at a time, in order.
        await withTaskGroup { group in
            for id in ids {
                group.addTask { await store.remove(id) }
            }
        }
    }
}
