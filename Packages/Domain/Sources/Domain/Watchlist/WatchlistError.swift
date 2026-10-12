//
//  WatchlistError.swift
//  Domain
//
//  Storage errors are mapped into this at the Persistence boundary, the way
//  transport errors become `MovieError` in TMDBClient.
//

public enum WatchlistError: Error, Equatable, Sendable {
    /// The saved movies couldn't be read.
    case loadFailed
    /// A change couldn't be written.
    case saveFailed
}
