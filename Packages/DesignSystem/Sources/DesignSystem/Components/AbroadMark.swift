import SwiftUI

/// "On your services abroad", drawn like a `ProviderLogo` so it sits flat in a
/// line of them: an accent globe on an accent-tinted app-icon tile.
public struct AbroadMark: View {
    public let size: CGFloat

    private static let tint = 0.18
    private static let inset = 0.2

    public init(size: CGFloat = LogoSize.small) {
        self.size = size
    }

    public var body: some View {
        Image(systemName: Symbol.globeEuropeAfricaFill)
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppPalette.accent)
            .padding(size * Self.inset)
            .frame(width: size, height: size)
            .background(
                AppPalette.accent.opacity(Self.tint),
                in: .rect(cornerRadius: Radius.medium, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: Spacing.default) {
        AbroadMark()
        ProviderLogo(url: nil, providerName: "Netflix", size: LogoSize.small)
        ProviderLogo(url: nil, providerName: "Prime Video", size: LogoSize.small)
    }
    .padding()
    .cinemaBackground()
}
