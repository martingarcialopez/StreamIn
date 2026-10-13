import CoreGraphics
import Foundation
import ImageIO

/// An equirectangular world map as raw pixels: longitude −180°…180° left to
/// right, latitude 90°…−90° top to bottom. RGBA, premultiplied, row 0 on top.
struct WorldMap: Sendable {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    /// `Resources/worldMap.png`, made by `scripts/make-globe-map.swift`.
    /// Decoded once; `nil` only if the resource is missing or unreadable.
    static let bundled: WorldMap? = Bundle.module
        .url(forResource: "worldMap", withExtension: "png")
        .flatMap(WorldMap.init(contentsOf:))

    init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(pixels.count == width * height * 4, "RGBA pixel count doesn't match the size")
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    init?(contentsOf url: URL) {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }

        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { return nil }
        self.init(width: image.width, height: image.height, pixels: pixels)
    }
}
