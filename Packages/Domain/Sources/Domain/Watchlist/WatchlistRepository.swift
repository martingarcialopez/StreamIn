//
//  WatchlistRepository.swift
//  Domain
//
//  The seam for saved movies. Features see this protocol (through
//  `WatchlistStore`); the SwiftData implementation lives in Persistence.
//

/// Kept as small as `MovieRepository`: there's no `contains`, because the
/// store holds every item in memory and answers that synchronously.
public protocol WatchlistRepository: Sendable {
    /// Every saved item, newest first.
    func items() async throws(WatchlistError) -> [WatchlistItem]

    /// Inserts the item, or replaces the saved one with the same movie ID.
    func save(_ item: WatchlistItem) async throws(WatchlistError)

    /// Removes the item for `id`. Removing a movie that isn't saved is a no-op.
    func remove(_ id: MovieID) async throws(WatchlistError)
}
