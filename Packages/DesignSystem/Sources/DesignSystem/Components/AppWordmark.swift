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
                        GlobeDot(fontSize: fontSize, slant: Self.slant)
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

/// The ı's dot: a still gold globe, its bottom where SF Pro Rounded Black's
/// i dot starts. It leans back by the wordmark's slant, so it stays round
/// while still moving over the leaning stem.
private struct GlobeDot: View {
    let fontSize: CGFloat
    let slant: CGFloat

    // In ems, measured with CoreText: the bottom of the i's dot above the
    // baseline, and a globe about twice the dot's 0.2 em width.
    private static let dotBottom: CGFloat = 0.583
    private static let diameter: CGFloat = 0.4

    var body: some View {
        // Still: at this size a spin barely shows.
        SpinningGlobe(diameter: fontSize * Self.diameter, turns: 0)
            // Gold, to match the "ın": lifted first, or multiplying darkens
            // the oceans to brown.
            .grayscale(1)
            .brightness(0.3)
            .colorMultiply(AppPalette.accent)
            .modifier(Slant(amount: -slant))
            .alignmentGuide(.firstTextBaseline) { d in
                d[.bottom] + fontSize * Self.dotBottom
            }
    }
}

/// Leans a view right (negative amounts lean it left) about its vertical
/// centre, by `amount` points across per point up.
private struct Slant: GeometryEffect {
    let amount: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            a: 1, b: 0, c: -amount, d: 1, tx: amount * size.height / 2, ty: 0
        ))
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
