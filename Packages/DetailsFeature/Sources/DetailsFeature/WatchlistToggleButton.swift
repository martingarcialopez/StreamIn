//
//  WatchlistToggleButton.swift
//  DetailsFeature
//
//  The heart in Details' toolbar: saves the movie to the Watchlist or removes
//  it. Its own file so the toolbar stays out of the way of the body's layout.
//

import SwiftUI
import Domain
import DesignSystem
import Preferences
import Watchlist

struct WatchlistToggleButton: View {
    let model: DetailsViewModel

    var body: some View {
        Button {
            Task { await model.toggleWatchlist() }
        } label: {
            Label {
                Text(model.isSaved ? .detailsWatchlistRemove : .detailsWatchlistAdd)
            } icon: {
                Image(systemName: model.isSaved ? Symbol.heartFill : Symbol.heart)
            }
        }
        .contentTransition(.symbolEffect(.replace))
        .sensoryFeedback(.selection, trigger: model.isSaved)
    }
}

// MARK: - Preview support

extension WatchlistStore {
    /// A store over an in-memory repository holding `saved`, for previews.
    /// It loads on first use, e.g. when Details' `.task` refreshes the movie.
    @MainActor
    static func preview(saving saved: [Movie] = []) -> WatchlistStore {
        WatchlistStore(repository: PreviewWatchlistRepository(
            items: saved.map { WatchlistItem(movie: $0, addedAt: .now) }
        ))
    }
}

/// Complete, so every path a preview can reach works: tapping the heart in
/// a live preview saves and removes.
private actor PreviewWatchlistRepository: WatchlistRepository {
    private var saved: [WatchlistItem]

    init(items: [WatchlistItem]) {
        saved = items
    }

    func items() throws(WatchlistError) -> [WatchlistItem] {
        saved.sorted { $0.addedAt > $1.addedAt }
    }

    func save(_ item: WatchlistItem) throws(WatchlistError) {
        saved.removeAll { $0.id == item.id }
        saved.append(item)
    }

    func remove(_ id: MovieID) throws(WatchlistError) {
        saved.removeAll { $0.id == id }
    }
}

#Preview {
    let movie = Movie(
        id: MovieID(27205), title: "Inception", originalTitle: "Inception", overview: "",
        releaseDate: nil, posterPath: nil, backdropPath: nil, voteAverage: 8.4, runtime: nil
    )
    let store = WatchlistStore.preview(saving: [movie])
    NavigationStack {
        Color.clear
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    WatchlistToggleButton(
                        model: DetailsViewModel(
                            movie: movie,
                            repository: NoMovieRepository(),
                            imageURLBuilder: NoImageURLBuilder(),
                            prefs: Preferences(defaults: UserDefaults(suiteName: "WatchlistToggleButton.preview")!),
                            watchlist: store
                        )
                    )
                }
            }
            .task { await store.load() }
    }
}

/// The button never loads anything; Details' own preview covers loading.
private struct NoMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.notFound }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.notFound }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.notFound }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle { throw MovieError.notFound }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

private struct NoImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
