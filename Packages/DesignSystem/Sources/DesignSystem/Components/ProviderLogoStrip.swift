import SwiftUI

/// Up to `maxLogos` small provider logos on one line, then "+N" for the rest.
/// Generic over the caller's provider type, since DesignSystem doesn't know
/// Domain's.
public struct ProviderLogoStrip<Provider: Identifiable>: View {
    public let providers: [Provider]
    public let maxLogos: Int
    public let logoSize: CGFloat
    public let logoURL: @MainActor (Provider) -> URL?
    public let name: @MainActor (Provider) -> String
    /// Dims the logos only; "+N" stays readable.
    public let logoOpacity: Double

    public init(
        _ providers: [Provider],
        maxLogos: Int,
        logoSize: CGFloat,
        logoOpacity: Double = 1,
        logoURL: @escaping @MainActor (Provider) -> URL?,
        name: @escaping @MainActor (Provider) -> String
    ) {
        self.providers = providers
        self.maxLogos = maxLogos
        self.logoSize = logoSize
        self.logoOpacity = logoOpacity
        self.logoURL = logoURL
        self.name = name
    }

    public var body: some View {
        HStack(spacing: Spacing.tight) {
            ForEach(providers.prefix(maxLogos)) { provider in
                ProviderLogo(
                    url: logoURL(provider),
                    providerName: name(provider),
                    size: logoSize,
                    cornerRadius: Radius.small
                )
                .opacity(logoOpacity)
            }
            if providers.count > maxLogos {
                Text(verbatim: "+\(providers.count - maxLogos)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Overflow") {
    struct Sample: Identifiable {
        let id: Int
    }
    return VStack(alignment: .leading, spacing: Spacing.comfortable) {
        ProviderLogoStrip((1...2).map(Sample.init), maxLogos: 3, logoSize: LogoSize.small,
                          logoURL: { _ in nil }, name: { "Provider \($0.id)" })
        ProviderLogoStrip((1...5).map(Sample.init), maxLogos: 3, logoSize: LogoSize.small,
                          logoURL: { _ in nil }, name: { "Provider \($0.id)" })
    }
    .padding()
}
