import SwiftUI
import DesignSystem

/// The landing page's hero: three reels (movie, service, country) that turn
/// like drums and stop one after another, left to right, on a winning line
/// marked by two pointers, and a lever in outline beside it. Tap the machine
/// or pull the lever to spin again. VoiceOver reads it as one element naming
/// what it landed on.
struct SlotMachine: View {
    let model: LandingViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var scaledRowHeight: CGFloat = 84
    /// Reels rolling right now; taps and pulls wait until they've all landed.
    @State private var rolling: Set<Int> = []
    /// Goes up as the lever bottoms out and the reels start, for a thump.
    @State private var reelStarts = 0
    /// Goes up as each reel lands, for a tick.
    @State private var landings = 0
    /// Goes up to pull the lever, for spins that didn't start with a hand on it.
    @State private var leverPulls = 0
    @State private var pulledByHand = false

    /// Keeps the machine, and the lever hanging off its side, within an
    /// iPhone SE's width at accessibility text sizes.
    private static let maximumRowHeight: CGFloat = 86
    /// Each reel turns longer than the one before, so they stop in order.
    private static let durations: [TimeInterval] = [1.4, 1.9, 2.4]
    private static let turns = [2, 3, 4]
    private static let reelWidthRatio: CGFloat = 0.95
    private static let pointerSize: CGFloat = 10
    /// Between the machine's edge and the lever.
    private static let leverGap: CGFloat = 8
    private static let leverLengthRatio: CGFloat = 0.7

    var body: some View {
        let rowHeight = min(scaledRowHeight, Self.maximumRowHeight)
        let reelWidth = rowHeight * Self.reelWidthRatio
        let windowHeight = rowHeight * SlotReel.windowRows
        Button(action: model.spin) {
            HStack(spacing: 0) {
                ForEach(model.reels.indices, id: \.self) { index in
                    if index > 0 {
                        AppPalette.separator.frame(width: 1)
                    }
                    SlotReel(
                        symbols: model.reels[index],
                        stop: model.stops[index],
                        spinCount: model.spinCount,
                        turns: Self.turns[index],
                        // The reels start as the lever reaches the bottom of its pull.
                        delay: SlotLever.pullDuration,
                        duration: Self.durations[index],
                        rowHeight: rowHeight,
                        onRolling: { isRolling in reelRolling(index, isRolling) }
                    )
                    .frame(width: reelWidth)
                }
            }
            .frame(height: windowHeight)
            .fixedSize()
            .padding(.horizontal, Spacing.comfortable)
            .padding(.vertical, Spacing.default)
            .background(AppPalette.secondaryBackground, in: .rect(cornerRadius: Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(AppPalette.accent.opacity(0.5), lineWidth: 1.5)
            }
            .overlay(alignment: .leading) {
                Pointer(systemName: Symbol.arrowtriangleRightFill, size: Self.pointerSize)
                    .offset(x: -Self.pointerSize / 2)
            }
            .overlay(alignment: .trailing) {
                Pointer(systemName: Symbol.arrowtriangleLeftFill, size: Self.pointerSize)
                    .offset(x: Self.pointerSize / 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityHint(Text(.searchLandingSlotHint))
        // The label changes with every spin; Voice Control needs a word that doesn't.
        .accessibilityInputLabels([Text(.searchLandingSlotInputLabel)])
        .accessibilityAddTraits(.isButton)
        // An overlay pushed just past the machine's edge, so the machine
        // keeps its centre on the page.
        .overlay(alignment: .trailing) {
            SlotLever(height: windowHeight * Self.leverLengthRatio, pullTrigger: leverPulls) { byHand in
                pulledByHand = byHand
                model.spin()
            }
            .offset(x: Self.pointerSize / 2 + Self.leverGap + SlotLever.knobDiameter)
        }
        // Untouchable until the first spin (the load's) and while reels roll.
        .allowsHitTesting(model.spinCount > 0 && rolling.isEmpty)
        .sensoryFeedback(.impact(weight: .heavy), trigger: reelStarts)
        .sensoryFeedback(.impact(weight: .light), trigger: landings)
        .onChange(of: model.spinCount) {
            if !pulledByHand && !reduceMotion {
                leverPulls += 1
            }
            pulledByHand = false
            Task {
                try? await Task.sleep(for: .seconds(SlotLever.pullDuration))
                reelStarts += 1
            }
        }
    }

    private var label: LocalizedStringResource {
        let landed = model.landed
        return .searchLandingSlotLabel(landed[0], landed[1], landed[2])
    }

    private func reelRolling(_ index: Int, _ isRolling: Bool) {
        if isRolling {
            rolling.insert(index)
        } else {
            rolling.remove(index)
            landings += 1
        }
    }
}

/// One of the two accent pointers marking the winning line.
private struct Pointer: View {
    let systemName: String
    let size: CGFloat

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: size, height: size)
            .foregroundStyle(AppPalette.accent)
    }
}
