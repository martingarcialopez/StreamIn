// Draws the equirectangular world map that DesignSystem's `GlobeRenderer`
// wraps around a sphere: flat ocean and land colors close to the 🌍 emoji,
// polar ice in white.
//
// Input: Natural Earth 1:110m land polygons (public domain),
//   https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson
//
// Usage:
//   swift scripts/make-globe-map.swift ne_110m_land.geojson \
//     Packages/DesignSystem/Sources/DesignSystem/Resources/worldMap.png

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let width = 512
let height = 256
let ocean = CGColor(srgbRed: 0.20, green: 0.49, blue: 0.84, alpha: 1)
let land = CGColor(srgbRed: 0.42, green: 0.71, blue: 0.29, alpha: 1)
let ice = CGColor(srgbRed: 0.93, green: 0.96, blue: 0.98, alpha: 1)
/// Polygons entirely south of this latitude (Antarctica) are drawn as ice.
let iceLatitude = -60.0

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make-globe-map.swift <land.geojson> <output.png>\n".utf8))
    exit(1)
}

typealias Ring = [[Double]]

let data = try Data(contentsOf: URL(filePath: arguments[1]))
let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let features = json["features"] as! [[String: Any]]

/// Every polygon as rings of [longitude, latitude]; the first ring is the
/// outline, the rest are holes.
let polygons: [[Ring]] = features.flatMap { feature -> [[Ring]] in
    let geometry = feature["geometry"] as! [String: Any]
    switch geometry["type"] as! String {
    case "Polygon":
        return [geometry["coordinates"] as! [Ring]]
    case "MultiPolygon":
        return geometry["coordinates"] as! [[Ring]]
    default:
        return []
    }
}

let context = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
context.setFillColor(ocean)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

// CoreGraphics' origin is bottom-left, so latitude maps straight to y.
func point(_ coordinate: [Double]) -> CGPoint {
    CGPoint(
        x: (coordinate[0] + 180) / 360 * Double(width),
        y: (coordinate[1] + 90) / 180 * Double(height)
    )
}

for polygon in polygons {
    let path = CGMutablePath()
    for ring in polygon {
        path.addLines(between: ring.map(point))
        path.closeSubpath()
    }
    let isIce = polygon[0].allSatisfy { $0[1] < iceLatitude }
    context.setFillColor(isIce ? ice : land)
    context.addPath(path)
    context.fillPath(using: .evenOdd)
}

let output = URL(filePath: arguments[2])
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("couldn't write \(output.path)\n".utf8))
    exit(1)
}
print("Wrote \(output.path) (\(width)×\(height), \(polygons.count) polygons)")
