//
//  WatchlistStorage.swift
//  Persistence
//

import Foundation

/// Where `SwiftDataWatchlistRepository` keeps its data. Lets the composition
/// root, tests and previews pick a store without importing SwiftData.
public enum WatchlistStorage: Sendable {
    /// `Watchlist.store` in Application Support — the app's real store.
    case appDefault
    /// A fresh store that lives as long as the repository. Each one is separate.
    case inMemory
    /// A store at `url`. Two repositories on the same URL see the same data,
    /// which is how the tests stand in for a relaunch.
    case file(URL)
}
