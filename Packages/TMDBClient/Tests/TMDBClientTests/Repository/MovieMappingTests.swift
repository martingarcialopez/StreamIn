import Testing
import Foundation
import Domain
@testable import TMDBClient

@Suite struct SearchMappingTests {

    @Test func copiesQueryAndPaging() async throws {
        let stub = Fixtures.searchClient(Fixtures.searchResponse(page: 2, totalPages: 5, totalResults: 93))
        let page = try await TMDBMovieRepository(client: stub).searchMovies(query: "inception", page: 2)

        #expect(page.query == "inception")
        #expect(page.page == 2)
        #expect(page.totalPages == 5)
        #expect(page.totalResults == 93)
        #expect(stub.searchLastQuery == "inception")
        #expect(stub.searchLastPage == 2)
    }

    @Test(arguments: [
        (1, 3, true),
        (2, 3, true),
        (3, 3, false),
        (1, 0, false)
    ])
    func hasMoreOnlyWhenPageBelowTotal(page: Int, totalPages: Int, expected: Bool) async throws {
        let stub = Fixtures.searchClient(Fixtures.searchResponse(page: page, totalPages: totalPages))
        let result = try await TMDBMovieRepository(client: stub).searchMovies(query: "x", page: page)
        #expect(result.hasMore == expected)
    }

    @Test func resultsKeepTheirOrder() async throws {
        let response = Fixtures.searchResponse(results: [
            Fixtures.movieDTO(id: 3), Fixtures.movieDTO(id: 1), Fixtures.movieDTO(id: 2)
        ])
        let page = try await TMDBMovieRepository(client: Fixtures.searchClient(response))
            .searchMovies(query: "x", page: 1)
        #expect(page.results.map(\.id) == [MovieID(3), MovieID(1), MovieID(2)])
    }

    @Test func resultsHaveNoRuntimeOrDirectors() async throws {
        let response = Fixtures.searchResponse(results: [Fixtures.movieDTO(id: 1), Fixtures.movieDTO(id: 2)])
        let page = try await TMDBMovieRepository(client: Fixtures.searchClient(response))
            .searchMovies(query: "x", page: 1)
        #expect(page.results.allSatisfy { $0.runtime == nil && $0.directors.isEmpty })
    }

    @Test func resultFieldsAreCopied() async throws {
        let dto = Fixtures.movieDTO(
            id: 27205, title: "Inception", originalTitle: "Inception (orig)",
            overview: "Dreams", posterPath: "/p.jpg", backdropPath: "/b.jpg", voteAverage: 8.3
        )
        let page = try await TMDBMovieRepository(client: Fixtures.searchClient(Fixtures.searchResponse(results: [dto])))
            .searchMovies(query: "x", page: 1)
        let movie = try #require(page.results.first)
        #expect(movie.id == MovieID(27205))
        #expect(movie.title == "Inception")
        #expect(movie.originalTitle == "Inception (orig)")
        #expect(movie.overview == "Dreams")
        #expect(movie.voteAverage == 8.3)
        #expect(movie.posterPath == ImagePath("/p.jpg"))
        #expect(movie.backdropPath == ImagePath("/b.jpg"))
    }

    @Test func nilImagePathsStayNil() async throws {
        let dto = Fixtures.movieDTO(posterPath: nil, backdropPath: nil)
        let page = try await TMDBMovieRepository(client: Fixtures.searchClient(Fixtures.searchResponse(results: [dto])))
            .searchMovies(query: "x", page: 1)
        let movie = try #require(page.results.first)
        #expect(movie.posterPath == nil)
        #expect(movie.backdropPath == nil)
    }
}

@Suite struct MovieDetailMappingTests {

    private func movie(_ dto: TMDBMovieDetailDTO) async throws -> Movie {
        try await TMDBMovieRepository(client: Fixtures.detailClient(dto)).movie(id: MovieID(dto.id))
    }

    @Test func requestsTheGivenID() async throws {
        let stub = Fixtures.detailClient(Fixtures.detailDTO(id: 27205))
        _ = try await TMDBMovieRepository(client: stub).movie(id: MovieID(27205))
        #expect(stub.movieDetailsLastID == 27205)
    }

    @Test func runtimeMinutesBecomeDuration() async throws {
        let result = try await movie(Fixtures.detailDTO(runtime: 148))
        #expect(result.runtime == .seconds(148 * 60))
    }

    @Test func nilRuntimeStaysNil() async throws {
        let result = try await movie(Fixtures.detailDTO(runtime: nil))
        #expect(result.runtime == nil)
    }

    @Test func fieldsAreCopied() async throws {
        let result = try await movie(Fixtures.detailDTO(
            id: 27205, title: "Inception", originalTitle: "Inception (orig)",
            overview: "Dreams", voteAverage: 8.3
        ))
        #expect(result.id == MovieID(27205))
        #expect(result.title == "Inception")
        #expect(result.originalTitle == "Inception (orig)")
        #expect(result.overview == "Dreams")
        #expect(result.voteAverage == 8.3)
    }

    @Test func imagePathsBecomeImagePath() async throws {
        let result = try await movie(Fixtures.detailDTO(posterPath: "/p.jpg", backdropPath: "/b.jpg"))
        #expect(result.posterPath == ImagePath("/p.jpg"))
        #expect(result.backdropPath == ImagePath("/b.jpg"))
    }

    @Test func nilImagePathsStayNil() async throws {
        let result = try await movie(Fixtures.detailDTO(posterPath: nil, backdropPath: nil))
        #expect(result.posterPath == nil)
        #expect(result.backdropPath == nil)
    }
}

@Suite struct ReleaseDateMappingTests {

    private func releaseDate(_ raw: String?) async throws -> Date? {
        let stub = Fixtures.detailClient(Fixtures.detailDTO(releaseDate: raw))
        return try await TMDBMovieRepository(client: stub).movie(id: MovieID(1)).releaseDate
    }

    @Test func isoDateBecomesMidnightGMT() async throws {
        let date = try #require(try await releaseDate("2010-07-16"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        #expect(parts.year == 2010)
        #expect(parts.month == 7)
        #expect(parts.day == 16)
        #expect(parts.hour == 0)
        #expect(parts.minute == 0)
        #expect(parts.second == 0)
    }

    @Test func isoDateIsTheSameInstantEverywhere() async throws {
        let date = try #require(try await releaseDate("2010-07-16"))
        #expect(date == Date(timeIntervalSince1970: 1_279_238_400))
    }

    @Test(arguments: [nil, "", "16/07/2010"] as [String?])
    func missingOrMalformedDateBecomesNil(raw: String?) async throws {
        #expect(try await releaseDate(raw) == nil)
    }

    @Test func searchResultsParseDatesToo() async throws {
        let response = Fixtures.searchResponse(results: [
            Fixtures.movieDTO(id: 1, releaseDate: "2010-07-16"),
            Fixtures.movieDTO(id: 2, releaseDate: "")
        ])
        let page = try await TMDBMovieRepository(client: Fixtures.searchClient(response))
            .searchMovies(query: "x", page: 1)
        #expect(page.results[0].releaseDate == Date(timeIntervalSince1970: 1_279_238_400))
        #expect(page.results[1].releaseDate == nil)
    }
}

@Suite struct DirectorMappingTests {

    private func directors(crew: [TMDBCrewMemberDTO]?) async throws -> [Person] {
        let credits = TMDBCreditsDTO(cast: nil, crew: crew)
        let stub = Fixtures.detailClient(Fixtures.detailDTO(credits: credits))
        return try await TMDBMovieRepository(client: stub).movie(id: MovieID(1)).directors
    }

    @Test func singleDirector() async throws {
        let result = try await directors(crew: [
            Fixtures.crew(id: 525, name: "Christopher Nolan", job: "Director", profilePath: "/nolan.jpg"),
            Fixtures.crew(id: 9, name: "Someone", job: "Producer")
        ])
        #expect(result == [
            Person(id: PersonID(525), name: "Christopher Nolan", profilePath: ImagePath("/nolan.jpg"))
        ])
    }

    @Test func severalDirectorsKeepOrder() async throws {
        let result = try await directors(crew: [
            Fixtures.crew(id: 2, name: "Lilly", job: "Director"),
            Fixtures.crew(id: 5, name: "Editor", job: "Editor"),
            Fixtures.crew(id: 1, name: "Lana", job: "Director")
        ])
        #expect(result.map(\.id) == [PersonID(2), PersonID(1)])
        #expect(result.map(\.name) == ["Lilly", "Lana"])
    }

    @Test func relatedJobsAreExcluded() async throws {
        let result = try await directors(crew: [
            Fixtures.crew(id: 1, job: "Director of Photography"),
            Fixtures.crew(id: 2, job: "Co-Director"),
            Fixtures.crew(id: 3, job: "director")
        ])
        #expect(result.isEmpty)
    }

    @Test func nilProfilePathStaysNil() async throws {
        let result = try await directors(crew: [Fixtures.crew(id: 1, job: "Director", profilePath: nil)])
        #expect(result.first?.profilePath == nil)
    }

    @Test func emptyOrMissingCrewGivesNoDirectors() async throws {
        #expect(try await directors(crew: []).isEmpty)
        #expect(try await directors(crew: nil).isEmpty)
    }

    @Test func missingCreditsGiveNoDirectors() async throws {
        let stub = Fixtures.detailClient(Fixtures.detailDTO(credits: nil))
        let movie = try await TMDBMovieRepository(client: stub).movie(id: MovieID(1))
        #expect(movie.directors.isEmpty)
    }
}
