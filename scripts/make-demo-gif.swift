// Turns a simulator recording (`simctl io recordVideo`) into the README's demo
// GIF: sampled at a few frames per second, scaled down, looping. Frames that
// barely change from the one before are merged into it (a longer delay), which
// keeps the file small while the app waits for data. Long pauses are cut short,
// and the home screen around the app (before the test launches it, after it
// quits) is dropped: the GIF runs between the first and last frames as dark as
// the app's cinema background.
//
// Usage (scripts/store-screenshots.sh --demo runs it):
//   swift scripts/make-demo-gif.swift demo.mov docs/screenshots/demo.gif

import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let width = 300
let framesPerSecond = 8.0
let maxBytes = 5_000_000
/// Mean per-channel difference (0–255) below which a frame counts as unchanged.
let unchangedThreshold = 1.5
/// The longest a single frame stays on screen, in seconds.
let maxDelay = 2.0
/// Mean brightness (0–255) above which a leading frame is the home screen, not the app.
let homeScreenBrightness = 30.0

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make-demo-gif.swift <video> <output.gif>\n".utf8))
    exit(1)
}
let input = URL(filePath: arguments[1])
let output = URL(filePath: arguments[2])

let asset = AVURLAsset(url: input)
let duration = try await asset.load(.duration).seconds
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
// simctl records only when the screen changes: take a frame from the step before
// each time, and a time with none keeps the previous frame on screen longer.
generator.requestedTimeToleranceBefore = CMTime(seconds: 1 / framesPerSecond, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = .zero

/// Draws a frame at the GIF's size and returns it with its RGBA bytes.
func scaled(_ image: CGImage) -> (image: CGImage, pixels: [UInt8]) {
    let height = Int((Double(image.height) * Double(width) / Double(image.width)).rounded())
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    let bytes = UnsafeRawBufferPointer(start: context.data, count: width * height * 4)
    return (context.makeImage()!, Array(bytes))
}

func brightness(_ pixels: [UInt8]) -> Double {
    var total = 0
    for index in stride(from: 0, to: pixels.count, by: 4) {
        total += Int(pixels[index]) + Int(pixels[index + 1]) + Int(pixels[index + 2])
    }
    return Double(total) / Double(pixels.count / 4 * 3)
}

func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
    var total = 0
    for index in stride(from: 0, to: a.count, by: 4) {
        total += abs(Int(a[index]) - Int(b[index]))
            + abs(Int(a[index + 1]) - Int(b[index + 1]))
            + abs(Int(a[index + 2]) - Int(b[index + 2]))
    }
    return Double(total) / Double(a.count / 4 * 3)
}

let step = 1 / framesPerSecond
let times = stride(from: 0.0, to: duration, by: step).map { CMTime(seconds: $0, preferredTimescale: 600) }
var frames: [(image: CGImage, pixels: [UInt8], delay: Double)] = []
for await result in generator.images(for: times) {
    // A recording's last moments can fail to decode; the frame before stays longer.
    guard let image = try? result.image else {
        if let last = frames.last { frames[frames.count - 1].delay = min(last.delay + step, maxDelay) }
        continue
    }
    let frame = scaled(image)
    if frames.isEmpty, brightness(frame.pixels) > homeScreenBrightness {
        continue
    }
    if let last = frames.last, difference(last.pixels, frame.pixels) < unchangedThreshold {
        frames[frames.count - 1].delay = min(last.delay + step, maxDelay)
    } else {
        frames.append((frame.image, frame.pixels, step))
    }
}

while let last = frames.last, brightness(last.pixels) > homeScreenBrightness {
    frames.removeLast()
}

guard let destination = CGImageDestinationCreateWithURL(
    output as CFURL, UTType.gif.identifier as CFString, frames.count, nil
) else {
    FileHandle.standardError.write(Data("Can't write \(output.path)\n".utf8))
    exit(1)
}
CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
] as CFDictionary)
for frame in frames {
    CGImageDestinationAddImage(destination, frame.image, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: frame.delay],
    ] as CFDictionary)
}
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("Can't write \(output.path)\n".utf8))
    exit(1)
}

let bytes = try output.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
let length = frames.reduce(0) { $0 + $1.delay }
print("\(output.path): \(frames.count) frames, \(length.formatted(.number.precision(.fractionLength(1)))) s, \((Double(bytes) / 1_000_000).formatted(.number.precision(.fractionLength(1)))) MB")
if bytes > maxBytes {
    FileHandle.standardError.write(Data("Over 5 MB: lower width or framesPerSecond.\n".utf8))
    exit(1)
}
