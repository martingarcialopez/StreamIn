//
//  WatchlistSchemaV1.swift
//  Persistence
//
//  Versioned from the first release: once users have saved movies, any change
//  to `WatchlistEntry` ships as a V2 plus a stage in `WatchlistMigrationPlan`.
//

import SwiftData

enum WatchlistSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [WatchlistEntry.self]
    }
}
