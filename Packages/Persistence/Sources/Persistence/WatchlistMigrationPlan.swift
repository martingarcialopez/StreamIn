//
//  WatchlistMigrationPlan.swift
//  Persistence
//

import SwiftData

/// One schema and no stages yet. Exists so the first migration is an added
/// stage rather than retrofitting versioning onto an unversioned store.
enum WatchlistMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WatchlistSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
