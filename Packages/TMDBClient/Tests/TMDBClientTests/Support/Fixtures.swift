import Foundation
@testable import TMDBClient

/// Small DTO builders so each test only spells out what it is about.
enum Fixtures {
    static func movieDTO(
        id: Int = 1,
        title: String = "Title",
        originalTitle: String = "Original Title",
        overview: String = "Overview",
        releaseDate: String? = "2010-07-16",
        posterPath: String? = "/poster.jpg",
        backdropPath: String? = "/backdrop.jpg",
        voteAverage: Double = 8.4
    ) -> TMDBMovieDTO {
        TMDBMovieDTO(
            id: id,
            title: title,
            originalTitle: originalTitle,
            overview: overview,
            releaseDate: releaseDate,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage
        )
    }

    static func detailDTO(
        id: Int = 1,
        title: String = "Title",
        originalTitle: String = "Original Title",
        overview: String = "Overview",
        releaseDate: String? = "2010-07-16",
        posterPath: String? = "/poster.jpg",
        backdropPath: String? = "/backdrop.jpg",
        voteAverage: Double = 8.4,
        runtime: Int? = 148,
        credits: TMDBCreditsDTO? = nil
    ) -> TMDBMovieDetailDTO {
        TMDBMovieDetailDTO(
            id: id,
            title: title,
            originalTitle: originalTitle,
            overview: overview,
            releaseDate: releaseDate,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            runtime: runtime,
            credits: credits
        )
    }

    static func crew(
        id: Int,
        name: String = "Person",
        job: String,
        profilePath: String? = nil
    ) -> TMDBCrewMemberDTO {
        TMDBCrewMemberDTO(id: id, name: name, profilePath: profilePath, job: job, department: "Directing")
    }

    static func searchResponse(
        page: Int = 1,
        totalPages: Int = 1,
        totalResults: Int = 0,
        results: [TMDBMovieDTO] = []
    ) -> TMDBSearchResponse {
        TMDBSearchResponse(page: page, totalPages: totalPages, totalResults: totalResults, results: results)
    }

    /// A stub whose `movieDetails` answers with `dto`.
    static func detailClient(_ dto: TMDBMovieDetailDTO) -> StubTMDBClient {
        let stub = StubTMDBClient()
        stub.movieDetailsResult = .success(dto)
        return stub
    }

    /// A stub whose `searchMovies` answers with `response`.
    static func searchClient(_ response: TMDBSearchResponse) -> StubTMDBClient {
        let stub = StubTMDBClient()
        stub.searchResult = .success(response)
        return stub
    }
}
