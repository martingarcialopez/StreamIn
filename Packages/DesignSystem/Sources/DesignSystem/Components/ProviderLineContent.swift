import Foundation

/// What a list row's `ProviderLine` shows.
public enum ProviderLineContent<Provider: Identifiable>: Equatable {
    /// Availability hasn't arrived yet.
    case loading
    /// Up to three logos and "+N"; `abroad` puts a still globe before them.
    case logos([Provider], abroad: Bool)
    /// A quiet line of text, from the caller's String Catalog.
    case caption(LocalizedStringResource)

    /// Providers by ID and captions by key: enough to tell when the line
    /// changes, which is all its animation needs.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            true
        case let (.logos(lhsProviders, lhsAbroad), .logos(rhsProviders, rhsAbroad)):
            lhsAbroad == rhsAbroad && lhsProviders.map(\.id) == rhsProviders.map(\.id)
        case let (.caption(lhsText), .caption(rhsText)):
            lhsText.key == rhsText.key
        default:
            false
        }
    }
}
