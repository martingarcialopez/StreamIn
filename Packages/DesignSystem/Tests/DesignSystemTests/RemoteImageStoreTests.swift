import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import DesignSystem

@MainActor
@Suite("RemoteImageStore")
struct RemoteImageStoreTests {

    @Test func loadedImageIsAvailableSynchronously() async throws {
        let url = try makePNGFile()
        let store = RemoteImageStore()
        #expect(store.image(for: url) == nil)

        let loaded = await store.load(url)

        #expect(loaded != nil)
        #expect(store.image(for: url) != nil)
    }

    @Test func prefetchedImageIsServedByLoad() async throws {
        let url = try makePNGFile()
        let store = RemoteImageStore()

        store.prefetch([url])
        let loaded = await store.load(url)

        #expect(loaded != nil)
        #expect(store.image(for: url) != nil)
    }

    @Test func failedLoadReturnsNilAndIsNotCached() async {
        let url = URL.temporaryDirectory.appending(path: "missing-\(UUID().uuidString).png")
        let store = RemoteImageStore()

        #expect(await store.load(url) == nil)
        #expect(store.image(for: url) == nil)
    }
}

/// Writes a 1×1 PNG to the temp directory and returns its file URL.
private func makePNGFile() throws -> URL {
    let context = try #require(
        CGContext(
            data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    )
    let image = try #require(context.makeImage())
    let data = NSMutableData()
    let destination = try #require(
        CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil)
    )
    CGImageDestinationAddImage(destination, image, nil)
    try #require(CGImageDestinationFinalize(destination))

    let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
    try (data as Data).write(to: url)
    return url
}
