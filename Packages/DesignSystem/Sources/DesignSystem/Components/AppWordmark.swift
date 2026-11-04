import SwiftUI

/// The brand name as a logo: "Stream" plus a gold "ın" whose dot is a gold
/// globe, in SF Pro Rounded Black leaning like an italic. Large Title size,
/// so it follows Dynamic Type. VoiceOver reads one element, "StreamIn".
public struct AppWordmark: View {
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize: CGFloat = 34

    /// SF Pro Rounded has no italic (asking for one swaps in SF Pro's, which
    /// isn't rounded), so the upright face is slanted by hand.
    private static let slant: CGFloat = 0.2

    public init() {}

    public var body: some View {
        // Separate texts so the globe can sit over the ı; the brand name is
        // the same in every language.
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: "Stream")
            Group {
                Text(verbatim: "ı")
                    .overlay(alignment: .centerFirstTextBaseline) {
                        WordmarkGlobeDot(fontSize: fontSize, slant: Self.slant)
                    }
                Text(verbatim: "n")
            }
            .foregroundStyle(AppPalette.accent)
        }
        .font(.largeTitle.weight(.black))
        .fontDesign(.rounded)
        .modifier(Slant(amount: Self.slant))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "StreamIn"))
    }
}

#Preview("Sizes") {
    VStack(spacing: Spacing.sectionGap) {
        AppWordmark()
        AppWordmark()
            .dynamicTypeSize(.xSmall)
        AppWordmark()
            .dynamicTypeSize(.accessibility3)
    }
    .padding()
    .cinemaBackground()
}
