import SwiftUI

/// A movie's poster thumbnail, 2:3, scaling with Dynamic Type. Shows a
/// placeholder while loading and a photo glyph if the image fails.
public struct MoviePoster: View {
    public let url: URL?

    @ScaledMetric(relativeTo: .headline) private var width: CGFloat = 60

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.15)
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray.opacity(0.15)
                    .overlay {
                        Image(systemName: Symbol.photo).foregroundStyle(.tertiary)
                    }
            @unknown default:
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(.rect(cornerRadius: Radius.medium))
        .accessibilityHidden(true)
    }
}

#Preview("Placeholder and failure") {
    HStack(spacing: Spacing.comfortable) {
        MoviePoster(url: nil)
        MoviePoster(url: URL(string: "https://invalid.example/poster.jpg"))
    }
    .padding()
}
