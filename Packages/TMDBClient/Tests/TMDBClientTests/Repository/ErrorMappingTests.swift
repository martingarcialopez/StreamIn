import Testing
import Foundation
import Domain
@testable import TMDBClient

@Suite struct ErrorMappingTests {

    /// Runs `searchMovies` against a client that throws `error`.
    private func searchError(from error: Error) async -> Error? {
        let stub = StubTMDBClient()
        stub.searchResult = .failure(error)
        do {
            _ = try await TMDBMovieRepository(client: stub).searchMovies(query: "x", page: 1)
            return nil
        } catch {
            return error
        }
    }

    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, MovieError.offline),
        (.dataNotAllowed, .offline),
        (.timedOut, .timeout),
        (.cancelled, .cancelled),
        (.badServerResponse, .unknown)
    ])
    func urlErrorMapsToMovieError(code: URLError.Code, expected: MovieError) async {
        let mapped = await searchError(from: URLError(code))
        #expect(mapped as? MovieError == expected)
    }

    @Test func cancellationErrorIsCancelled() async {
        let mapped = await searchError(from: CancellationError())
        #expect(mapped as? MovieError == .cancelled)
    }

    @Test func movieErrorPassesThroughUnchanged() async {
        let mapped = await searchError(from: MovieError.rateLimited)
        #expect(mapped as? MovieError == .rateLimited)
    }

    @Test func otherErrorsAreUnknown() async {
        struct Boom: Error {}
        let mapped = await searchError(from: Boom())
        #expect(mapped as? MovieError == .unknown)
    }

    @Test func movieDetailAlsoMapsErrors() async {
        let stub = StubTMDBClient()
        stub.movieDetailsResult = .failure(URLError(.timedOut))
        await #expect(throws: MovieError.timeout) {
            try await TMDBMovieRepository(client: stub).movie(id: MovieID(1))
        }
    }

    @Test func availabilityAlsoMapsErrors() async {
        let stub = StubTMDBClient()
        stub.watchProvidersResult = .failure(URLError(.notConnectedToInternet))
        await #expect(throws: MovieError.offline) {
            try await TMDBMovieRepository(client: stub).availability(for: MovieID(1), in: .spain)
        }
    }

    @Test func availabilitiesAlsoMapsErrors() async {
        let stub = StubTMDBClient()
        stub.watchProvidersResult = .failure(CancellationError())
        await #expect(throws: MovieError.cancelled) {
            try await TMDBMovieRepository(client: stub).availabilities(for: MovieID(1), in: .spain)
        }
    }

    @Test func allProvidersAlsoMapsErrors() async {
        let stub = StubTMDBClient()
        stub.providerListResult = .failure(URLError(.dataNotAllowed))
        await #expect(throws: MovieError.offline) {
            try await TMDBMovieRepository(client: stub).allProviders(in: nil)
        }
    }
}
