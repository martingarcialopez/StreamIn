//
//  SearchResultsView.swift
//  SearchFeature
//
//  Pushed onto the SearchTab's NavigationStack when the user submits a
//  query from `LandingView`. Hosts the actual search experience —
//  `.searchable()` for further refinement, results list, error / empty
//  states, and re-runs the query when the region or language changes.
//  Each row's logos follow Details' order: your services and free ones at
//  home, otherwise your services abroad behind a small globe.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem

public struct SearchResultsView: View {

    @State private var model: SearchViewModel
    @State private var searchText: String
    /// The query whose results are shown. Changes only on submit, so text
    /// edited in the field but never submitted isn't searched when the user
    /// comes back from Details.
    @State private var submittedQuery: String
    @Environment(Preferences.self) private var prefs

    public init(model: SearchViewModel, initialQuery: String) {
        _model = State(initialValue: model)
        _searchText = State(initialValue: initialQuery)
        _submittedQuery = State(initialValue: initialQuery)
    }

    public var body: some View {
        SearchContent(model: model, onRetry: retry, onRefresh: search)
            // The search on screen, so the back stack reads as "the results for…".
            .navigationTitle(Text(verbatim: submittedQuery))
            .searchable(text: $searchText, prompt: Text(.searchPrompt))
            .onSubmit(of: .search) {
                if let query = SearchView.sanitize(searchText) {
                    submittedQuery = query
                }
            }
            // Fires on first appearance, on submit, and on region or language
            // changes, cancelling the previous run. It also fires every time
            // this screen reappears (e.g. Details popped); the view model
            // recognises that as the search already on screen and keeps it.
            .task(id: SearchTrigger(query: submittedQuery, settings: prefs.snapshot)) {
                await search()
            }
    }

    private func search() async {
        await model.search(query: submittedQuery, region: prefs.region, language: prefs.language)
    }

    private func retry() {
        Task { await search() }
    }
}

private struct SearchTrigger: Hashable {
    let query: String
    let settings: Preferences.Snapshot
}

// MARK: - Content
//
// The List stays on screen in every state; loading, error and empty states
// are overlaid on it (empty at that point). Swapping a List in after a
// spinner makes the navigation bar attach to a new scroll view, which
// collapses the search field right after it has appeared.

private struct SearchContent: View {
    let model: SearchViewModel
    let onRetry: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List(model.results) { movie in
            NavigationLink(value: movie) {
                SearchResultRow(movie: movie, model: model)
            }
            .cinemaRow()
        }
        .listStyle(.insetGrouped)
        .cinemaBackground()
        // The same search again: keeps the results and retries the rows
        // whose availability failed.
        .refreshable { await onRefresh() }
        .overlay {
            SearchStatus(model: model, onRetry: onRetry)
        }
    }
}

private struct SearchStatus: View {
    let model: SearchViewModel
    let onRetry: () -> Void

    var body: some View {
        if let error = model.error {
            ErrorState(error: error, onRetry: onRetry)
        } else if model.isLoading || !model.hasLoadedResults {
            // `!hasLoadedResults` covers the first frame, before `.task` has
            // started the search — otherwise "No results" flashes on push.
            ProgressView { Text(.searchInProgress) }
        } else if model.results.isEmpty {
            ContentUnavailableView {
                Label { Text(.searchEmptyTitle) } icon: { Image(systemName: Symbol.movieclapper) }
            } description: {
                Text(.searchEmptyState)
            }
        }
    }
}

private struct ErrorState: View {
    let error: MovieError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.comfortable) {
            Text(error.userMessage)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button(.searchRetry, action: onRetry)
        }
        .padding()
    }
}

/// Poster, title, year and the provider line, read by VoiceOver as one
/// element. At accessibility text sizes the poster moves above the text so
/// the title keeps the row's full width.
private struct SearchResultRow: View {
    let movie: Movie
    let model: SearchViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.comfortable))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.comfortable))

        layout {
            MoviePoster(url: model.posterURL(for: movie))

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(isLarge ? nil : 2)

                if let year = model.releaseYear(for: movie) {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProviderLine(providers: model.rowProviders(for: movie), model: model)
                    .padding(.top, Spacing.tight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.tight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel(for: movie))
    }
}

/// Up to three small logos and "+N"; abroad ones follow a globe. Holds the
/// logos' height in every state, so rows don't jump as availability lands.
private struct ProviderLine: View {
    let providers: SearchRowProviders
    let model: SearchViewModel

    @ScaledMetric(relativeTo: .caption) private var logoSize: CGFloat = LogoSize.small

    var body: some View {
        Group {
            switch providers {
            case .loading:
                ProgressView()
                    .controlSize(.mini)
            case .failed:
                RowCaption(text: .searchRowAvailabilityFailed)
            case .atHome(let providers):
                Logos(providers: providers, logoSize: logoSize, model: model)
            case .abroad(let providers):
                HStack(spacing: Spacing.default) {
                    AbroadMark(size: logoSize)
                    Logos(providers: providers, logoSize: logoSize, model: model)
                }
            case .none(.notOnYourServices):
                RowCaption(text: .searchRowNotOnYourServices)
            case .none(.notStreamingHere):
                RowCaption(text: .searchRowNotStreamingHere)
            }
        }
        .frame(minHeight: logoSize, alignment: .leading)
        .animation(.smooth, value: providers)
    }
}

private struct Logos: View {
    let providers: [WatchProvider]
    let logoSize: CGFloat
    let model: SearchViewModel

    var body: some View {
        ProviderLogoStrip(
            providers,
            maxLogos: 3,
            logoSize: logoSize,
            logoURL: model.providerLogoURL,
            name: \.name
        )
    }
}

private struct RowCaption: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    previewResults("loaded", .results)
}

#Preview("Loaded, dark") {
    previewResults("dark", .results)
        .preferredColorScheme(.dark)
}

#Preview("Loaded, accessibility size") {
    previewResults("large", .results)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Searching") {
    previewResults("searching", .searching)
}

#Preview("Searching, dark") {
    previewResults("searching-dark", .searching)
        .preferredColorScheme(.dark)
}

#Preview("No results") {
    previewResults("empty", .empty)
}

#Preview("No results, dark") {
    previewResults("empty-dark", .empty)
        .preferredColorScheme(.dark)
}

#Preview("Search failed") {
    previewResults("error", .failure(.offline))
}

#Preview("Search failed, dark") {
    previewResults("error-dark", .failure(.offline))
        .preferredColorScheme(.dark)
}

/// Searches from Spain, subscribed to Netflix, Prime Video, HBO Max and
/// Disney+. Each preview gets its own defaults suite so previews don't share
/// state.
@MainActor
private func previewResults(_ name: String, _ mode: PreviewMovieRepository.Mode) -> some View {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "SearchResultsView.preview.\(name)")!)
    prefs.region = .spain
    prefs.subscribedProviderIDs = Set([WatchProvider.netflix, .primeVideo, .hboMax, .disneyPlus].map(\.id))
    return NavigationStack {
        SearchResultsView(
            model: SearchViewModel(
                repository: PreviewMovieRepository(mode: mode),
                imageURLBuilder: PreviewImageURLBuilder(),
                prefs: prefs
            ),
            initialQuery: "Peter Pan"
        )
        .environment(prefs)
    }
}

/// The search's `.task` runs in previews too, so every method the screen
/// calls answers. One movie per row state.
private struct PreviewMovieRepository: MovieRepository {
    enum Mode {
        case results
        /// The search never answers.
        case searching
        case empty
        case failure(MovieError)
    }

    let mode: Mode

    private static let rows: [(movie: Movie, availability: Availability)] = [
        (movie(1, "The Lord of the Rings: The Fellowship of the Ring", 2001), .home(
            subscription: [.netflix, .primeVideo, .hboMax, .disneyPlus, .filmin]
        )),
        (movie(2, "Peter Pan & Wendy", 2023), .home(subscription: [.disneyPlus], free: [.rtvePlay])),
        (movie(3, "Pan", 2015), .home(free: [.rtvePlay])),
        (movie(4, "Peter Pan", 2003), .abroad([
            ProviderRegionalAvailability(provider: .netflix, regions: [.unitedStates, Region(code: "GB")]),
            ProviderRegionalAvailability(provider: .primeVideo, regions: [Region(code: "JP")]),
        ])),
        (movie(5, "Peter Pan", 1953), .home(subscription: [.filmin])),
        (movie(6, "Peter Pan: The Quest for the Never Book", 2018), .home()),
        (movie(7, "Hook", 1991), .fails),
        (movie(8, "Finding Neverland", 2004), .pending),
    ]

    enum Availability {
        /// `subscription` and `free` at home; `subscription` also counts as
        /// global, at home only.
        case home(subscription: [WatchProvider] = [], free: [WatchProvider] = [])
        case abroad([ProviderRegionalAvailability])
        case fails
        /// Never answers, so the row keeps loading.
        case pending
    }

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        let results: [Movie]
        switch mode {
        case .results:
            results = Self.rows.map(\.movie)
        case .searching:
            try await Task.sleep(for: .seconds(3600))
            results = []
        case .empty:
            results = []
        case .failure(let error):
            throw error
        }
        return SearchPage(query: query, page: page, totalPages: 1, totalResults: results.count, results: results)
    }

    func movie(id: MovieID) async throws -> Movie {
        try Self.row(id).movie
    }

    func trendingMovies() async throws -> [Movie] {
        fatalError("not used in preview")
    }

    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try await availabilities(for: id, in: region).regional
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        let subscription: [WatchProvider]
        var free: [WatchProvider] = []
        let global: [ProviderRegionalAvailability]
        switch try Self.row(id).availability {
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

    private static func row(_ id: MovieID) throws -> (movie: Movie, availability: Availability) {
        guard let row = rows.first(where: { $0.movie.id == id }) else { throw MovieError.notFound }
        return row
    }

    private static func movie(_ id: Int, _ title: String, _ year: Int) -> Movie {
        Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "",
            releaseDate: DateComponents(calendar: .current, year: year, month: 6, day: 1).date,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7,
            runtime: nil
        )
    }
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
