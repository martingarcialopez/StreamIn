//
//  WatchlistItem.swift
//  Domain
//
//  A movie the user saved, with when they saved it.
//

import Foundation

/// The whole `Movie` is kept, not a few display fields: a Watchlist row can
/// push it straight into Details, which then renders complete on its first
/// frame — backdrop, rating, directors — even offline.
public struct WatchlistItem: Identifiable, Hashable, Sendable {
    public let movie: Movie
    public let addedAt: Date

    public var id: MovieID { movie.id }

    public init(movie: Movie, addedAt: Date) {
        self.movie = movie
        self.addedAt = addedAt
    }
}
