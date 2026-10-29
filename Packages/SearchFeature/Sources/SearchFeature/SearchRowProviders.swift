//
//  SearchRowProviders.swift
//  SearchFeature
//

import Domain

/// What a search result's provider line shows, in Details' order: the
/// user's services and free ones at home, otherwise the user's services
/// abroad.
enum SearchRowProviders: Equatable {
    /// Availability hasn't arrived yet.
    case loading
    /// The availability request failed; pull to refresh retries it.
    case failed
    /// The user's services that carry it at home, then free ones.
    case atHome([WatchProvider])
    /// Nothing of the user's or free at home; the user's services carry it
    /// in other regions.
    case abroad([WatchProvider])
    /// Nothing to show a logo for.
    case none(Reason)

    enum Reason: Equatable {
        /// Something streams it at home, just not one of the user's services.
        case notOnYourServices
        /// No subscription or free service carries it at home.
        case notStreamingHere
    }
}
