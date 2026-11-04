// Draws the app icon's cinema spotlight as a PNG: accent gold from the top
// centre, fading out, like CinemaBackground. It's a bitmap because Xcode's
// icon compiler ignores an SVG radial gradient's user-space centre and draws
// it in the middle of the icon (Icon Composer's preview gets it right).
//
//   swift scripts/make-icon-spotlight.swift StreamIn/Resources/AppIcon.icon/Assets/spotlight.png
import AppKit

let size = 1024
let opacity: CGFloat = 0.38
let radius: CGFloat = 820

let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let gold = (r: 1.0, g: 0xCB / 255.0, b: 0x6B / 255.0)
let gradient = CGGradient(
    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    colors: [
        CGColor(srgbRed: gold.r, green: gold.g, blue: gold.b, alpha: opacity),
        CGColor(srgbRed: gold.r, green: gold.g, blue: gold.b, alpha: 0),
    ] as CFArray,
    locations: [0, 1]
)!
// CoreGraphics has y up: the top centre is (512, 1024).
let top = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size))
context.drawRadialGradient(gradient, startCenter: top, startRadius: 0, endCenter: top, endRadius: radius, options: [])
try! NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("Wrote \(CommandLine.arguments[1])")
