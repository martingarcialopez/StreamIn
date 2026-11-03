import Testing
import Foundation
@testable import Domain

/// Pins how the curated free list matches: by id, or by name ignoring case
/// and accents, since a broadcaster's id differs per region.
@Suite struct FreeProvidersTests {

    private func provider(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
    }

    @Test func listedIdMatchesWhateverItsName() {
        #expect(FreeProviders.contains(provider(300, "Pluto TV")))
        #expect(FreeProviders.contains(provider(38, "BBC iPlayer (renamed)")))
    }

    /// RTVE's player has a different id in each region TMDB lists it in.
    @Test func listedNameMatchesWhateverItsId() {
        #expect(FreeProviders.contains(provider(9999, "RTVE Play")))
    }

    @Test func nameMatchIgnoresCaseAndAccents() {
        #expect(FreeProviders.contains(provider(9998, "ATRESPLAYER")))
        #expect(FreeProviders.contains(provider(9997, "Atresplayér")))
        #expect(FreeProviders.contains(provider(9996, "BBC iPlayer")))
    }

    /// Only the whole name counts: a paid tier whose name contains a free
    /// service's must stay pickable.
    @Test func partialNameDoesNotMatch() {
        #expect(!FreeProviders.contains(provider(9995, "Pluto TV Premium")))
    }

    @Test func paidServicesAreNotFree() {
        #expect(!FreeProviders.contains(provider(8, "Netflix")))
        #expect(!FreeProviders.contains(provider(337, "Disney Plus")))
        #expect(!FreeProviders.contains(provider(149, "Movistar Plus+")))
    }
}
