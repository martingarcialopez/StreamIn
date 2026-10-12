public struct TMDBWatchProvidersResponse: Decodable, Sendable {
    public let id: Int
    /// Keyed by ISO country code: "US", "ES", ...
    public let results: [String: TMDBWatchProvidersRegionDTO]
}
