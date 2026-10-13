import Testing
@testable import DesignSystem

@Suite("SpinningGlobe spin")
struct SpinningGlobeTests {

    private let drag = 4.0

    private func spun(_ progress: Double) -> Double {
        SpinningGlobe.spunFraction(at: progress, drag: drag)
    }

    @Test func startsAtRestAndLandsOnTheFullSpin() {
        #expect(spun(0) == 0)
        #expect(abs(spun(1) - 1) < 1e-12)
    }

    /// Fast at first: most of the turning happens early.
    @Test func coversMostOfTheSpinInTheFirstHalf() {
        #expect(spun(0.5) > 0.85)
    }

    /// Every slice of time turns less than the one before, down to a stop.
    @Test func keepsSlowingDownUntilItStops() {
        let steps = (0...100).map { spun(Double($0) / 100) }
        let speeds = zip(steps.dropFirst(), steps).map { $0 - $1 }

        #expect(zip(speeds.dropFirst(), speeds).allSatisfy { $0 < $1 })
        #expect(speeds.last! < speeds.first! / 100)
    }
}
