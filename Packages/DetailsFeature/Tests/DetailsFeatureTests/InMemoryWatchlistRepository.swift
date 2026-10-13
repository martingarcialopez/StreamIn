import Foundation
import Domain

/// The watchlist behind `makeModel`'s store: plain storage, no failures.
actor InMemoryWatchlistRepository: WatchlistRepository {
    private(set) var stored: [WatchlistItem]

    init(stored: [WatchlistItem] = []) {
        self.stored = stored
    }

    func items() throws(WatchlistError) -> [WatchlistItem] {
        stored.sorted { $0.addedAt > $1.addedAt }
    }

    func save(_ item: WatchlistItem) throws(WatchlistError) {
        stored.removeAll { $0.id == item.id }
        stored.append(item)
    }

    func remove(_ id: MovieID) throws(WatchlistError) {
        stored.removeAll { $0.id == id }
    }
}
