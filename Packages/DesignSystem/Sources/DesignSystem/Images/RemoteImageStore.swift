//
//  RemoteImageStore.swift
//  DesignSystem
//
//  Process-wide memory cache of decoded remote images.
//
//  `AsyncImage` always starts in its `.empty` phase — even when the bytes are
//  already in `URLCache` — so small images the app shows over and over
//  (provider logos) flash a placeholder on every appearance. `RemoteImage`
//  looks images up here synchronously and renders them on its first frame.
//

import CoreGraphics
import Foundation
import ImageIO

@MainActor
public final class RemoteImageStore {

    public static let shared = RemoteImageStore()

    private let cache = NSCache<NSURL, CGImage>()
    private var inFlight: [URL: Task<CGImage?, Never>] = [:]
    private let session: URLSession

    init(session: URLSession = .shared, countLimit: Int = 300) {
        self.session = session
        cache.countLimit = countLimit
    }

    /// The decoded image for `url`, if it's already in memory.
    public func image(for url: URL) -> CGImage? {
        cache.object(forKey: url as NSURL)
    }

    /// Loads the image at `url`, joining an in-flight load if there is one.
    /// Returns `nil` on failure. Failures aren't remembered, so the next
    /// appearance retries.
    @discardableResult
    public func load(_ url: URL) async -> CGImage? {
        if let image = image(for: url) { return image }
        return await loadTask(for: url).value
    }

    /// Starts loading `urls` in the background so they render on their first
    /// frame when a view asks for them.
    public func prefetch(_ urls: some Sequence<URL>) {
        for url in urls where image(for: url) == nil {
            _ = loadTask(for: url)
        }
    }

    private func loadTask(for url: URL) -> Task<CGImage?, Never> {
        if let running = inFlight[url] { return running }

        let task = Task {
            let image = await download(url)
            if let image {
                cache.setObject(image, forKey: url as NSURL)
            }
            inFlight[url] = nil
            return image
        }
        inFlight[url] = task
        return task
    }

    /// Decoding happens on the main actor. That's fine for logo-sized images
    /// (well under a millisecond); revisit before using this for large artwork.
    private func download(_ url: URL) async -> CGImage? {
        guard let (data, response) = try? await session.data(from: url) else { return nil }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return nil
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        return CGImageSourceCreateImageAtIndex(source, 0, options)
    }
}
