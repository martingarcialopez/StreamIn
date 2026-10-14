import Foundation
import Domain

/// In-memory repository whose load can be made to fail by the test.
actor FakeWatchlistRepository: WatchlistRepository {
    private(set) var stored: [WatchlistItem]
    private var loadError: WatchlistError?

    init(stored: [WatchlistItem] = [], loadError: WatchlistError? = nil) {
        self.stored = stored
        self.loadError = loadError
    }

    func set(loadError: WatchlistError?) { self.loadError = loadError }

    func items() throws(WatchlistError) -> [WatchlistItem] {
        if let loadError { throw loadError }
        return stored.sorted { $0.addedAt > $1.addedAt }
    }

    func save(_ item: WatchlistItem) throws(WatchlistError) {
        stored.removeAll { $0.id == item.id }
        stored.append(item)
    }

    func remove(_ id: MovieID) throws(WatchlistError) {
        stored.removeAll { $0.id == id }
    }
}
