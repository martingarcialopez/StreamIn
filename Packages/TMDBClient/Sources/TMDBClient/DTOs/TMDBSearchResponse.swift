// MARK: - DTOs (transport types)
//
// DTOs mirror TMDB's JSON exactly. They are NOT used outside this module.
// This is what protects the rest of the app from TMDB's quirks (dates as
// strings, paths starting with "/", optional fields that are sometimes empty
// strings instead of null).

public struct TMDBSearchResponse: Decodable, Sendable {
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
    public let results: [TMDBMovieDTO]

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
