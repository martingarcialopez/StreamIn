import Testing
import Foundation
import Synchronization
import Domain
@testable import TMDBClient

// MARK: - Test doubles

/// Upstream repository that records every call it receives.
private actor RecordingMovieRepository: MovieRepository {
    private(set) var searchCalls = 0
    private(set) var movieCalls = 0
    private(set) var trendingCalls = 0
    private(set) var availabilitiesCalls = 0
    private(set) var allProvidersCalls = 0
    private var shouldFailNextSearch = false

    func failNextSearch() { shouldFailNextSearch = true }

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        searchCalls += 1
        if shouldFailNextSearch {
            shouldFailNextSearch = false
            throw MovieError.offline
        }
        return SearchPage(query: query, page: page, totalPages: 1, totalResults: 0, results: [])
    }

    func movie(id: MovieID) async throws -> Movie {
        movieCalls += 1
        return .fixture(id: id.rawValue)
    }

    func trendingMovies() async throws -> [Movie] {
        trendingCalls += 1
        return [.fixture(id: 1), .fixture(id: 2)]
    }

    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        Issue.record("The decorator should serve availability from the bundle")
        throw MovieError.unknown
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        availabilitiesCalls += 1
        return AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: [], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: [])
        )
    }

    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        allProvidersCalls += 1
        return []
    }
}

/// Mutable stand-in for the TMDB client's current language.
private final class LanguageSetting: Sendable {
    private let code = Mutex("en-US")

    var current: String { code.withLock { $0 } }

    func set(_ newCode: String) { code.withLock { $0 = newCode } }
}

private extension Movie {
    static func fixture(id: Int) -> Movie {
        Movie(
            id: MovieID(id),
            title: "Movie \(id)",
            originalTitle: "Movie \(id)",
            overview: "",
            releaseDate: nil,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            runtime: nil
        )
    }
}

private func makeRepository(
    upstream: RecordingMovieRepository,
    language: LanguageSetting = LanguageSetting()
) -> CachingMovieRepository {
    CachingMovieRepository(upstream: upstream, currentLanguage: { language.current })
}

// MARK: - Tests

@Suite("CachingMovieRepository")
struct CachingMovieRepositoryTests {

    @Test func repeatedSearchIsServedFromCache() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.searchMovies(query: "Inception", page: 1)
        _ = try await repo.searchMovies(query: "Inception", page: 1)

        #expect(await upstream.searchCalls == 1)
    }

    @Test func searchIgnoresQueryCasing() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.searchMovies(query: "Inception", page: 1)
        _ = try await repo.searchMovies(query: "inception", page: 1)

        #expect(await upstream.searchCalls == 1)
    }

    @Test func differentPagesAreCachedSeparately() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.searchMovies(query: "Inception", page: 1)
        _ = try await repo.searchMovies(query: "Inception", page: 2)

        #expect(await upstream.searchCalls == 2)
    }

    @Test func languageChangeBypassesLocalizedEntries() async throws {
        let upstream = RecordingMovieRepository()
        let language = LanguageSetting()
        let repo = makeRepository(upstream: upstream, language: language)

        _ = try await repo.searchMovies(query: "Inception", page: 1)
        _ = try await repo.movie(id: MovieID(27205))
        language.set("es-ES")
        _ = try await repo.searchMovies(query: "Inception", page: 1)
        _ = try await repo.movie(id: MovieID(27205))

        #expect(await upstream.searchCalls == 2)
        #expect(await upstream.movieCalls == 2)
    }

    @Test func trendingIsCachedPerLanguage() async throws {
        let upstream = RecordingMovieRepository()
        let language = LanguageSetting()
        let repo = makeRepository(upstream: upstream, language: language)

        _ = try await repo.trendingMovies()
        _ = try await repo.trendingMovies()
        #expect(await upstream.trendingCalls == 1)

        language.set("es-ES")
        _ = try await repo.trendingMovies()
        #expect(await upstream.trendingCalls == 2)
    }

    @Test func failedSearchIsRetried() async throws {
        let upstream = RecordingMovieRepository()
        await upstream.failNextSearch()
        let repo = makeRepository(upstream: upstream)

        await #expect(throws: MovieError.offline) {
            try await repo.searchMovies(query: "Inception", page: 1)
        }
        _ = try await repo.searchMovies(query: "Inception", page: 1)

        #expect(await upstream.searchCalls == 2)
    }

    @Test func repeatedMovieDetailIsServedFromCache() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.movie(id: MovieID(27205))
        _ = try await repo.movie(id: MovieID(27205))
        _ = try await repo.movie(id: MovieID(155))

        #expect(await upstream.movieCalls == 2)
    }

    /// The search list asks for `availability`, Details asks for
    /// `availabilities` — both must come from one upstream request.
    @Test func searchRowAndDetailsShareOneAvailabilityRequest() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        let regional = try await repo.availability(for: MovieID(27205), in: .spain)
        let bundle = try await repo.availabilities(for: MovieID(27205), in: .spain)

        #expect(regional == bundle.regional)
        #expect(await upstream.availabilitiesCalls == 1)
    }

    @Test func availabilityIsCachedPerRegion() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.availabilities(for: MovieID(27205), in: .spain)
        _ = try await repo.availabilities(for: MovieID(27205), in: .france)

        #expect(await upstream.availabilitiesCalls == 2)
    }

    @Test func concurrentAvailabilityRequestsShareOneFetch() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        async let row = repo.availability(for: MovieID(27205), in: .spain)
        async let details = repo.availabilities(for: MovieID(27205), in: .spain)
        _ = try await (row, details)

        #expect(await upstream.availabilitiesCalls == 1)
    }

    @Test func providerListIsNotCached() async throws {
        let upstream = RecordingMovieRepository()
        let repo = makeRepository(upstream: upstream)

        _ = try await repo.allProviders(in: nil)
        _ = try await repo.allProviders(in: nil)

        #expect(await upstream.allProvidersCalls == 2)
    }
}
