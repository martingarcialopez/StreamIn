//
//  WatchlistView.swift
//  WatchlistFeature
//
//  The Watchlist tab's first screen: saved movies, newest first. A row
//  pushes its `Movie`, so Details opens complete from the saved snapshot;
//  swiping a row removes it.
//

import SwiftUI
import Domain
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
            }
            .onDelete { offsets in
                // Offsets to IDs now, before the Task lets the list change.
                let ids = model.ids(atOffsets: offsets)
                Task { await model.remove(ids) }
            }
            .cinemaRow()
        }
        .overlay {
            WatchlistStatus(model: model)
        }
        .navigationTitle(Text(.watchlistTitle))
        .task {
            await model.load()
        }
    }
}

private struct WatchlistStatus: View {
    let model: WatchlistViewModel

    var body: some View {
        // A failed load can still leave rows on screen (a heart saved while
        // retries kept failing); the overlay would draw over them.
        if model.loadError != nil && model.items.isEmpty {
            ContentUnavailableView {
                Label { Text(.watchlistLoadFailedTitle) } icon: { Image(systemName: Symbol.exclamationmarkTriangle) }
            } description: {
                Text(.watchlistLoadFailedDescription)
            } actions: {
                Button(.watchlistRetry) {
                    Task { await model.retry() }
                }
            }
        } else if model.isLoaded && model.items.isEmpty {
            ContentUnavailableView {
                Label { Text(.watchlistEmptyTitle) } icon: { Image(systemName: Symbol.heart) }
            } description: {
                Text(.watchlistEmptyDescription)
            }
        }
    }
}

private struct WatchlistRow: View {
    let item: WatchlistItem
    let model: WatchlistViewModel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.comfortable) {
            MoviePoster(url: model.posterURL(for: item))

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(item.movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let year = model.year(for: item) {
                    Text(year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let directors = model.directorsLine(for: item) {
                    Text(directors)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.tight)
    }
}

// MARK: - Preview

#Preview("Empty") {
    previewWatchlist(PreviewWatchlistRepository())
}

#Preview("Filled") {
    previewWatchlist(PreviewWatchlistRepository(items: PreviewWatchlistRepository.sample))
}

#Preview("Load failed") {
    previewWatchlist(PreviewWatchlistRepository(loadError: .loadFailed))
}

@MainActor
private func previewWatchlist(_ repository: PreviewWatchlistRepository) -> some View {
    NavigationStack {
        WatchlistView(
            model: WatchlistViewModel(
                store: WatchlistStore(repository: repository),
                imageURLBuilder: PreviewImageURLBuilder()
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

    static let sample: [WatchlistItem] = [
        item(1, "Cloud Atlas", year: 2012, directors: ["Lana Wachowski", "Lilly Wachowski", "Tom Tykwer"], daysAgo: 0),
        item(2, "No Country for Old Men", year: 2007, directors: ["Joel Coen", "Ethan Coen"], daysAgo: 1),
        item(3, "Past Lives", year: 2023, directors: ["Celine Song"], daysAgo: 2),
        item(4, "Untitled", year: nil, directors: [], daysAgo: 3),
    ]

    private static func item(_ id: Int, _ title: String, year: Int?, directors: [String], daysAgo: Int) -> WatchlistItem {
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
        return WatchlistItem(movie: movie, addedAt: .now.addingTimeInterval(-Double(daysAgo) * 86_400))
    }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
