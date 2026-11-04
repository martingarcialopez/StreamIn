//
//  WCAGContrast.swift
//  StreamInUITests
//
//  WCAG 2 contrast measured on a screenshot of one element: its brightest
//  pixel (the text, on StreamIn's dark pages) against its darkest (the
//  background behind it).
//

import UIKit

enum WCAGContrast {

    /// AA for body text. Large text may go down to 3:1, but an element's
    /// height can't tell large type from wrapped lines, so every text is held
    /// to 4.5:1; StreamIn's large text is primary and clears it anyway.
    static let minimum = 4.5

    /// The contrast between the brightest and darkest pixels, or `nil` when
    /// the image can't be read.
    static func ratio(in image: UIImage) -> Double? {
        guard let cgImage = image.cgImage,
              let space = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        var darkest = 1.0
        var brightest = 0.0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let value = luminance(pixels[index], pixels[index + 1], pixels[index + 2])
            darkest = min(darkest, value)
            brightest = max(brightest, value)
        }
        return (brightest + 0.05) / (darkest + 0.05)
    }

    /// WCAG relative luminance of an sRGB pixel.
    private static func luminance(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Double {
        func linear(_ channel: UInt8) -> Double {
            let value = Double(channel) / 255
            return value <= 0.039_28 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
