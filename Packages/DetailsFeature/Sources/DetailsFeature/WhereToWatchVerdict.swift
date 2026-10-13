//
//  WhereToWatchVerdict.swift
//  DetailsFeature
//

import Domain

/// The one answer the "Where to watch" card leads with.
public enum WhereToWatchVerdict: Equatable, Sendable {
    /// Home availability hasn't arrived yet.
    case loading
    /// The load failed and there's no home availability to show.
    case failed(MovieError)
    /// One of the user's services or a free one carries it at home.
    case watchNow
    /// Nothing of the user's or free at home, but the user's services carry
    /// it in other regions.
    case abroad
    /// No services picked and nothing free at home: the card offers the picker.
    case chooseServices
    /// Nothing of the user's or free at home, and none of the user's
    /// services carry it anywhere else.
    case unavailable
}
