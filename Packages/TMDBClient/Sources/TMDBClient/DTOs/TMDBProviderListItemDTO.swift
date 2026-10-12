public struct TMDBProviderListItemDTO: Decodable, Sendable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?
    /// Aggregate priority TMDB uses when no region filter is applied.
    public let displayPriority: Int

    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }
}
