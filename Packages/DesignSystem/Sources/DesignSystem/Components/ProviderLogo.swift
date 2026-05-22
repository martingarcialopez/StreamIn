import SwiftUI

public struct ProviderLogo: View {
    public let url: URL?
    public let providerName: String
    public let size: CGFloat
    public let cornerRadius: CGFloat

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
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .accessibilityLabel(providerName)
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
