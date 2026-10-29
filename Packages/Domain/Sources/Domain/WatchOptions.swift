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
    /// The user's services that carry the film outside the home region, each
    /// with only those other regions, in TMDB's order. Services whose only
    /// region is home aren't here.
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
            let others = entry.regions.filter { $0 != home }
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
