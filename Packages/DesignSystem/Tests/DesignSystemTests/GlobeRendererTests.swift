import Testing
import CoreGraphics
import Foundation
@testable import DesignSystem

@Suite("GlobeRenderer")
struct GlobeRendererTests {

    /// Western hemisphere red, eastern hemisphere green.
    private let hemispheres: WorldMap = {
        let width = 64, height = 32
        var pixels = [UInt8]()
        for _ in 0..<height {
            for column in 0..<width {
                pixels += column < width / 2 ? [255, 0, 0, 255] : [0, 255, 0, 255]
            }
        }
        return WorldMap(width: width, height: height, pixels: pixels)
    }()

    private func rgba(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        let data = try #require(image.dataProvider?.data) as Data
        let start = y * image.bytesPerRow + x * 4
        return Array(data[start..<start + 4])
    }

    @Test func facesTheRequestedLongitude() throws {
        let renderer = GlobeRenderer(map: hemispheres, pixelSize: 21)

        let east = try #require(renderer.image(centerLongitude: .pi / 2))
        let west = try #require(renderer.image(centerLongitude: -.pi / 2))

        let eastCenter = try rgba(east, x: 10, y: 10)
        let westCenter = try rgba(west, x: 10, y: 10)
        #expect(eastCenter[1] > 0 && eastCenter[0] == 0)
        #expect(westCenter[0] > 0 && westCenter[1] == 0)
        #expect(eastCenter[3] == 255)
    }

    @Test func outsideTheSphereIsTransparent() throws {
        let renderer = GlobeRenderer(map: hemispheres, pixelSize: 21)

        let image = try #require(renderer.image(centerLongitude: 0))

        #expect(image.width == 21 && image.height == 21)
        #expect(try rgba(image, x: 0, y: 0)[3] == 0)
        #expect(try rgba(image, x: 20, y: 20)[3] == 0)
    }

    @Test func bundledMapLoads() throws {
        let map = try #require(WorldMap.bundled)

        #expect(map.width == 2 * map.height)
    }
}
