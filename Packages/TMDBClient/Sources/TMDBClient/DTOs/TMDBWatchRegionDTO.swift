public struct TMDBWatchRegionDTO: Decodable, Sendable {
    /// ISO 3166-1 alpha-2, e.g. "ES".
    public let iso3166_1: String

    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
    }
}
