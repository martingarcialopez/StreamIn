import Foundation

/// Builds the one-line directors summary shown in a Watchlist row.
enum WatchlistDirectorsFormatter {

    private static let separator = ", "

    /// `nil` without directors, the names for one or two, "A, B & N more" beyond that.
    static func line(for names: [String]) -> String? {
        switch names.count {
        case 0:
            return nil
        case 1, 2:
            return names.joined(separator: separator)
        default:
            return String(localized: .watchlistDirectorsOverflow(names[0], names[1], names.count - 2))
        }
    }
}
