//
//  WatchlistEntry.swift
//  Persistence
//
//  The stored form of a `WatchlistItem`: a flattened `Movie` plus `addedAt`.
//  Raw values (Int, String) instead of Domain's typed IDs, which SwiftData
//  can't index or query.
//

import Foundation
import SwiftData

typealias WatchlistEntry = WatchlistSchemaV1.WatchlistEntry

extension WatchlistSchemaV1 {

    @Model
    final class WatchlistEntry {
        #Index<WatchlistEntry>([\.addedAt])

        @Attribute(.unique) var movieID: Int
        var title: String
        var originalTitle: String
        var overview: String
        var releaseDate: Date?
        var posterPath: String?
        var backdropPath: String?
        var voteAverage: Double
        var runtimeMinutes: Int?
        /// In credit order, which the array keeps.
        var directors: [StoredPerson]
        var addedAt: Date

        init(
            movieID: Int,
            title: String,
            originalTitle: String,
            overview: String,
            releaseDate: Date?,
            posterPath: String?,
            backdropPath: String?,
            voteAverage: Double,
            runtimeMinutes: Int?,
            directors: [StoredPerson],
            addedAt: Date
        ) {
            self.movieID = movieID
            self.title = title
            self.originalTitle = originalTitle
            self.overview = overview
            self.releaseDate = releaseDate
            self.posterPath = posterPath
            self.backdropPath = backdropPath
            self.voteAverage = voteAverage
            self.runtimeMinutes = runtimeMinutes
            self.directors = directors
            self.addedAt = addedAt
        }
    }
}
