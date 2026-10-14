//
//  WatchlistStore.swift
//  Watchlist
//
//  The saved movies, shared by Details (the heart) and the Watchlist tab (the
//  list). Built on Domain's `WatchlistRepository`, so neither feature knows
//  about SwiftData.
//
//  Like `ProviderCatalog`, it keeps everything in memory and answers reads
//  synchronously: the heart is right on Details' first frame. Changes show
//  immediately and persist behind them, one write at a time.
//

import Foundation
import Observation
import Domain

@Observable
@MainActor
public final class WatchlistStore {

    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(WatchlistError)
    }

    /// Newest first.
    public private(set) var items: [WatchlistItem] = []
    public private(set) var loadState: LoadState = .idle
    /// The latest add or remove that failed and was rolled back, until the UI
    /// calls `dismissWriteFailure()`. A newer failure replaces it; a later
    /// successful write doesn't clear it, so an alert never vanishes mid-read.
    public private(set) var writeFailure: WatchlistWriteFailure?

    private let repository: WatchlistRepository
    private let now: @Sendable () -> Date
    private var inFlightLoad: Task<Void, Never>?
    /// The last write in the queue. Each write waits for the one before it,
    /// so a fast double tap reaches the repository in the order it was made.
    private var lastWrite: Task<Void, Never>?
    /// What the repository is known to hold for each movie (absent = not
    /// saved): from the last load, updated by every successful write.
    private var confirmed: [MovieID: WatchlistItem] = [:]
    /// Queued or running writes per movie.
    private var pendingWrites: [MovieID: Int] = [:]

    public init(repository: WatchlistRepository, now: @escaping @Sendable () -> Date = { .now }) {
        self.repository = repository
        self.now = now
    }

    // MARK: - Reading

    /// Loads the saved movies. A no-op once loaded; concurrent callers share
    /// one request, and calling again after a failure retries.
    public func load() async {
        if loadState == .loaded { return }
        if let inFlightLoad {
            await inFlightLoad.value
            return
        }
        let task = Task {
            loadState = .loading
            // Writes made after a failed load must land before the retry
            // reads, or the fetched list would drop them from the screen.
            await lastWrite?.value
            do throws(WatchlistError) {
                let loaded = try await repository.items()
                items = loaded
                confirmed = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
                loadState = .loaded
            } catch {
                loadState = .failed(error)
            }
        }
        inFlightLoad = task
        await task.value
        inFlightLoad = nil
    }

    /// Linear, which is fine for a personal watchlist.
    public func contains(_ id: MovieID) -> Bool {
        items.contains { $0.id == id }
    }

    // MARK: - Writing
    //
    // Every write waits for the initial load first, so a heart tapped during
    // launch isn't wiped out when the load lands.

    public func add(_ movie: Movie) async {
        await load()
        guard !contains(movie.id) else { return }
        let item = WatchlistItem(movie: movie, addedAt: now())
        show(item, for: item.id)
        await persist(item, for: item.id, reporting: (.add, movie)) { [repository] () async throws(WatchlistError) in
            try await repository.save(item)
        }
    }

    public func remove(_ id: MovieID) async {
        await load()
        guard let current = items.first(where: { $0.id == id }) else { return }
        show(nil, for: id)
        await persist(nil, for: id, reporting: (.remove, current.movie)) { [repository] () async throws(WatchlistError) in
            try await repository.remove(id)
        }
    }

    public func toggle(_ movie: Movie) async {
        await load()
        if contains(movie.id) {
            await remove(movie.id)
        } else {
            await add(movie)
        }
    }

    /// Replaces a saved movie's snapshot with fresher data (e.g. the detail
    /// Details just loaded), keeping when it was added. Does nothing for a
    /// movie that isn't saved, or when nothing changed.
    public func refresh(_ movie: Movie) async {
        await load()
        guard let current = items.first(where: { $0.id == movie.id }),
              current.movie != movie else { return }
        let updated = WatchlistItem(movie: movie, addedAt: current.addedAt)
        show(updated, for: updated.id)
        // Not reported: the user didn't ask for this write, and on failure the
        // earlier snapshot is still a good one.
        await persist(updated, for: updated.id, reporting: nil) { [repository] () async throws(WatchlistError) in
            try await repository.save(updated)
        }
    }

    /// Called once the UI has shown `writeFailure`.
    public func dismissWriteFailure() {
        writeFailure = nil
    }

    // MARK: - Private

    /// Queues `write`, which makes the repository hold `state` for `id`.
    /// A failure becomes `writeFailure` when `change` is given.
    ///
    /// On failure the screen goes back to what the repository is known to
    /// hold for `id` — unless a later write for the same movie is still
    /// queued, in which case that write's outcome decides. Undoing only the
    /// failed change instead would let two failing writes leave the screen
    /// showing the opposite of what's stored.
    private func persist(
        _ state: WatchlistItem?,
        for id: MovieID,
        reporting change: (WatchlistWriteFailure.Change, Movie)?,
        _ write: @escaping @Sendable () async throws(WatchlistError) -> Void
    ) async {
        pendingWrites[id, default: 0] += 1
        let previous = lastWrite
        let task = Task {
            await previous?.value
            do throws(WatchlistError) {
                try await write()
                confirmed[id] = state
            } catch {
                if case let (kind, movie)? = change {
                    writeFailure = WatchlistWriteFailure(change: kind, movie: movie, error: error)
                }
                if pendingWrites[id] == 1 {
                    show(confirmed[id], for: id)
                }
            }
            pendingWrites[id, default: 1] -= 1
            if pendingWrites[id] == 0 { pendingWrites[id] = nil }
        }
        lastWrite = task
        await task.value
    }

    /// Puts `item` on screen for `id`, in date order, or removes it when nil.
    private func show(_ item: WatchlistItem?, for id: MovieID) {
        items.removeAll { $0.id == id }
        guard let item else { return }
        let index = items.firstIndex { $0.addedAt < item.addedAt } ?? items.endIndex
        items.insert(item, at: index)
    }
}
