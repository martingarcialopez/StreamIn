//
//  MemoryCache.swift
//  TMDBClient
//
//  Session-lifetime, in-memory response cache with optional expiry.
//
//  Entries hold the *task* producing a value rather than the value itself, so
//  concurrent requests for the same key share one fetch: the search results
//  fan-out and the Details screen asking for the same movie's providers
//  produce a single network call. Failures are never cached.
//

actor MemoryCache<Key: Hashable & Sendable, Value: Sendable> {

    private struct Entry {
        let task: Task<Value, Error>
        let storedAt: ContinuousClock.Instant
    }

    private var entries: [Key: Entry] = [:]
    private let timeToLive: Duration?
    private let now: @Sendable () -> ContinuousClock.Instant

    /// - Parameters:
    ///   - timeToLive: How long an entry stays valid; `nil` keeps it for the
    ///     whole session.
    ///   - now: Clock source, injectable so tests can exercise expiry.
    init(
        timeToLive: Duration? = nil,
        now: @escaping @Sendable () -> ContinuousClock.Instant = { .now }
    ) {
        self.timeToLive = timeToLive
        self.now = now
    }

    /// Returns the cached value for `key`, joining an in-flight fetch if there
    /// is one, or runs `fetch` and caches its result.
    ///
    /// The fetch runs in its own task, so a caller being cancelled (e.g. a
    /// view disappearing) doesn't abort a request other callers are waiting on
    /// — and the result still lands in the cache for the next appearance.
    func value(
        for key: Key,
        orFetch fetch: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        if let entry = entries[key], !isExpired(entry) {
            return try await entry.task.value
        }

        let task = Task { try await fetch() }
        entries[key] = Entry(task: task, storedAt: now())
        do {
            return try await task.value
        } catch {
            // Only evict our own entry: a newer fetch may have replaced it
            // while this one was running.
            if entries[key]?.task == task {
                entries[key] = nil
            }
            throw error
        }
    }

    private func isExpired(_ entry: Entry) -> Bool {
        guard let timeToLive else { return false }
        return now() - entry.storedAt >= timeToLive
    }
}
