//
//  Region+Portability.swift
//  Domain
//

extension Region {
    /// Whether a VPN to `other` gives a subscriber whose home is this region a
    /// paid service's catalogue other than home's. EU portability
    /// (Regulation (EU) 2017/1128) makes paid services show an EEA resident
    /// their home catalogue anywhere else in the EEA, so a VPN to another EEA
    /// country brings back the home catalogue, not that country's.
    public func reachesCatalogue(in other: Region) -> Bool {
        other != self && !(isInEEA && other.isInEEA)
    }

    /// EU member states plus Iceland, Liechtenstein and Norway. The United
    /// Kingdom left with Brexit.
    public var isInEEA: Bool { Self.eeaCodes.contains(code) }

    private static let eeaCodes: Set<String> = [
        "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "ES", "FI",
        "FR", "GR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
        "NL", "PL", "PT", "RO", "SE", "SI", "SK",
        "IS", "LI", "NO",
    ]
}
