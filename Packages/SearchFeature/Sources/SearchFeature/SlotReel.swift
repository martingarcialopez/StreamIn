import SwiftUI
import DesignSystem

/// One reel of the slot machine, turning like a drum (`DrumPlacement`). When
/// `spinCount` changes it waits `delay`, then rolls forward `turns` whole
/// turns and slows to a stop on `stop` over `duration`; under Reduce Motion
/// it just shows the new symbol.
struct SlotReel: View {
    let symbols: [SlotSymbol]
    let stop: Int
    let spinCount: Int
    let turns: Int
    let delay: TimeInterval
    let duration: TimeInterval
    let rowHeight: CGFloat
    /// Called with `true` when the reel starts rolling and `false` when it lands.
    let onRolling: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far the drum has turned, in symbols: the one on the winning line is
    /// `position` modulo the symbol count.
    @State private var position = 0

    /// The winning row and part of its neighbours, as in a real machine's window.
    static let windowRows: CGFloat = 2.2

    /// Fast start, long slow finish, like a reel losing speed.
    private var rollAnimation: Animation {
        .timingCurve(0.15, 0.6, 0.25, 1, duration: duration).delay(delay)
    }

    private var count: Int { max(symbols.count, 1) }

    var body: some View {
        Drum(symbols: symbols, position: Double(position), rowHeight: rowHeight)
            .frame(height: rowHeight * Self.windowRows)
            .frame(maxWidth: .infinity)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.25),
                        .init(color: .black, location: 0.75),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .onAppear { position = stop % count }
            .onChange(of: spinCount) { roll() }
    }

    private func roll() {
        let target = stop % count
        guard !reduceMotion else {
            position = target
            return
        }
        let destination = Self.travel(from: position % count, to: target, count: count, turns: turns)
        onRolling(true)
        withAnimation(rollAnimation) {
            position = destination
        } completion: {
            // The same symbol, without the turns, so the next spin starts small.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { position = target }
            onRolling(false)
        }
    }

    /// Where a reel at `start` ends up to land on `stop` after `turns` whole
    /// turns: always forward, like a real reel.
    nonisolated static func travel(from start: Int, to stop: Int, count: Int, turns: Int) -> Int {
        let ahead = ((stop - start) % count + count) % count
        return start + turns * count + ahead
    }
}

/// The reel at one moment of its turn. `position` is animatable, so SwiftUI
/// redraws it at every frame of a spin, placing the few symbols on the front
/// of the drum.
private struct Drum: View, Animatable {
    let symbols: [SlotSymbol]
    var position: Double
    let rowHeight: CGFloat

    /// Symbols drawn either side of the line; any further are round the back.
    private static let reach = 2

    nonisolated var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    var body: some View {
        // Mid-spin the line falls between two symbols, so one more is drawn
        // below than above to keep `reach` on each side of it.
        let onLine = Int(position.rounded(.down))
        let indices = symbols.isEmpty ? [] : Array((onLine - Self.reach)...(onLine + Self.reach + 1))
        ZStack {
            ForEach(indices, id: \.self) { index in
                let place = DrumPlacement(rowsFromLine: Double(index) - position, rowHeight: rowHeight)
                SlotSymbolView(symbol: symbols[wrapped(index)], rowHeight: rowHeight)
                    .scaleEffect(x: 1, y: place.flattening)
                    .offset(y: place.offset)
                    .opacity(place.opacity)
            }
        }
    }

    private func wrapped(_ index: Int) -> Int {
        let count = symbols.count
        return (index % count + count) % count
    }
}
