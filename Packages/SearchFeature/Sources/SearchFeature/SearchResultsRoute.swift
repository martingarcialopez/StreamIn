public struct SearchResultsRoute: Hashable, Sendable {
    public let query: String

    public init(query: String) {
        self.query = query
    }
}
