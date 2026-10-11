//
//  RemoteImage.swift
//  DesignSystem
//
//  Drop-in for `AsyncImage` backed by `RemoteImageStore`: an image the app
//  has already loaded renders on the view's first frame, with no placeholder
//  flash.
//

import SwiftUI

public struct RemoteImage<Content: View, Placeholder: View>: View {

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    /// This view's own finished load. Keeps the image on screen even if the
    /// shared store evicts it under memory pressure.
    @State private var loaded: LoadedImage?

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        if let image = currentImage {
            content(Image(decorative: image, scale: 1))
        } else {
            placeholder()
                .task(id: url) {
                    guard let url, let image = await RemoteImageStore.shared.load(url) else { return }
                    loaded = LoadedImage(url: url, image: image)
                }
        }
    }

    private var currentImage: CGImage? {
        guard let url else { return nil }
        if let loaded, loaded.url == url {
            return loaded.image
        }
        return RemoteImageStore.shared.image(for: url)
    }
}

private struct LoadedImage {
    let url: URL
    let image: CGImage
}
