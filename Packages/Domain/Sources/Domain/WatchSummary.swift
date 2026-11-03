//
//  WatchSummary.swift
//  Domain
//

/// A list row's one-line answer to "where can I watch it?", in Details'
/// order: the user's services and free ones at home, otherwise the user's
/// services abroad, otherwise the other services at home. Search results and
/// the Watchlist both show it.
public enum WatchSummary: Equatable, Sendable {
    /// The user's services that carry it at home, then free ones.
    case atHome([WatchProvider])
    /// Nothing of the user's or free at home; the user's services carry it
    /// in other regions.
    case abroad([WatchProvider])
    /// Nothing of the user's, free, or abroad; these subscription services
    /// carry it at home, in TMDB's order.
    case othersAtHome([WatchProvider])
    /// No subscription or free service carries it at home.
    case notStreamingHere
}

extension WatchOptions {
    public var summary: WatchSummary {
        if !watchNow.isEmpty { return .atHome(watchNow) }
        if !yoursAbroad.isEmpty { return .abroad(yoursAbroad.map(\.provider)) }
        if !othersAtHome.isEmpty { return .othersAtHome(othersAtHome) }
        return .notStreamingHere
    }
}
