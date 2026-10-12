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
            return String(localized: overflow(names[0], names[1], names.count - 2))
        }
    }

    // Stand-in for the generated `.watchlistDirectorsOverflow(_:_:_:)` symbol, which
    // can't be regenerated outside Xcode tooling; same key, table and bundle.
    private static func overflow(_ first: String, _ second: String, _ others: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "watchlistDirectorsOverflow",
            defaultValue: "\(first)\(second)\(others, specifier: "%lld")",
            table: "Localizable",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
