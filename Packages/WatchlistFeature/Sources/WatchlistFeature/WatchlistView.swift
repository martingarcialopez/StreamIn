//
//  WatchlistView.swift
//  WatchlistFeature
//
//  The Watchlist tab's first screen: saved movies, newest first, each with
//  where you can watch it now (the same line as a search result). A row
//  pushes its `Movie`, so Details opens complete from the saved snapshot;
//  swiping a row removes it.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem
import Watchlist

public struct WatchlistView: View {

    /// Passed in, not owned: the model keeps no state of its own (the shared
    /// `WatchlistStore` does), and the app builds it once.
    let model: WatchlistViewModel

    public init(model: WatchlistViewModel) {
        self.model = model
    }

    public var body: some View {
        // The List stays on screen in every state, with the empty and error
        // states overlaid, so the large title keeps one scroll view.
        List {
            ForEach(model.items) { item in
                NavigationLink(value: item.movie) {
                    WatchlistRow(item: item, model: model)
                }
                .listRowBackground(AppPalette.secondaryBackground)
            }
            .onDelete { offsets in
                // Offsets to IDs now, before the Task lets the list change.
                let ids = model.ids(atOffsets: offsets)
                Task { await model.remove(ids) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppPalette.background)
        // Asks again for every row: answers can change while the app stays
        // in memory, and failed rows get retried.
        .refreshable { await model.loadAvailability(refetchingLoaded: true) }
        .overlay {
            WatchlistStatus(model: model)
        }
        .navigationTitle(Text(.watchlistTitle))
        .task {
            await model.load()
        }
        // Fires once the saved movies load, when one is added or removed,
        // and on a region change; each run fetches only what's missing.
        .task(id: model.availabilityTrigger) {
            await model.loadAvailability()
        }
    }
}

private struct WatchlistStatus: View {
    let model: WatchlistViewModel

    var body: some View {
        // A failed load can still leave rows on screen (a heart saved while
        // retries kept failing); the overlay would draw over them.
        if model.loadError != nil && model.items.isEmpty {
            StatusMessage(
                symbol: Symbol.exclamationmarkTriangle,
                tint: .secondary,
                title: .watchlistLoadFailedTitle,
                message: .watchlistLoadFailedDescription
            ) {
                Button(.watchlistRetry) {
                    Task { await model.retry() }
                }
                .buttonStyle(.bordered)
            }
        } else if model.isLoaded && model.items.isEmpty {
            StatusMessage(
                symbol: Symbol.heartFill,
                tint: AppPalette.accent,
                title: .watchlistEmptyTitle,
                message: .watchlistEmptyDescription
            ) {
                EmptyView()
            }
        }
    }
}

/// A large tinted symbol, a semibold headline and a line of help, centered
/// on the page. Scrolls when the text is too large to fit.
private struct StatusMessage<Actions: View>: View {
    let symbol: String
    let tint: AnyShapeStyle
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let actions: Actions

    init(
        symbol: String,
        tint: some ShapeStyle,
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        @ViewBuilder actions: () -> Actions
    ) {
        self.symbol = symbol
        self.tint = AnyShapeStyle(tint)
        self.title = title
        self.message = message
        self.actions = actions()
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            StatusMessageContent(symbol: symbol, tint: tint, title: title, message: message, actions: actions)
            ScrollView {
                StatusMessageContent(symbol: symbol, tint: tint, title: title, message: message, actions: actions)
            }
        }
    }
}

private struct StatusMessageContent<Actions: View>: View {
    let symbol: String
    let tint: AnyShapeStyle
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let actions: Actions

    var body: some View {
        VStack(spacing: Spacing.comfortable) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(tint)
                .padding(.bottom, Spacing.tight)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            actions
                .padding(.top, Spacing.default)
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity)
    }
}

/// Poster, title, year, directors and where to watch it, read by VoiceOver
/// as one element. At accessibility text sizes the poster moves above the
/// text so the title keeps the row's full width.
private struct WatchlistRow: View {
    let item: WatchlistItem
    let model: WatchlistViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.comfortable))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.comfortable))

        layout {
            MoviePoster(url: model.posterURL(for: item))

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(item.movie.title)
                    .font(.headline)
                    .lineLimit(isLarge ? nil : 2)

                if let year = model.year(for: item) {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let directors = model.directorsLine(for: item) {
                    Text(directors)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isLarge ? nil : 2)
                }

                ProviderLine(
                    model.rowProviders(for: item).lineContent,
                    logoURL: model.providerLogoURL,
                    name: \.name
                )
                .padding(.top, Spacing.tight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.tight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel(for: item))
    }
}

// MARK: - Preview

#Preview("Empty") {
    previewWatchlist("empty", PreviewWatchlistRepository())
}

#Preview("Empty, dark") {
    previewWatchlist("empty-dark", PreviewWatchlistRepository())
        .preferredColorScheme(.dark)
}

#Preview("Empty, accessibility size") {
    previewWatchlist("empty-large", PreviewWatchlistRepository())
        .dynamicTypeSize(.accessibility3)
}

#Preview("Filled") {
    previewWatchlist("filled", PreviewWatchlistRepository(items: PreviewWatchlistRepository.sample))
}

#Preview("Filled, dark") {
    previewWatchlist("filled-dark", PreviewWatchlistRepository(items: PreviewWatchlistRepository.sample))
        .preferredColorScheme(.dark)
}

#Preview("Filled, accessibility size") {
    previewWatchlist("filled-large", PreviewWatchlistRepository(items: PreviewWatchlistRepository.sample))
        .dynamicTypeSize(.accessibility3)
}

#Preview("Load failed") {
    previewWatchlist("failed", PreviewWatchlistRepository(loadError: .loadFailed))
}

#Preview("Load failed, dark") {
    previewWatchlist("failed-dark", PreviewWatchlistRepository(loadError: .loadFailed))
        .preferredColorScheme(.dark)
}

/// From Spain, subscribed to Netflix, Prime Video, HBO Max and Disney+. Each
/// preview gets its own defaults suite so previews don't share state.
@MainActor
private func previewWatchlist(_ name: String, _ repository: PreviewWatchlistRepository) -> some View {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "WatchlistView.preview.\(name)")!)
    prefs.region = .spain
    prefs.subscribedProviderIDs = Set([WatchProvider.netflix, .primeVideo, .hboMax, .disneyPlus].map(\.id))
    return NavigationStack {
        WatchlistView(
            model: WatchlistViewModel(
                store: WatchlistStore(repository: repository),
                repository: PreviewMovieRepository(),
                imageURLBuilder: PreviewImageURLBuilder(),
                prefs: prefs
            )
        )
    }
}

/// Complete, so swipe to delete works in a live preview. `load()` runs in
/// the preview too (`.task` fires).
private actor PreviewWatchlistRepository: WatchlistRepository {
    private var saved: [WatchlistItem]
    private let loadError: WatchlistError?

    init(items: [WatchlistItem] = [], loadError: WatchlistError? = nil) {
        saved = items
        self.loadError = loadError
    }

    func items() throws(WatchlistError) -> [WatchlistItem] {
        if let loadError { throw loadError }
        return saved.sorted { $0.addedAt > $1.addedAt }
    }

    func save(_ item: WatchlistItem) throws(WatchlistError) {
        saved.removeAll { $0.id == item.id }
        saved.append(item)
    }

    func remove(_ id: MovieID) throws(WatchlistError) {
        saved.removeAll { $0.id == id }
    }

    /// One movie per row state, in `PreviewMovieRepository.availability`'s
    /// order.
    static let sample: [WatchlistItem] = [
        item(1, "The Lord of the Rings: The Fellowship of the Ring", year: 2001, directors: ["Peter Jackson"]),
        item(2, "Peter Pan & Wendy", year: 2023, directors: ["David Lowery"]),
        item(3, "Peter Pan", year: 2003, directors: ["P.J. Hogan"]),
        item(4, "Peter Pan", year: 1953, directors: ["Clyde Geronimi", "Hamilton Luske", "Wilfred Jackson"]),
        item(5, "No Country for Old Men", year: 2007, directors: ["Joel Coen", "Ethan Coen"]),
        item(6, "Past Lives", year: 2023, directors: ["Celine Song"]),
        item(7, "Untitled", year: nil, directors: []),
    ]

    private static func item(_ id: Int, _ title: String, year: Int?, directors: [String]) -> WatchlistItem {
        let releaseDate = year.flatMap { Calendar.current.date(from: DateComponents(year: $0, month: 6, day: 1)) }
        let movie = Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "",
            releaseDate: releaseDate,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.5,
            runtime: nil,
            directors: directors.enumerated().map { index, name in
                Person(id: PersonID(index), name: name, profilePath: nil)
            }
        )
        return WatchlistItem(movie: movie, addedAt: .now.addingTimeInterval(-Double(id) * 86_400))
    }
}

/// Answers the rows' availability requests; the screen calls nothing else.
private struct PreviewMovieRepository: MovieRepository {
    enum Availability {
        /// `subscription` and `free` at home; `subscription` also counts as
        /// global, at home only.
        case home(subscription: [WatchProvider] = [], free: [WatchProvider] = [])
        case abroad([ProviderRegionalAvailability])
        case fails
        /// Never answers, so the row keeps loading.
        case pending
    }

    private static let availability: [MovieID: Availability] = [
        MovieID(1): .home(subscription: [.netflix, .primeVideo, .hboMax, .disneyPlus, .filmin]),
        MovieID(2): .home(subscription: [.disneyPlus], free: [.rtvePlay]),
        MovieID(3): .abroad([
            ProviderRegionalAvailability(provider: .netflix, regions: [.unitedStates, Region(code: "GB")]),
            ProviderRegionalAvailability(provider: .primeVideo, regions: [Region(code: "JP")]),
        ]),
        MovieID(4): .home(subscription: [.filmin]),
        MovieID(5): .home(),
        MovieID(6): .fails,
        MovieID(7): .pending,
    ]

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        SearchPage(query: query, page: page, totalPages: 1, totalResults: 0, results: [])
    }

    func movie(id: MovieID) async throws -> Movie {
        throw MovieError.notFound
    }

    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try await availabilities(for: id, in: region).regional
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        let subscription: [WatchProvider]
        var free: [WatchProvider] = []
        let global: [ProviderRegionalAvailability]
        switch Self.availability[id] ?? .home() {
        case .home(let homeSubscription, let homeFree):
            subscription = homeSubscription
            free = homeFree
            global = homeSubscription.map { ProviderRegionalAvailability(provider: $0, regions: [region]) }
        case .abroad(let abroad):
            subscription = []
            global = abroad
        case .fails:
            throw MovieError.timeout
        case .pending:
            try await Task.sleep(for: .seconds(3600))
            throw MovieError.cancelled
        }
        return AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: subscription, rent: [], buy: [], free: free, externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: global)
        )
    }

    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}

private extension WatchProvider {
    static let netflix = preview(8, "Netflix")
    static let primeVideo = preview(119, "Prime Video")
    static let disneyPlus = preview(337, "Disney Plus")
    static let hboMax = preview(1899, "HBO Max")
    static let filmin = preview(63, "Filmin")
    static let rtvePlay = preview(541, "RTVE Play")

    static func preview(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
    }
}
