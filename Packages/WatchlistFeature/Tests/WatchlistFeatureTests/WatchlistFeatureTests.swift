import Testing
@testable import WatchlistFeature

@Suite("WatchlistDirectorsFormatter")
struct WatchlistDirectorsFormatterTests {

    @Test func noDirectorsHasNoLine() {
        #expect(WatchlistDirectorsFormatter.line(for: []) == nil)
    }

    @Test func oneDirectorIsTheName() {
        #expect(WatchlistDirectorsFormatter.line(for: ["Greta Gerwig"]) == "Greta Gerwig")
    }

    @Test func twoDirectorsAreCommaSeparated() {
        #expect(WatchlistDirectorsFormatter.line(for: ["Joel Coen", "Ethan Coen"]) == "Joel Coen, Ethan Coen")
    }

    @Test func threeDirectorsCountOneMore() {
        let line = WatchlistDirectorsFormatter.line(for: ["Lana Wachowski", "Lilly Wachowski", "Tom Tykwer"])
        #expect(line == "Lana Wachowski, Lilly Wachowski & 1 more")
    }

    @Test func fiveDirectorsCountThreeMore() {
        let line = WatchlistDirectorsFormatter.line(for: ["A", "B", "C", "D", "E"])
        #expect(line == "A, B & 3 more")
    }
}
