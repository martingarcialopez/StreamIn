import SwiftUI

/// The app's page background: a warm near-black (`AppPalette.background`) lit
/// by a faint accent spotlight from the top, like a cinema before the film.
public struct CinemaBackground: View {
    /// Off for a screen with its own light at the top, such as Details'
    /// backdrop, which fades into the plain page colour.
    public let spotlight: Bool

    /// How far down the page the spotlight reaches.
    private static let spotlightRadius: CGFloat = 420
    private static let spotlightOpacity = 0.16

    public init(spotlight: Bool = true) {
        self.spotlight = spotlight
    }

    public var body: some View {
        AppPalette.background
            .overlay {
                if spotlight {
                    RadialGradient(
                        colors: [AppPalette.accent.opacity(Self.spotlightOpacity), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: Self.spotlightRadius
                    )
                }
            }
            .ignoresSafeArea()
    }
}

public extension View {
    /// Puts a screen on the cinema background, behind its lists and forms too.
    /// The app is always dark, so this asks for dark mode as well, which takes
    /// the screen's bars and search field with it, in a preview too.
    func cinemaBackground(spotlight: Bool = true) -> some View {
        scrollContentBackground(.hidden)
            .background { CinemaBackground(spotlight: spotlight) }
            .preferredColorScheme(.dark)
    }

    /// A list or form row in the app's warm card colour, rather than the
    /// system's cooler grey.
    func cinemaRow() -> some View {
        listRowBackground(AppPalette.secondaryBackground)
    }
}

#Preview {
    Text(verbatim: "StreamIn")
        .font(.largeTitle.bold())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cinemaBackground()
}
