import Testing
import Synchronization
import Domain
@testable import TMDBClient

/// Clock whose "now" only moves when the test says so.
private final class ManualClock: Sendable {
    private let start = ContinuousClock.now
    private let elapsed = Mutex(Duration.zero)

    func advance(by duration: Duration) {
        elapsed.withLock { $0 += duration }
    }

    func now() -> ContinuousClock.Instant {
        start.advanced(by: elapsed.withLock { $0 })
    }
}

/// Counts fetches so tests can tell a cache hit from a miss.
private final class FetchCounter: Sendable {
    private let count = Mutex(0)

    var value: Int { count.withLock { $0 } }

    func fetch(returning result: String) -> @Sendable () async throws -> String {
        { [self] in
            count.withLock { $0 += 1 }
            return result
        }
    }

    func failingFetch(_ error: MovieError) -> @Sendable () async throws -> String {
        { [self] in
            count.withLock { $0 += 1 }
            throw error
        }
    }
}

@Suite("MemoryCache")
struct MemoryCacheTests {

    @Test func secondReadIsServedFromCache() async throws {
        let cache = MemoryCache<String, String>()
        let counter = FetchCounter()

        let first = try await cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        let second = try await cache.value(for: "key", orFetch: counter.fetch(returning: "b"))

        #expect(first == "a")
        #expect(second == "a")
        #expect(counter.value == 1)
    }

    @Test func differentKeysFetchIndependently() async throws {
        let cache = MemoryCache<String, String>()
        let counter = FetchCounter()

        _ = try await cache.value(for: "one", orFetch: counter.fetch(returning: "a"))
        _ = try await cache.value(for: "two", orFetch: counter.fetch(returning: "b"))

        #expect(counter.value == 2)
    }

    @Test func concurrentReadsShareOneFetch() async throws {
        let cache = MemoryCache<String, String>()
        let counter = FetchCounter()

        async let first = cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        async let second = cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        _ = try await (first, second)

        #expect(counter.value == 1)
    }

    @Test func failuresAreNotCached() async throws {
        let cache = MemoryCache<String, String>()
        let counter = FetchCounter()

        await #expect(throws: MovieError.offline) {
            try await cache.value(for: "key", orFetch: counter.failingFetch(.offline))
        }
        let value = try await cache.value(for: "key", orFetch: counter.fetch(returning: "a"))

        #expect(value == "a")
        #expect(counter.value == 2)
    }

    @Test func entryExpiresAfterTimeToLive() async throws {
        let clock = ManualClock()
        let cache = MemoryCache<String, String>(timeToLive: .seconds(60), now: { clock.now() })
        let counter = FetchCounter()

        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        clock.advance(by: .seconds(59))
        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "b"))
        #expect(counter.value == 1)

        clock.advance(by: .seconds(1))
        let refreshed = try await cache.value(for: "key", orFetch: counter.fetch(returning: "b"))
        #expect(refreshed == "b")
        #expect(counter.value == 2)
    }

    @Test func entriesWithoutTimeToLiveNeverExpire() async throws {
        let clock = ManualClock()
        let cache = MemoryCache<String, String>(now: { clock.now() })
        let counter = FetchCounter()

        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        clock.advance(by: .seconds(60 * 60 * 24))
        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "b"))

        #expect(counter.value == 1)
    }

    @Test func removeAllForcesRefetch() async throws {
        let cache = MemoryCache<String, String>()
        let counter = FetchCounter()

        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "a"))
        await cache.removeAll()
        _ = try await cache.value(for: "key", orFetch: counter.fetch(returning: "b"))

        #expect(counter.value == 2)
    }
}
