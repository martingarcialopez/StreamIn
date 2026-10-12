//
//  WatchlistEntry+Mapping.swift
//  Persistence
//
//  Domain ↔ storage. The runtime is stored in whole minutes, the unit TMDB
//  provides it in.
//

import Foundation
import Domain

extension WatchlistEntry {

    convenience init(_ item: WatchlistItem) {
        self.init(
            movieID: item.movie.id.rawValue,
            title: "",
            originalTitle: "",
            overview: "",
            releaseDate: nil,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            runtimeMinutes: nil,
            directors: [],
            addedAt: item.addedAt
        )
        update(from: item)
    }

    /// Overwrites every field with `item`'s, `addedAt` included.
    func update(from item: WatchlistItem) {
        let movie = item.movie
        title = movie.title
        originalTitle = movie.originalTitle
        overview = movie.overview
        releaseDate = movie.releaseDate
        posterPath = movie.posterPath?.rawValue
        backdropPath = movie.backdropPath?.rawValue
        voteAverage = movie.voteAverage
        runtimeMinutes = movie.runtime.map { Int($0.components.seconds / 60) }
        directors = movie.directors.map {
            StoredPerson(id: $0.id.rawValue, name: $0.name, profilePath: $0.profilePath?.rawValue)
        }
        addedAt = item.addedAt
    }

    var item: WatchlistItem {
        WatchlistItem(
            movie: Movie(
                id: MovieID(movieID),
                title: title,
                originalTitle: originalTitle,
                overview: overview,
                releaseDate: releaseDate,
                posterPath: posterPath.map(ImagePath.init),
                backdropPath: backdropPath.map(ImagePath.init),
                voteAverage: voteAverage,
                runtime: runtimeMinutes.map { .seconds($0 * 60) },
                directors: directors.map {
                    Person(id: PersonID($0.id), name: $0.name, profilePath: $0.profilePath.map(ImagePath.init))
                }
            ),
            addedAt: addedAt
        )
    }
}
