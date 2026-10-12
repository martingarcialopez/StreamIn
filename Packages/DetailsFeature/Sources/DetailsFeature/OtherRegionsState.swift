//
//  OtherRegionsState.swift
//  DetailsFeature
//

/// What the "Other regions" section shows.
public enum OtherRegionsState: Equatable, Sendable {
    /// No services, still loading, failed, or available at home only.
    case hidden
    /// The user's services carry the film nowhere.
    case noMatches
    /// The user's services carry it in other regions.
    case available
}
