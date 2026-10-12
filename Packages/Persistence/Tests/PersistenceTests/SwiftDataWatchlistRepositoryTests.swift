import Testing
import Foundation
import Domain
@testable import Persistence

@Suite struct SwiftDataWatchlistRepositoryTests {

    @Test func startsEmpty() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        #expect(try await repository.items().isEmpty)
    }

    @Test func savedItemRoundTripsEveryField() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        let item = WatchlistItem(movie: .matrix, addedAt: .at(100))

        try await repository.save(item)

        #expect(try await repository.items() == [item])
    }

    @Test func optionalFieldsRoundTripAsNil() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        let item = WatchlistItem(movie: .bare(id: 7), addedAt: .at(100))

        try await repository.save(item)

        #expect(try await repository.items() == [item])
    }

    @Test func itemsAreNewestFirst() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        try await repository.save(WatchlistItem(movie: .bare(id: 1), addedAt: .at(100)))
        try await repository.save(WatchlistItem(movie: .bare(id: 2), addedAt: .at(300)))
        try await repository.save(WatchlistItem(movie: .bare(id: 3), addedAt: .at(200)))

        let ids = try await repository.items().map(\.id.rawValue)

        #expect(ids == [2, 3, 1])
    }

    @Test func savingTheSameMovieReplacesIt() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        try await repository.save(WatchlistItem(movie: .bare(id: 1, title: "Old"), addedAt: .at(100)))

        let updated = WatchlistItem(movie: .bare(id: 1, title: "New"), addedAt: .at(100))
        try await repository.save(updated)

        #expect(try await repository.items() == [updated])
    }

    @Test func removeDeletesOnlyThatMovie() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        try await repository.save(WatchlistItem(movie: .bare(id: 1), addedAt: .at(100)))
        try await repository.save(WatchlistItem(movie: .bare(id: 2), addedAt: .at(200)))

        try await repository.remove(MovieID(1))

        #expect(try await repository.items().map(\.id) == [MovieID(2)])
    }

    @Test func removingAMovieThatIsNotSavedIsANoOp() async throws {
        let repository = try SwiftDataWatchlistRepository(storage: .inMemory)
        try await repository.save(WatchlistItem(movie: .bare(id: 1), addedAt: .at(100)))

        try await repository.remove(MovieID(99))

        #expect(try await repository.items().count == 1)
    }

    @Test func inMemoryStoresAreSeparate() async throws {
        let first = try SwiftDataWatchlistRepository(storage: .inMemory)
        let second = try SwiftDataWatchlistRepository(storage: .inMemory)

        try await first.save(WatchlistItem(movie: .bare(id: 1), addedAt: .at(100)))

        #expect(try await second.items().isEmpty)
    }

    /// The public way in, as the composition root uses it.
    @Test func factoryBuildsAWorkingRepository() async throws {
        let repository = try WatchlistPersistence.makeRepository(storage: .inMemory)
        let item = WatchlistItem(movie: .matrix, addedAt: .at(100))

        try await repository.save(item)

        #expect(try await repository.items() == [item])
    }

    /// Stands in for a relaunch: a second repository on the same file sees
    /// what the first one saved.
    @Test func savedItemsSurviveANewRepositoryOnTheSameFile() async throws {
        let directory = URL.temporaryDirectory.appending(path: "PersistenceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Watchlist.store")
        let item = WatchlistItem(movie: .matrix, addedAt: .at(100))

        do {
            let repository = try SwiftDataWatchlistRepository(storage: .file(url))
            try await repository.save(item)
        }
        let relaunched = try SwiftDataWatchlistRepository(storage: .file(url))

        #expect(try await relaunched.items() == [item])
    }
}

// MARK: - Fixtures

private extension Date {
    static func at(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }
}

private extension Movie {
    /// Every field set, including two directors whose order must survive.
    static let matrix = Movie(
        id: MovieID(603),
        title: "The Matrix",
        originalTitle: "The Matrix",
        overview: "A hacker learns the truth about his reality.",
        releaseDate: .at(-60_000_000),
        posterPath: ImagePath("/poster.jpg"),
        backdropPath: ImagePath("/backdrop.jpg"),
        voteAverage: 8.2,
        runtime: .seconds(136 * 60),
        directors: [
            Person(id: PersonID(9340), name: "Lana Wachowski", profilePath: ImagePath("/lana.jpg")),
            Person(id: PersonID(9339), name: "Lilly Wachowski", profilePath: nil),
        ]
    )

    /// Only the required fields; every optional is nil and directors are empty.
    static func bare(id: Int, title: String = "Movie") -> Movie {
        Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "",
            releaseDate: nil,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            runtime: nil
        )
    }
}
