public struct TMDBMovieDetailDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let releaseDate: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double
    public let runtime: Int?              // minutes
    /// Populated when the request asked for `append_to_response=credits`.
    public let credits: TMDBCreditsDTO?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, credits
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
}
