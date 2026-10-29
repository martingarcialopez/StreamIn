import SwiftUI

/// A globe that really turns: the bundled world map wrapped around a sphere
/// by `GlobeRenderer`. When it appears it's flicked eastward, slows down like
/// a ball spinning on a table and comes to rest on Europe and Africa, like 🌍.
/// Static under Reduce Motion, or with `turns: 0` (e.g. in a list, where a
/// globe per row would be too busy).
public struct SpinningGlobe: View {
    public let diameter: CGFloat
    public let turns: Int

    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinStart: Date?

    /// 15°E puts Europe and Africa in front.
    private static let restingLongitude = 15.0 * .pi / 180
    private static let secondsPerTurn = 0.9
    /// How hard drag bleeds off speed; higher means a faster start and a
    /// longer slow tail.
    private static let drag = 4.0

    public init(diameter: CGFloat, turns: Int = 5) {
        self.diameter = diameter
        self.turns = turns
    }

    private var duration: Double {
        Self.secondsPerTurn * Double(turns)
    }

    public var body: some View {
        let renderer = GlobeRenderer.cached(pixelSize: Int((diameter * displayScale).rounded(.up)))
        TimelineView(.animation(paused: spinStart == nil)) { context in
            if let renderer, let image = renderer.image(centerLongitude: centerLongitude(at: context.date)) {
                Image(decorative: image, scale: displayScale)
                    .resizable()
            } else {
                Text(verbatim: "🌍")
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
        .task {
            guard !reduceMotion, turns > 0 else { return }
            spinStart = .now
            try? await Task.sleep(for: .seconds(duration))
            spinStart = nil
        }
    }

    /// Turning eastward brings longitudes further west into view.
    private func centerLongitude(at date: Date) -> Double {
        guard let spinStart else { return Self.restingLongitude }
        let progress = min(1, max(0, date.timeIntervalSince(spinStart) / duration))
        let spun = Self.spunFraction(at: progress, drag: Self.drag)
        return Self.restingLongitude - spun * Double(turns) * 2 * .pi
    }

    /// The share of the whole spin done at `progress` (0…1) of the duration,
    /// for a ball flicked on a table. Speed falls with drag (proportional to
    /// speed, so it bleeds off fast at first) plus a constant friction that
    /// takes it exactly to zero at the end:
    /// `speed(t) = e^(−drag·t) − e^(−drag)`, integrated and normalized to 1.
    nonisolated static func spunFraction(at progress: Double, drag: Double) -> Double {
        let floor = exp(-drag)
        func distance(_ t: Double) -> Double {
            (1 - exp(-drag * t)) / drag - floor * t
        }
        return distance(progress) / distance(1)
    }
}

#Preview("Sizes") {
    HStack(spacing: Spacing.comfortable) {
        SpinningGlobe(diameter: LogoSize.small)
        SpinningGlobe(diameter: LogoSize.large)
        SpinningGlobe(diameter: 120)
    }
    .padding()
}
