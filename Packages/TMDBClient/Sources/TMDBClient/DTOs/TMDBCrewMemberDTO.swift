public struct TMDBCrewMemberDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let job: String          // e.g. "Director", "Director of Photography"
    public let department: String   // e.g. "Directing", "Camera"

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}
