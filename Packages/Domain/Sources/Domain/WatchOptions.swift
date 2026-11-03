//
//  WatchOptions.swift
//  Domain
//

/// Where a film streams, seen from the home region and the user's services:
/// the one reading of an `AvailabilityBundle` that Details and the search
/// results share, so both list providers in the same order. Free and
/// subscription only; rent and buy aren't shown in v1.
public struct WatchOptions: Equatable, Sendable {
    /// The user's services that carry the film at home, in TMDB's order.
    public let yoursAtHome: [WatchProvider]
    /// Free providers at home.
    public let freeAtHome: [WatchProvider]
    /// The user's services that carry the film in regions a VPN can reach,
    /// each with only those regions, in TMDB's order. Only services whose
    /// catalogue follows the location count (`CatalogScope`), and from an EEA
    /// home the rest of the EEA doesn't (`Region.reachesCatalogue(in:)`).
    public let yoursAbroad: [ProviderRegionalAvailability]
    /// Home subscription providers that aren't the user's and aren't free.
    public let othersAtHome: [WatchProvider]

    /// The regional half of `bundle` counts only when it's `home`'s, so
    /// after a region change the old region's providers aren't read as home.
    public init(bundle: AvailabilityBundle, home: Region, subscribed: Set<ProviderID>) {
        let yours = bundle.global.subscription.filter { subscribed.contains($0.provider.id) }
        let regional = bundle.regional.region == home ? bundle.regional : nil

        yoursAtHome = yours.filter { $0.regions.contains(home) }.map(\.provider)
        freeAtHome = regional?.free ?? []
        yoursAbroad = yours.compactMap { entry in
            guard CatalogScope.of(entry.provider.id) == .location else { return nil }
            let others = entry.regions.filter(home.reachesCatalogue(in:))
            guard !others.isEmpty else { return nil }
            return ProviderRegionalAvailability(provider: entry.provider, regions: others)
        }
        let excluded = Set((yoursAtHome + freeAtHome).map(\.id))
        othersAtHome = (regional?.subscription ?? []).filter { !excluded.contains($0.id) }
    }

    /// What the user can watch on at home: their services, then free ones,
    /// each provider once.
    public var watchNow: [WatchProvider] {
        var seen = Set<ProviderID>()
        return (yoursAtHome + freeAtHome).filter { seen.insert($0.id).inserted }
    }

    /// Whether any subscription or free service carries the film at home,
    /// the user's or not.
    public var streamsAtHome: Bool {
        !yoursAtHome.isEmpty || !freeAtHome.isEmpty || !othersAtHome.isEmpty
    }
}
