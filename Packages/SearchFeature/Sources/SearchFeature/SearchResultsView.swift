//
//  SearchResultsView.swift
//  SearchFeature
//
//  Pushed onto the SearchTab's NavigationStack when the user submits a
//  query from `LandingView`. Hosts the actual search experience —
//  `.searchable()` for further refinement, results list, error / empty
//  states, and re-runs the query when the region or language changes.
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
        SearchContent(model: model, onRetry: retry)
            .navigationTitle(Text(.searchTitle))
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

    var body: some View {
        List(model.results) { movie in
            NavigationLink(value: movie) {
                SearchResultRow(movie: movie, model: model)
            }
        }
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
        VStack(spacing: 12) {
            Text(error.userMessage)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button(.searchRetry, action: onRetry)
        }
        .padding()
    }
}

private struct SearchResultRow: View {
    let movie: Movie
    let model: SearchViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoviePoster(url: model.posterURL(for: movie))

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let date = movie.releaseDate {
                    Text(date.formatted(.dateTime.year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProviderStrip(movie: movie, model: model)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct ProviderStrip: View {
    let movie: Movie
    let model: SearchViewModel

    @ScaledMetric(relativeTo: .caption) private var logoSize: CGFloat = LogoSize.medium

    var body: some View {
        if let availability = model.availability[movie.id] {
            if availability.subscription.isEmpty {
                Text(.searchNoStreamingInRegion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(availability.subscription.prefix(5)) { provider in
                        ProviderLogo(
                            url: model.providerLogoURL(for: provider),
                            providerName: provider.name,
                            size: logoSize
                        )
                    }
                }
            }
        } else {
            ProgressView()
                .controlSize(.mini)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchResultsView(
            model: SearchViewModel(
                repository: PreviewMovieRepository(),
                imageURLBuilder: PreviewImageURLBuilder()
            ),
            initialQuery: "Inception"
        )
        .environment(Preferences())
    }
}

private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        SearchPage(
            query: query,
            page: 1,
            totalPages: 1,
            totalResults: 1,
            results: [
                Movie(
                    id: MovieID(27205),
                    title: "Inception",
                    originalTitle: "Inception",
                    overview: "A thief who steals corporate secrets through dream-sharing technology…",
                    releaseDate: nil,
                    posterPath: nil,
                    backdropPath: nil,
                    voteAverage: 8.4,
                    runtime: nil
                )
            ]
        )
    }
    func movie(id: MovieID) async throws -> Movie {
        fatalError("not used in preview")
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        WatchAvailability(
            movieID: id,
            region: region,
            subscription: [],
            rent: [],
            buy: [],
            free: [],
            externalLink: nil
        )
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: [], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: [])
        )
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
