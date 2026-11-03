//
//  CatalogScope.swift
//  Domain
//
//  Whether a VPN to another country gives a subscriber that country's
//  catalogue. Netflix picks the catalogue from where you connect; Prime Video
//  picks it from the Amazon account's country, so a new IP alone unlocks
//  nothing. The research behind each entry, with sources, is in
//  docs/roadmap.md → "Catalogue scope".
//

/// What picks the catalogue a subscriber sees on a streaming service.
public enum CatalogScope: Sendable {
    /// The country the user connects from: a VPN brings that country's
    /// catalogue with the account they already have.
    case location
    /// The country of the account (billing or registration): a VPN doesn't
    /// change it.
    case account

    /// The scope of `provider`'s brand. A service that isn't in the table is
    /// `.account`, so the app never promises a catalogue a VPN won't unlock.
    public static func of(_ provider: ProviderID) -> CatalogScope {
        scopes[ProviderAliases.canonical(provider)] ?? .account
    }

    /// Keyed by canonical id (`ProviderAliases`). Entries marked "unverified"
    /// have no source either way and stay `.account` until one turns up.
    private static let scopes: [ProviderID: CatalogScope] = [
        ProviderID(8): .location,    // Netflix
        ProviderID(122): .location,  // Disney+
        ProviderID(384): .location,  // HBO Max (legacy id)
        ProviderID(1899): .location, // HBO Max
        ProviderID(283): .location,  // Crunchyroll
        ProviderID(300): .location,  // Pluto TV: free, no account

        ProviderID(9): .account,     // Prime Video
        ProviderID(350): .account,   // Apple TV+
        ProviderID(531): .account,   // Paramount+: location, except that only US accounts reach the US catalogue
        ProviderID(149): .account,   // Movistar Plus+: Spain and the EEA, home catalogue
        ProviderID(386): .account,   // Peacock: US only
        ProviderID(1773): .account,  // SkyShowtime: EEA only, home catalogue
        ProviderID(63): .account,    // Filmin: Spanish subscriptions, Europe only, home catalogue
        ProviderID(510): .account,   // Discovery+: tied to the sign-up country
        ProviderID(381): .account,   // Canal+: blocked outside the EU, home catalogue inside
        ProviderID(43): .account,    // Starz / STARZPLAY / Lionsgate Play (unverified)
    ]
}
