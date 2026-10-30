//
//  WatchlistRowProviders.swift
//  WatchlistFeature
//

import Domain
import DesignSystem

/// What a saved movie's provider line shows.
enum WatchlistRowProviders: Equatable {
    /// Availability hasn't arrived yet.
    case loading
    /// The availability request failed; pull to refresh retries it.
    case failed
    /// Details' answer, as one line.
    case loaded(WatchSummary)

    var lineContent: ProviderLineContent<WatchProvider> {
        switch self {
        case .loading: .loading
        case .failed: .caption(.watchlistRowAvailabilityFailed)
        case .loaded(.atHome(let providers)): .logos(providers, abroad: false)
        case .loaded(.abroad(let providers)): .logos(providers, abroad: true)
        case .loaded(.notOnYourServices): .caption(.watchlistRowNotOnYourServices)
        case .loaded(.notStreamingHere): .caption(.watchlistRowNotStreamingHere)
        }
    }
}
