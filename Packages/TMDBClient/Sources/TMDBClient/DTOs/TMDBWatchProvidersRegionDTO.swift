public struct TMDBWatchProvidersRegionDTO: Decodable, Sendable {
    public let link: String?
    public let flatrate: [TMDBProviderDTO]?
    public let rent: [TMDBProviderDTO]?
    public let buy: [TMDBProviderDTO]?
    public let free: [TMDBProviderDTO]?
}
