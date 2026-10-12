public struct TMDBCastMemberDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let character: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}
