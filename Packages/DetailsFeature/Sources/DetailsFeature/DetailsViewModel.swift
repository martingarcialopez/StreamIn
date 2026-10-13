//
//  DetailsViewModel.swift
//  DetailsFeature
//
//  Owns the state for one movie's detail screen: the movie itself (initially the
//  summary passed in from search, then enriched with full detail), its
//  region-specific watch availability, and its cross-region availability, which
//  together decide the "Where to watch" card's verdict.
//

import Foundation
import Domain
import Preferences
import Watchlist

@Observable
@MainActor
public final class DetailsViewModel {

    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    private let prefs: Preferences
    private let watchlist: WatchlistStore

    /// Starts with the summary that the search screen already had (so the title,
    /// year, and poster render instantly), then gets replaced by the richer
    /// detail object once `load()` completes.
    private(set) var movie: Movie
    private(set) var availability: WatchAvailability?
    private(set) var globalAvailability: GlobalWatchAvailability?
    private(set) var error: MovieError?

    public init(
        movie: Movie,
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder,
        prefs: Preferences,
        watchlist: WatchlistStore
    ) {
        self.movie = movie
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        self.prefs = prefs
        self.watchlist = watchlist
    }

    /// Fetches full detail and the combined regional+global availability bundle
    /// in parallel via `async let`. The bundle comes from a single TMDB
    /// `/movie/{id}/watch/providers` call — earlier the regional and global
    /// views fanned out as two identical requests, which Proxyman cheerfully
    /// flagged. `MovieRepository.availabilities(...)` collapses them.
    ///
    /// If either task throws, the other is cancelled (Swift's structured
    /// concurrency guarantee). The whole load is cheap-failure: the
    /// previously-rendered summary stays on screen, and the error state
    /// surfaces for the user to retry.
    ///
    /// Region is passed per-call so a runtime change in Settings flows through
    /// to the next reload without rebuilding the view model. A cancelled run
    /// (superseded by that reload, or the screen went away) writes nothing:
    /// the run that replaced it owns the state.
    public func load(region: Region) async {
        error = nil
        do {
            async let detailTask = repository.movie(id: movie.id)
            async let bundleTask = repository.availabilities(for: movie.id, in: region)
            let (detail, bundle) = try await (detailTask, bundleTask)
            guard !Task.isCancelled else { return }
            movie = detail
            availability = bundle.regional
            globalAvailability = bundle.global
            // A heart tapped before the detail arrived saved the summary
            // (no directors, no runtime); store the full movie instead.
            await watchlist.refresh(detail)
        } catch {
            guard !Task.isCancelled else { return }
            self.error = (error as? MovieError) ?? .unknown
        }
    }

    // MARK: - Watchlist

    /// Whether the heart is filled. Read from the shared store, so it follows
    /// changes made from the Watchlist tab too.
    public var isSaved: Bool {
        watchlist.contains(movie.id)
    }

    /// Saves the movie as currently shown (the full detail once loaded), or
    /// removes it.
    public func toggleWatchlist() async {
        await watchlist.toggle(movie)
    }

    /// Regional providers for the current home region, or `nil` until they
    /// load. After a region change (made from the other tab while Details
    /// stays open), the previous region's list would otherwise sit unlabeled
    /// under "Where to watch" until the reload lands.
    public var homeAvailability: WatchAvailability? {
        availability?.region == homeRegion ? availability : nil
    }

    /// Cross-region availability filtered to the user's subscribed providers.
    /// Pure derivation from `globalAvailability` + `prefs.subscribedProviderIDs`,
    /// so it stays in sync if either side changes between renders.
    public var subscribedAvailability: [ProviderRegionalAvailability] {
        guard let global = globalAvailability else { return [] }
        let subscribed = prefs.subscribedProviderIDs
        return global.subscription.filter { subscribed.contains($0.provider.id) }
    }

    public var homeRegion: Region { prefs.region }

    /// "🇪🇸 Spain"
    public var homeRegionLabel: String {
        "\(homeRegion.flag) \(homeRegion.displayName)"
    }

    /// Free providers in the home region; empty until home availability loads.
    public var homeFreeProviders: [WatchProvider] {
        homeAvailability?.free ?? []
    }

    /// Home-region subscription providers the user hasn't subscribed to and
    /// that aren't free, in TMDB's order; empty until home availability loads.
    public var homeSubscriptionsOthers: [WatchProvider] {
        guard let home = homeAvailability else { return [] }
        let excluded = Set((providersAvailableAtHome + homeFreeProviders).map(\.id))
        return home.subscription.filter { !excluded.contains($0.id) }
    }

    /// The answer the "Where to watch" card leads with. Your services and
    /// free ones at home come first; only without them do your services
    /// abroad matter. Rent and buy aren't shown in v1.
    public var verdict: WhereToWatchVerdict {
        guard homeAvailability != nil else {
            return error.map(WhereToWatchVerdict.failed) ?? .loading
        }
        if !watchNowProviders.isEmpty { return .watchNow }
        guard hasAnySubscriptions else { return .chooseServices }
        return hasProvidersElsewhere ? .abroad : .unavailable
    }

    /// Whether `providersAvailableElsewhere` has anything, without sorting
    /// every region by its localized name: the view reads `verdict` often.
    private var hasProvidersElsewhere: Bool {
        let home = homeRegion
        return subscribedAvailability.contains { entry in entry.regions.contains { $0 != home } }
    }

    /// Your services that carry the film at home, then the free ones.
    public var watchNowProviders: [WatchProvider] {
        var seen = Set<ProviderID>()
        return (providersAvailableAtHome + homeFreeProviders).filter { seen.insert($0.id).inserted }
    }

    /// Free providers carry the verdict without any services picked; the
    /// card then offers the picker in a compact row to unlock the rest.
    public var offersServicePicker: Bool {
        verdict == .watchNow && !hasAnySubscriptions
    }

    /// A reload failed while the home region's earlier results stay on
    /// screen; the error shows below them. With nothing to keep, the failure
    /// is `WhereToWatchVerdict.failed` instead.
    public var reloadError: MovieError? {
        homeAvailability == nil ? nil : error
    }

    public var hasAnySubscriptions: Bool {
        !prefs.subscribedProviderIDs.isEmpty
    }

    /// Subscribed providers that carry this film **in the user's home region**:
    /// the ones the user can watch on without a VPN.
    public var providersAvailableAtHome: [WatchProvider] {
        let home = homeRegion
        return subscribedAvailability
            .filter { $0.regions.contains(home) }
            .map(\.provider)
    }

    /// Subscribed providers + the regions where they carry this film
    /// **outside** the user's home region. Each entry's `regions` leads with
    /// popular VPN locations (`PopularRegions`). Providers whose only region
    /// IS home are excluded (they appear in `providersAvailableAtHome` instead).
    public var providersAvailableElsewhere: [ProviderRegionalAvailability] {
        let home = homeRegion
        return subscribedAvailability.compactMap { entry in
            let others = PopularRegions.sorted(entry.regions.filter { $0 != home })
            guard !others.isEmpty else { return nil }
            return ProviderRegionalAvailability(provider: entry.provider, regions: others)
        }
    }

    public func backdropURL() -> URL? {
        movie.backdropPath.flatMap { imageURLBuilder.url(for: $0, size: .backdrop) }
    }

    public func posterURL() -> URL? {
        movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func providerLogoURL(for provider: WatchProvider) -> URL? {
        provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
    }

    // MARK: - Display strings
    //
    // Formatting lives here (not in the view) so it's unit-testable without
    // standing up a SwiftUI hierarchy. Modern `FormatStyle` API throughout —
    // never `DateFormatter`/`NumberFormatter`/`String(format:)`.

    /// "2010" — the release year, or `nil` if TMDB didn't provide a date.
    public var formattedReleaseYear: String? {
        movie.releaseDate?.formatted(.dateTime.year())
    }

    /// "148 min" — the runtime in whole minutes, or `nil` if not available.
    /// Formatted via `Duration.UnitsFormatStyle` so the unit label localizes
    /// alongside the number ("min" → "мин." in Russian, etc.).
    public var formattedRuntime: String? {
        movie.runtime?.formatted(.units(allowed: [.minutes], width: .abbreviated))
    }

    /// "8.4" — TMDB's vote average to one decimal place. Routed through
    /// `Double.formatted(.number...)` so the locale's decimal separator is
    /// respected (a Spanish user sees "8,4").
    public var formattedVoteAverage: String {
        movie.voteAverage.formatted(.number.precision(.fractionLength(1)))
    }

    /// "Directed by Christopher Nolan" — `nil` if the credits haven't been
    /// loaded yet. The full enrichment lands on `load()`; until then the
    /// summary movie has an empty `directors` array.
    public var formattedDirectors: String? {
        guard !movie.directors.isEmpty else { return nil }
        let names = movie.directors.map(\.name).formatted(.list(type: .and))
        return String(localized: .detailsDirectedBy(names))
    }
}
