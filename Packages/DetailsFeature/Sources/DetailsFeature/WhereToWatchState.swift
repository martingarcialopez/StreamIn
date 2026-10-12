//
//  WhereToWatchState.swift
//  DetailsFeature
//

import Domain

/// What the "Where to watch" section shows for the home region.
public enum WhereToWatchState: Equatable, Sendable {
    /// Home availability hasn't arrived yet.
    case loading
    /// The load failed and there's no home availability to show.
    case failed(MovieError)
    /// Nothing free or on a subscription at home (rent/buy isn't shown in v1).
    case unavailable
    /// Something free or on a subscription at home.
    case available
}
