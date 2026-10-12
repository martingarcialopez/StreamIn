//
//  SwiftDataWatchlistRepository.swift
//  Persistence
//
//  `WatchlistRepository` on SwiftData. A `@ModelActor` owns its own
//  `ModelContext`, so the repository is Sendable and every call is
//  serialized on the actor. SwiftData errors become `WatchlistError` here and
//  never leave the package.
//
//  Internal on purpose: `@ModelActor` adds a public `init(modelContainer:)`
//  and `modelContainer`, which would let callers build a container without
//  the migration plan. `WatchlistPersistence.makeRepository` is the way in.
//

import Foundation
import SwiftData
import Domain

@ModelActor
actor SwiftDataWatchlistRepository: WatchlistRepository {

    init(storage: WatchlistStorage) throws(WatchlistError) {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Schema(versionedSchema: WatchlistSchemaV1.self),
                migrationPlan: WatchlistMigrationPlan.self,
                configurations: storage.configuration
            )
        } catch {
            throw .loadFailed
        }
        self.init(modelContainer: container)
    }

    func items() throws(WatchlistError) -> [WatchlistItem] {
        let newestFirst = FetchDescriptor<WatchlistEntry>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(newestFirst).map(\.item)
        } catch {
            throw .loadFailed
        }
    }

    func save(_ item: WatchlistItem) throws(WatchlistError) {
        do {
            if let existing = try entry(for: item.id) {
                existing.update(from: item)
            } else {
                modelContext.insert(WatchlistEntry(item))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw .saveFailed
        }
    }

    func remove(_ id: MovieID) throws(WatchlistError) {
        let movieID = id.rawValue
        do {
            try modelContext.delete(
                model: WatchlistEntry.self,
                where: #Predicate { $0.movieID == movieID }
            )
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw .saveFailed
        }
    }

    private func entry(for id: MovieID) throws -> WatchlistEntry? {
        let movieID = id.rawValue
        var descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate { $0.movieID == movieID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

private extension WatchlistStorage {
    /// CloudKit is off explicitly: iCloud sync is a non-goal, and the schema
    /// relies on `@Attribute(.unique)`, which CloudKit doesn't allow.
    var configuration: ModelConfiguration {
        switch self {
        case .appDefault:
            ModelConfiguration("Watchlist", cloudKitDatabase: .none)
        case .inMemory:
            // A unique name per store, so two in-memory repositories never share data.
            ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        case .file(let url):
            ModelConfiguration(url: url, cloudKitDatabase: .none)
        }
    }
}
