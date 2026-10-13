import SwiftUI

/// A streaming provider's logo, drawn like an app icon: continuous corners, a
/// hairline edge and a soft shadow, so white logos don't melt into a white
/// background. Backed by `RemoteImageStore`, so a logo the app has already
/// shown (or prefetched at launch) renders on the first frame.
public struct ProviderLogo: View {
    public let url: URL?
    public let providerName: String
    public let size: CGFloat
    public let cornerRadius: CGFloat

    @Environment(\.displayScale) private var displayScale

    public init(
        url: URL?,
        providerName: String,
        size: CGFloat = LogoSize.medium,
        cornerRadius: CGFloat = Radius.medium
    ) {
        self.url = url
        self.providerName = providerName
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RemoteImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fit)
        } placeholder: {
            Rectangle().fill(.quaternary)
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1 / displayScale)
        }
        .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(providerName)
        .accessibilityAddTraits(.isImage)
    }
}

#Preview("Sizes") {
    HStack(spacing: Spacing.comfortable) {
        ProviderLogo(url: nil, providerName: "Small", size: LogoSize.small)
        ProviderLogo(url: nil, providerName: "Medium", size: LogoSize.medium)
        ProviderLogo(url: nil, providerName: "Large", size: LogoSize.large)
        ProviderLogo(url: nil, providerName: "Hero", size: LogoSize.hero)
    }
    .padding()
}
