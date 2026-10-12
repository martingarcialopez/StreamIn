import Foundation
import Domain

/// In-memory repository whose failures and timing are set by the test.
actor FakeWatchlistRepository: WatchlistRepository {
    private(set) var stored: [WatchlistItem]
    private(set) var loadCount = 0
    /// Writes in the order they reached the repository, e.g. "save 1", "remove 1".
    private(set) var writes: [String] = []

    var loadError: WatchlistError?
    var saveError: WatchlistError?
    var removeError: WatchlistError?
    /// Slows saves down, so a later write would overtake an unqueued one.
    var saveDelay: Duration = .zero

    private var holdsLoads = false
    private var heldLoads: [CheckedContinuation<Void, Never>] = []

    init(stored: [WatchlistItem] = []) {
        self.stored = stored
    }

    func set(loadError: WatchlistError?) { self.loadError = loadError }
    func set(saveError: WatchlistError?) { self.saveError = saveError }
    func set(removeError: WatchlistError?) { self.removeError = removeError }
    func set(saveDelay: Duration) { self.saveDelay = saveDelay }

    /// Makes `items()` wait until `releaseLoad()`.
    func holdLoads() { holdsLoads = true }
    var isHoldingLoad: Bool { !heldLoads.isEmpty }
    func releaseLoad() {
        holdsLoads = false
        heldLoads.forEach { $0.resume() }
        heldLoads = []
    }

    /// Reads `stored` when called, like a real fetch: writes that land while
    /// the load is held aren't in its result.
    func items() async throws(WatchlistError) -> [WatchlistItem] {
        loadCount += 1
        let snapshot = stored.sorted { $0.addedAt > $1.addedAt }
        let error = loadError
        if holdsLoads {
            await withCheckedContinuation { heldLoads.append($0) }
        }
        if let error { throw error }
        return snapshot
    }

    func save(_ item: WatchlistItem) async throws(WatchlistError) {
        if saveDelay > .zero {
            try? await Task.sleep(for: saveDelay)
        }
        writes.append("save \(item.id.rawValue)")
        if let saveError { throw saveError }
        stored.removeAll { $0.id == item.id }
        stored.append(item)
    }

    func remove(_ id: MovieID) async throws(WatchlistError) {
        writes.append("remove \(id.rawValue)")
        if let removeError { throw removeError }
        stored.removeAll { $0.id == id }
    }
}
