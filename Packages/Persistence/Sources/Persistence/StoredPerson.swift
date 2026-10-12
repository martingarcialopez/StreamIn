//
//  StoredPerson.swift
//  Persistence
//

/// A director as stored inside `WatchlistEntry`. A Codable value rather than a
/// related model: directors are only ever read with their movie.
struct StoredPerson: Codable, Hashable {
    var id: Int
    var name: String
    var profilePath: String?
}
