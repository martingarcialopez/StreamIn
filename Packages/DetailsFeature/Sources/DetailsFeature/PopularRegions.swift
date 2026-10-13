//
//  PopularRegions.swift
//  DetailsFeature
//

import Foundation
import Domain

/// Countries people most often pick as a VPN location, so a provider's
/// other regions lead with useful ones rather than Andorra and Antigua.
enum PopularRegions {

    static let shortlist: [Region] = [
        "US", "GB", "CA", "DE", "FR", "NL", "JP", "AU", "IT", "BR", "MX", "SE", "CH", "IN", "KR",
    ].map(Region.init(code:))

    private static let rank = Dictionary(
        uniqueKeysWithValues: shortlist.enumerated().map { ($0.element, $0.offset) }
    )

    /// Shortlisted regions first, in shortlist order; the rest by localized name.
    static func sorted(_ regions: [Region]) -> [Region] {
        // Each name is a locale lookup; do it once per region, not per comparison.
        let named = regions.map { (region: $0, name: $0.displayName) }
        return named.sorted { lhs, rhs in
            switch (rank[lhs.region], rank[rhs.region]) {
            case let (lhsRank?, rhsRank?):
                lhsRank < rhsRank
            case (.some, nil):
                true
            case (nil, .some):
                false
            case (nil, nil):
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
        .map(\.region)
    }
}
