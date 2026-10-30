import Testing
import Foundation
@testable import SearchFeature

// The landing page's motion, as pure functions: the reels' travel, where a
// symbol sits on its drum, and the halo's rotation.

@Suite("SlotReel.travel")
struct SlotReelTravelTests {

    @Test(arguments: 0..<5, 0..<5)
    func landsOnTheStopAfterWholeTurns(start: Int, stop: Int) {
        let count = 5
        let turns = 3
        let destination = SlotReel.travel(from: start, to: stop, count: count, turns: turns)

        #expect(destination % count == stop)
        #expect(destination - start >= turns * count)
        #expect(destination - start < (turns + 1) * count)
    }
}

@Suite("DrumPlacement")
struct DrumPlacementTests {

    private let row: CGFloat = 80

    @Test func symbolOnTheLineIsCentredFlatAndOpaque() {
        let place = DrumPlacement(rowsFromLine: 0, rowHeight: row)

        #expect(place.offset == 0)
        #expect(place.flattening == 1)
        #expect(place.opacity == 1)
    }

    @Test func symbolsAboveAndBelowMirrorEachOther() {
        let above = DrumPlacement(rowsFromLine: -1, rowHeight: row)
        let below = DrumPlacement(rowsFromLine: 1, rowHeight: row)

        #expect(above.offset == -below.offset)
        #expect(above.flattening == below.flattening)
        #expect(above.opacity == below.opacity)
    }

    @Test func symbolsBunchUpSquashAndFadeTowardTheEdge() {
        let next = DrumPlacement(rowsFromLine: 1, rowHeight: row)
        let further = DrumPlacement(rowsFromLine: 1.5, rowHeight: row)

        // On a cylinder, each step away from the line covers less height.
        #expect(next.offset < row)
        #expect(further.offset - next.offset < next.offset)
        #expect(further.flattening < next.flattening)
        #expect(further.opacity < next.opacity)
    }

    @Test func offsetsKeepGrowingUpToTheDrumsEdge() {
        let offsets = stride(from: 0.0, to: 2.0, by: 0.05).map {
            DrumPlacement(rowsFromLine: $0, rowHeight: row).offset
        }

        #expect(zip(offsets, offsets.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test func symbolsRoundTheBackAreHidden() {
        #expect(DrumPlacement(rowsFromLine: 2, rowHeight: row).opacity == 0)
        #expect(DrumPlacement(rowsFromLine: -2.5, rowHeight: row).opacity == 0)
    }
}

@Suite("SearchBarHalo.angle")
struct SearchBarHaloAngleTests {

    private let period: TimeInterval = 12

    @Test func startsAtZeroOnAPeriodBoundary() {
        let date = Date(timeIntervalSinceReferenceDate: period * 1_000)
        #expect(SearchBarHalo.angle(at: date, period: period).degrees == 0)
    }

    @Test func isHalfATurnHalfwayThroughAPeriod() {
        let date = Date(timeIntervalSinceReferenceDate: period / 2)
        #expect(SearchBarHalo.angle(at: date, period: period).degrees == 180)
    }

    @Test func wrapsAfterAFullTurn() {
        let quarter = Date(timeIntervalSinceReferenceDate: period / 4)
        let nextQuarter = quarter.addingTimeInterval(period)
        #expect(SearchBarHalo.angle(at: nextQuarter, period: period).degrees
            .isApproximatelyEqual(to: SearchBarHalo.angle(at: quarter, period: period).degrees))
    }

    @Test func staysWithinOneTurnAtPresentDayDates() {
        // About 8e8 s since 2001: the angle is reduced to one turn, and one
        // 30 fps frame still advances it by its share of a turn.
        let now = Date(timeIntervalSinceReferenceDate: 814_000_000)
        let frame: TimeInterval = 1.0 / 30
        let angle = SearchBarHalo.angle(at: now, period: period).degrees
        let step = SearchBarHalo.angle(at: now.addingTimeInterval(frame), period: period).degrees - angle
        #expect((0..<360).contains(angle))
        #expect(step.isApproximatelyEqual(to: 360 * frame / period))
    }
}

private extension Double {
    func isApproximatelyEqual(to other: Double) -> Bool {
        abs(self - other) < 1e-3
    }
}
