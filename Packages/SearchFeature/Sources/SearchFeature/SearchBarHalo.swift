import SwiftUI
import DesignSystem

/// A warm glow turning slowly behind the landing page's search bar: a conic
/// gradient from the accent to orange and red, blurred until it dissolves
/// into the page. Still under Reduce Motion.
struct SearchBarHalo: View {
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Starts and ends on accent so the wrap-around seam is invisible.
    private static let colors: [Color] = [
        AppPalette.accent,
        .orange,
        .red,
        .orange,
        AppPalette.accent,
    ]
    private static let period: TimeInterval = 12
    /// 30 fps is plenty for a 12 s turn, and halves the work on small iPhones.
    private static let frameInterval: TimeInterval = 1.0 / 30
    private static let blur: CGFloat = 28
    /// How far past the bar the glow reaches before the blur.
    private static let extent: CGFloat = 18
    /// Tuned for the landing page, which is always dark; low enough to leave
    /// the slot machine as the brightest thing on it.
    private static let opacity = 0.45

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: reduceMotion)) { context in
            let angle = reduceMotion ? .zero : Self.angle(at: context.date, period: Self.period)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AngularGradient(colors: Self.colors, center: .center, angle: angle))
                .blur(radius: Self.blur)
                .opacity(Self.opacity)
                .padding(-Self.extent)
        }
        .accessibilityHidden(true)
    }

    /// The gradient's rotation at `date`, one full turn per `period`.
    /// Takes the remainder before scaling, so the angle stays within one turn:
    /// unreduced it would be about 2.4e10° by 2026, which loses its fraction
    /// in single precision.
    nonisolated static func angle(at date: Date, period: TimeInterval) -> Angle {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        return .degrees(phase * 360 / period)
    }
}
