public struct TMDBCreditsDTO: Decodable, Sendable {
    public let cast: [TMDBCastMemberDTO]?
    public let crew: [TMDBCrewMemberDTO]?
}
