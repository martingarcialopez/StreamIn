//
//  SubscriptionsState.swift
//  DetailsFeature
//

import Domain

/// What the "Watch with your subscriptions" section shows.
public enum SubscriptionsState: Equatable, Sendable {
    /// No services picked yet: the section offers the picker.
    case needsSubscriptions
    /// Availability hasn't arrived yet.
    case loading
    /// The load failed and there's no earlier result to show.
    case failed(MovieError)
    /// None of the user's services carries this film anywhere.
    case noMatches
    /// At least one of the user's services carries it somewhere.
    case available
}
