import SwiftUI
import DesignSystem

/// A lever in outline, made of the machine's own materials: a slim track with
/// the machine's background and accent border, and an accent knob set in the
/// tiles' Liquid Glass rim. Every spin pulls the knob down and lets it spring
/// back (`pullTrigger`). It can be pulled by hand too: dragged most of the way
/// down, or tapped, it spins the reels. Decorative for VoiceOver, which spins
/// through the machine itself.
struct SlotLever: View {
    /// The track's length.
    let height: CGFloat
    let pullTrigger: Int
    /// `byHand` is true when the knob was dragged down, so it doesn't pull again.
    let onPull: (_ byHand: Bool) -> Void

    /// How far a hand has the knob down, 0 (top) to 1 (bottom).
    @State private var handPull: CGFloat = 0

    /// How long the knob takes to come down; the machine starts the reels then.
    static let pullDuration: TimeInterval = 0.2
    static let knobDiameter: CGFloat = 26
    private static let trackWidth: CGFloat = 8
    /// A hand pull past this share of the way spins the reels.
    private static let spinThreshold: CGFloat = 0.6
    /// A touch that moves less than this is a tap on the lever.
    private static let tapSlop: CGFloat = 4

    var body: some View {
        KeyframeAnimator(initialValue: 0.0, trigger: pullTrigger) { pull in
            ZStack(alignment: .top) {
                // The same border as the machine's, so the lever reads as part of it.
                Capsule()
                    .fill(AppPalette.secondaryBackground)
                    .strokeBorder(AppPalette.accent.opacity(0.5), lineWidth: 1.5)
                    .frame(width: Self.trackWidth, height: height)
                LeverKnob(diameter: Self.knobDiameter)
                    .offset(y: (height - Self.knobDiameter) * max(pull, handPull))
            }
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1, duration: Self.pullDuration)
                SpringKeyframe(0, duration: 0.6, spring: .bouncy)
            }
        }
        .frame(width: Self.knobDiameter, height: height)
        .contentShape(.rect)
        .gesture(handDrag)
        .accessibilityHidden(true)
    }

    private var handDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let travel = height - Self.knobDiameter
                handPull = min(max(value.translation.height / travel, 0), 1)
            }
            .onEnded { value in
                let isTap = abs(value.translation.height) < Self.tapSlop
                    && abs(value.translation.width) < Self.tapSlop
                let isFullPull = handPull >= Self.spinThreshold
                withAnimation(.bouncy) { handPull = 0 }
                if isTap {
                    onPull(false)
                } else if isFullPull {
                    onPull(true)
                }
            }
    }
}

/// The lever's knob, built like the tiles: an accent disc filling a Liquid
/// Glass one inside the same thin rim, which gives it its depth.
private struct LeverKnob: View {
    let diameter: CGFloat

    var body: some View {
        let disc = diameter - SlotSymbolView.rim * 2
        Circle()
            .fill(AppPalette.accent)
            .frame(width: disc, height: disc)
            .frame(width: diameter, height: diameter)
            .glassEffect(.regular.interactive(), in: .circle)
    }
}
