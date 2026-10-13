import CoreGraphics
import Foundation

/// Draws a `WorldMap` wrapped around a sphere (orthographic projection), lit
/// from the upper left. The trigonometry runs once per size in `init`; each
/// frame only shifts the map horizontally, so spinning costs a few thousand
/// lookups per frame.
struct GlobeRenderer: Sendable {

    /// Where one output pixel reads the map, before the spin is applied.
    private struct Sample: Sendable {
        /// Longitude relative to the globe's center, as a fraction of a turn.
        let longitude: Double
        let row: Int
        /// Light (0…1+) times rim coverage (0…1, antialiasing).
        let shade: Double
        let coverage: Double
    }

    let pixelSize: Int
    private let map: WorldMap
    /// Row-major, `nil` outside the sphere.
    private let samples: [Sample?]

    private static let light: (x: Double, y: Double, z: Double) = {
        let (x, y, z) = (-0.45, 0.5, 0.75)
        let length = (x * x + y * y + z * z).squareRoot()
        return (x / length, y / length, z / length)
    }()

    init(map: WorldMap, pixelSize: Int) {
        self.map = map
        self.pixelSize = pixelSize

        let radius = Double(pixelSize) / 2
        var samples = [Sample?]()
        samples.reserveCapacity(pixelSize * pixelSize)
        for row in 0..<pixelSize {
            for column in 0..<pixelSize {
                // Pixel center, in −1…1 with y pointing up.
                let x = (Double(column) + 0.5 - radius) / radius
                let y = (radius - Double(row) - 0.5) / radius
                let distance = (x * x + y * y).squareRoot()
                // One pixel of antialiasing at the rim.
                let coverage = min(1, max(0, (1 - distance) * radius + 0.5))
                guard coverage > 0 else {
                    samples.append(nil)
                    continue
                }
                let z = max(0, 1 - min(1, distance * distance)).squareRoot()
                let latitude = asin(max(-1, min(1, y)))
                let lighting = max(0, x * Self.light.x + y * Self.light.y + z * Self.light.z)
                samples.append(Sample(
                    longitude: atan2(x, z) / (2 * .pi),
                    row: min(map.height - 1, Int((0.5 - latitude / .pi) * Double(map.height))),
                    shade: 0.45 + 0.65 * lighting,
                    coverage: coverage
                ))
            }
        }
        self.samples = samples
    }

    /// The globe with `centerLongitude` (radians, east positive) facing the
    /// viewer, or `nil` if CoreGraphics can't make the image.
    func image(centerLongitude: Double) -> CGImage? {
        let offset = centerLongitude / (2 * .pi) + 0.5
        let mapWidth = Double(map.width)
        var output = [UInt8](repeating: 0, count: pixelSize * pixelSize * 4)

        for (index, sample) in samples.enumerated() {
            guard let sample else { continue }
            // Wrap around the date line, then blend the two nearest columns so
            // coastlines glide instead of stepping as the globe turns.
            var u = (sample.longitude + offset).truncatingRemainder(dividingBy: 1)
            if u < 0 { u += 1 }
            let position = u * mapWidth - 0.5
            let left = Int(position.rounded(.down))
            let blend = position - Double(left)
            let rowStart = sample.row * map.width
            let leftPixel = (rowStart + (left + map.width) % map.width) * 4
            let rightPixel = (rowStart + (left + 1 + map.width) % map.width) * 4

            let scale = sample.shade * sample.coverage
            for channel in 0..<3 {
                let leftValue = Double(map.pixels[leftPixel + channel])
                let rightValue = Double(map.pixels[rightPixel + channel])
                let value: Double = leftValue + (rightValue - leftValue) * blend
                output[index * 4 + channel] = UInt8(min(255, value * scale))
            }
            output[index * 4 + 3] = UInt8(min(255, 255 * sample.coverage))
        }

        guard
            let provider = CGDataProvider(data: Data(output) as CFData),
            let space = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        return CGImage(
            width: pixelSize, height: pixelSize,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: pixelSize * 4,
            space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
    }
}
