//
//  WatchlistWriteFailure.swift
//  Watchlist
//
//  A change the user made that couldn't be saved and was rolled back, kept
//  until the UI has told them about it.
//

import Domain

public struct WatchlistWriteFailure: Equatable, Sendable {

    public enum Change: Equatable, Sendable {
        case add
        case remove
    }

    public let change: Change
    public let movie: Movie
    public let error: WatchlistError

    public init(change: Change, movie: Movie, error: WatchlistError) {
        self.change = change
        self.movie = movie
        self.error = error
    }
}
