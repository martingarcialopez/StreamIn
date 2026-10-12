import Foundation
import os

/// Answers every request of a session with a canned status and body, and
/// records the last request it saw. The state is global (URLSession
/// instantiates the class), so suites using it must be `.serialized`.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private struct State: Sendable {
        var statusCode = 200
        var body = Data()
        var lastRequest: URLRequest?
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static var lastRequest: URLRequest? {
        state.withLock { $0.lastRequest }
    }

    static func respond(statusCode: Int = 200, body: String = "{}") {
        state.withLock {
            $0.statusCode = statusCode
            $0.body = Data(body.utf8)
        }
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    /// A session whose requests never leave the process.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let snapshot = Self.state.withLock { state -> State in
            state.lastRequest = request
            return state
        }
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: snapshot.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: snapshot.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
