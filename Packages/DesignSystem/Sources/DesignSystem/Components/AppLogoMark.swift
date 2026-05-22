import SwiftUI

public struct AppLogoMark: View {
    public let size: CGFloat

    public init(size: CGFloat = 120) {
        self.size = size
    }

    public var body: some View {
        Image(systemName: Symbol.popcornFill)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppPalette.accent)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.sectionGap) {
        AppLogoMark(size: 64)
        AppLogoMark()
        AppLogoMark(size: 160)
    }
    .padding()
}
