import SwiftUI

/// `AppWordmark`'s ı dot: a still gold globe, its bottom where SF Pro Rounded
/// Black's i dot starts. It leans back by the wordmark's slant, so it stays
/// round while still moving over the leaning stem.
struct WordmarkGlobeDot: View {
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
