import Foundation
import Domain

// MARK: - Image URL Builder
//
// Concrete `ImageURLBuilder` for TMDB's CDN. Lives in this layer because the
// URL scheme (`https://image.tmdb.org/t/p/<size>/<path>`) is TMDB-specific.
// Features import only the `ImageURLBuilder` protocol from Domain and receive
// this implementation through the composition root.

public struct TMDBImageURLBuilder: ImageURLBuilder {
    private let baseURL: String

    public init(baseURL: String = "https://image.tmdb.org/t/p/") {
        self.baseURL = baseURL
    }

    public func url(for path: ImagePath, size: ImageSize) -> URL? {
        // TMDB image paths arrive with a leading slash, e.g. "/abc.jpg".
        // The size segments are TMDB's standard sizes; see
        // https://developers.themoviedb.org/3/configuration/get-api-configuration
        let sizeSegment: String
        switch size {
        case .poster:        sizeSegment = "w342"
        case .backdrop:      sizeSegment = "w780"
        case .providerLogo:  sizeSegment = "w92"
        }
        return URL(string: "\(baseURL)\(sizeSegment)\(path.rawValue)")
    }
}
