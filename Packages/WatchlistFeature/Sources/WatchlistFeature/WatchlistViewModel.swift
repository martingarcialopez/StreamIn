//
//  WatchlistViewModel.swift
//  WatchlistFeature
//
//  The Watchlist tab's view of the shared `WatchlistStore`: the saved movies
//  as rows, and swipe to delete. The store owns the data, so a heart tapped
//  on Details shows up here without a reload.
//

import Foundation
import Observation
import Domain
import Watchlist

@Observable
@MainActor
public final class WatchlistViewModel {

    private let store: WatchlistStore
    private let imageURLBuilder: ImageURLBuilder

    public init(store: WatchlistStore, imageURLBuilder: ImageURLBuilder) {
        self.store = store
        self.imageURLBuilder = imageURLBuilder
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

    // MARK: - Rows

    public func posterURL(for item: WatchlistItem) -> URL? {
        item.movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func year(for item: WatchlistItem) -> String? {
        item.movie.releaseDate?.formatted(.dateTime.year())
    }

    public func directorsLine(for item: WatchlistItem) -> String? {
        WatchlistDirectorsFormatter.line(for: item.movie.directors.map(\.name))
    }

    // MARK: - Actions

    /// A no-op once the store has loaded (`RootView` loads it at launch).
    public func load() async {
        await store.load()
    }

    public func retry() async {
        await store.load()
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
