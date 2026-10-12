public struct TMDBMovieDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let releaseDate: String?       // "YYYY-MM-DD" or sometimes ""
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
}
