import Testing
import Domain

@Suite struct CatalogScopeTests {

    @Test func netflixFollowsTheLocation() {
        #expect(CatalogScope.of(ProviderID(8)) == .location)
    }

    @Test func primeVideoFollowsTheAccount() {
        #expect(CatalogScope.of(ProviderID(9)) == .account)
    }

    /// Tier and spelling variants share their brand's scope.
    @Test func aliasesShareTheirBrandsScope() {
        #expect(CatalogScope.of(ProviderID(1796)) == .location) // Netflix Standard with Ads
        #expect(CatalogScope.of(ProviderID(337)) == .location)  // "Disney Plus"
        #expect(CatalogScope.of(ProviderID(119)) == .account)   // Prime Video, Latin America id
        #expect(CatalogScope.of(ProviderID(1965)) == .location) // Pluto TV Live
    }

    @Test func unknownServicesFollowTheAccount() {
        #expect(CatalogScope.of(ProviderID(541)) == .account) // RTVE Play
    }

    // MARK: - EU portability

    @Test func eeaIncludesEUAndEFTAMembersButNotTheUK() {
        #expect(Region.spain.isInEEA)
        #expect(Region(code: "NO").isInEEA)
        #expect(!Region.unitedKingdom.isInEEA)
        #expect(!Region.unitedStates.isInEEA)
    }

    @Test func homeNeverReachesItsOwnCatalogueAbroad() {
        #expect(!Region.unitedStates.reachesCatalogue(in: .unitedStates))
    }

    @Test func eeaHomeReachesOnlyNonEEACatalogues() {
        #expect(!Region.spain.reachesCatalogue(in: .france))
        #expect(Region.spain.reachesCatalogue(in: .unitedKingdom))
        #expect(Region.unitedKingdom.reachesCatalogue(in: .france))
    }
}
