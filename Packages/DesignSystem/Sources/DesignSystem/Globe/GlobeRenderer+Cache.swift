import Foundation

@MainActor
extension GlobeRenderer {
    /// One renderer per pixel size, built on first use: its projection is
    /// all trigonometry, and `SpinningGlobe.body` runs several times per
    /// appearance. `nil` if the bundled map can't be read.
    static func cached(pixelSize: Int) -> GlobeRenderer? {
        if let renderer = cache[pixelSize] { return renderer }
        guard let map = WorldMap.bundled else { return nil }
        let renderer = GlobeRenderer(map: map, pixelSize: pixelSize)
        cache[pixelSize] = renderer
        return renderer
    }

    private static var cache: [Int: GlobeRenderer] = [:]
}
