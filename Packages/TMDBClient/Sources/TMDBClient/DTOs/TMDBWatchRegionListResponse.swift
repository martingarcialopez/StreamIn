// MARK: - Watch region DTOs
//
// `/watch/providers/regions` lists every country TMDB has streaming
// availability for. Each entry also carries English and native names; the
// app names countries through `Locale` instead, so only the code is decoded.

public struct TMDBWatchRegionListResponse: Decodable, Sendable {
    public let results: [TMDBWatchRegionDTO]
}
