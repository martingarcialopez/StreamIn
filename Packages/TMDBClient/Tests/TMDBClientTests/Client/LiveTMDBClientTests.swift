import Testing
import Foundation
import Domain
@testable import TMDBClient

// The stub's state is global, so these tests must not run at the same time.
@Suite(.serialized) struct LiveTMDBClientTests {
    private let client: LiveTMDBClient

    init() {
        StubURLProtocol.reset()
        client = LiveTMDBClient(
            config: TMDBConfig(apiKey: "test-key", language: "en-US"),
            session: StubURLProtocol.makeSession()
        )
    }

    private let emptySearch = #"{"page":1,"total_pages":1,"total_results":0,"results":[]}"#
    private let emptyProviders = #"{"id":1,"results":{}}"#

    /// Path and query items of the last request, the latter as a set because
    /// their order isn't guaranteed.
    private func lastRequest() throws -> (path: String, query: Set<URLQueryItem>, request: URLRequest) {
        let request = try #require(StubURLProtocol.lastRequest)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return (components.path, Set(components.queryItems ?? []), request)
    }

    // MARK: Request building

    @Test func searchBuildsRequest() async throws {
        StubURLProtocol.respond(body: emptySearch)
        _ = try await client.searchMovies(query: "inception", page: 2)

        let last = try lastRequest()
        #expect(last.path == "/3/search/movie")
        #expect(last.query == [
            URLQueryItem(name: "query", value: "inception"),
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "api_key", value: "test-key")
        ])
    }

    @Test func movieDetailsBuildsRequest() async throws {
        StubURLProtocol.respond(body: #"{"id":27205,"title":"T","original_title":"T","overview":"","vote_average":1}"#)
        _ = try await client.movieDetails(id: 27205)

        let last = try lastRequest()
        #expect(last.path == "/3/movie/27205")
        #expect(last.query == [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "append_to_response", value: "credits"),
            URLQueryItem(name: "api_key", value: "test-key")
        ])
    }

    @Test func watchProvidersBuildsRequest() async throws {
        StubURLProtocol.respond(body: emptyProviders)
        _ = try await client.watchProviders(movieID: 27205)

        let last = try lastRequest()
        #expect(last.path == "/3/movie/27205/watch/providers")
        #expect(last.query == [URLQueryItem(name: "api_key", value: "test-key")])
    }

    @Test func providerListSendsWatchRegionWhenGiven() async throws {
        StubURLProtocol.respond(body: #"{"results":[]}"#)
        _ = try await client.providerList(watchRegion: "ES")

        let last = try lastRequest()
        #expect(last.path == "/3/watch/providers/movie")
        #expect(last.query.contains(URLQueryItem(name: "watch_region", value: "ES")))
        #expect(last.query.contains(URLQueryItem(name: "api_key", value: "test-key")))
    }

    @Test func providerListOmitsWatchRegionWhenNil() async throws {
        StubURLProtocol.respond(body: #"{"results":[]}"#)
        _ = try await client.providerList(watchRegion: nil)

        let last = try lastRequest()
        #expect(last.path == "/3/watch/providers/movie")
        #expect(!last.query.contains { $0.name == "watch_region" })
    }

    @Test func everyRequestAcceptsJSON() async throws {
        StubURLProtocol.respond(body: emptySearch)
        _ = try await client.searchMovies(query: "x", page: 1)

        let last = try lastRequest()
        #expect(last.request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(last.request.httpMethod == "GET")
    }

    @Test func updateLanguageAppliesToNextRequest() async throws {
        StubURLProtocol.respond(body: emptySearch)
        client.updateLanguage("es-ES")
        _ = try await client.searchMovies(query: "x", page: 1)

        let last = try lastRequest()
        #expect(last.query.contains(URLQueryItem(name: "language", value: "es-ES")))
        #expect(client.language == "es-ES")
    }

    // MARK: Status codes

    @Test(arguments: [
        (401, MovieError.unauthorized),
        (404, MovieError.notFound),
        (429, MovieError.rateLimited),
        (500, MovieError.server),
        (503, MovieError.server),
        (403, MovieError.unknown)
    ])
    func statusCodeMapsToMovieError(status: Int, expected: MovieError) async {
        StubURLProtocol.respond(statusCode: status)
        await #expect(throws: expected) {
            try await client.searchMovies(query: "x", page: 1)
        }
    }

    // MARK: Decoding

    @Test func validJSONDecodes() async throws {
        StubURLProtocol.respond(body: #"{"page":3,"total_pages":9,"total_results":170,"results":[]}"#)
        let response = try await client.searchMovies(query: "x", page: 3)
        #expect(response.page == 3)
        #expect(response.totalPages == 9)
        #expect(response.totalResults == 170)
    }

    @Test func malformedJSONIsDecodingError() async {
        StubURLProtocol.respond(body: "not json")
        await #expect(throws: MovieError.decoding) {
            try await client.searchMovies(query: "x", page: 1)
        }
    }

    @Test func jsonMissingRequiredFieldsIsDecodingError() async {
        StubURLProtocol.respond(body: #"{"page":1}"#)
        await #expect(throws: MovieError.decoding) {
            try await client.searchMovies(query: "x", page: 1)
        }
    }
}
