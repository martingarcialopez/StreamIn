//
//  WatchlistPersistence.swift
//  Persistence
//

import Domain

/// The package's only public entry point: builds the SwiftData-backed
/// repository behind Domain's protocol, so callers never see SwiftData.
public enum WatchlistPersistence {

    /// Opens (or creates) the store described by `storage`.
    /// - Throws: `WatchlistError.loadFailed` if the store can't be opened.
    public static func makeRepository(storage: WatchlistStorage) throws(WatchlistError) -> any WatchlistRepository {
        try SwiftDataWatchlistRepository(storage: storage)
    }
}
