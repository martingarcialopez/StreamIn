import Testing
import Foundation
import Domain
@testable import TMDBClient

// MARK: - Test double

/// Simple in-memory TMDBClient. Each method returns whatever the test puts
/// into its `result` property; if untouched, the methods throw to flush out
/// accidental unexpected calls.
final class StubTMDBClient: TMDBClient, @unchecked Sendable {
    var watchProvidersResult: Result<TMDBWatchProvidersResponse, Error> = .failure(MovieError.unknown)
    var providerListResult: Result<TMDBProviderListResponse, Error> = .failure(MovieError.unknown)
    var providerListCallCount = 0
    var providerListLastWatchRegion: String?

    func searchMovies(query: String, page: Int) async throws -> TMDBSearchResponse {
        throw MovieError.unknown
    }
    func movieDetails(id: Int) async throws -> TMDBMovieDetailDTO {
        throw MovieError.unknown
    }
    func watchProviders(movieID: Int) async throws -> TMDBWatchProvidersResponse {
        try watchProvidersResult.get()
    }
    func providerList(watchRegion: String?) async throws -> TMDBProviderListResponse {
        providerListCallCount += 1
        providerListLastWatchRegion = watchRegion
        return try providerListResult.get()
    }
}

// MARK: - availabilities bundle (regional + global from one HTTP call)

@Suite struct AvailabilitiesBundleTests {

    /// Two regions, two overlapping providers — the adapter must collapse the
    /// duplicates into one entry per provider with both regions present.
    @Test func aggregatesGlobalAcrossRegions() async throws {
        let stub = StubTMDBClient()
        stub.watchProvidersResult = .success(
            TMDBWatchProvidersResponse(
                id: 27205,
                results: [
                    "US": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 8, providerName: "Netflix", logoPath: "/n.png", displayPriority: 1),
                            TMDBProviderDTO(providerId: 337, providerName: "Disney+", logoPath: nil, displayPriority: 5)
                        ],
                        rent: nil, buy: nil, free: nil
                    ),
                    "DE": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 9, providerName: "Amazon Prime Video", logoPath: nil, displayPriority: 2),
                            TMDBProviderDTO(providerId: 8, providerName: "Netflix", logoPath: "/n.png", displayPriority: 3)
                        ],
                        rent: nil, buy: nil, free: nil
                    )
                ]
            )
        )
        let repo = TMDBMovieRepository(client: stub)
        let bundle = try await repo.availabilities(for: MovieID(27205), in: .unitedStates)

        // Regional view reflects only the US slice.
        #expect(Set(bundle.regional.subscription.map(\.id)) == Set([ProviderID(8), ProviderID(337)]))

        // Global view aggregates: three distinct providers across the two regions.
        #expect(bundle.global.subscription.count == 3)

        // Netflix appears in both regions and should win the priority race
        // (best of 1 from US vs 3 from DE → 1), so it comes first in the sort.
        let netflix = try #require(bundle.global.subscription.first(where: { $0.provider.id == ProviderID(8) }))
        #expect(Set(netflix.regions.map(\.code)) == Set(["US", "DE"]))
        #expect(bundle.global.subscription[0].provider.id == ProviderID(8))
    }

    /// Anatomy-of-a-Fall pattern: Prime Video tagged as id 9 in some regions
    /// and id 119 in others. After the alias collapse, one entry whose
    /// `regions` covers everywhere.
    @Test func aliasedPrimeVideoMergesAcrossVariantIDs() async throws {
        let stub = StubTMDBClient()
        stub.watchProvidersResult = .success(
            TMDBWatchProvidersResponse(
                id: 915935,
                results: [
                    "JP": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 9, providerName: "Amazon Prime Video", logoPath: "/p.png", displayPriority: 1)
                        ],
                        rent: nil, buy: nil, free: nil
                    ),
                    "NI": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 119, providerName: "Amazon Prime Video", logoPath: "/p.png", displayPriority: 2)
                        ],
                        rent: nil, buy: nil, free: nil
                    ),
                    "PE": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 119, providerName: "Amazon Prime Video", logoPath: "/p.png", displayPriority: 3)
                        ],
                        rent: nil, buy: nil, free: nil
                    ),
                    "US": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: [
                            TMDBProviderDTO(providerId: 2100, providerName: "Amazon Prime Video with Ads", logoPath: "/p.png", displayPriority: 4)
                        ],
                        rent: nil, buy: nil, free: nil
                    )
                ]
            )
        )
        let repo = TMDBMovieRepository(client: stub)
        let bundle = try await repo.availabilities(for: MovieID(915935), in: .unitedStates)

        // One entry, not three.
        #expect(bundle.global.subscription.count == 1)
        let entry = try #require(bundle.global.subscription.first)
        // Canonical id wins.
        #expect(entry.provider.id == ProviderID(9))
        // Canonical metadata wins — the "with Ads" name from id 2100 doesn't
        // overwrite the plain "Amazon Prime Video" from id 9.
        #expect(entry.provider.name == "Amazon Prime Video")
        // All four regions present.
        #expect(Set(entry.regions.map(\.code)) == Set(["JP", "NI", "PE", "US"]))
    }

    /// Regions with no `flatrate` entry should be skipped from the global
    /// aggregation entirely (rent-only or buy-only regions don't contribute
    /// providers to v1's subscription view).
    @Test func globalSkipsRegionsWithoutFlatrate() async throws {
        let stub = StubTMDBClient()
        stub.watchProvidersResult = .success(
            TMDBWatchProvidersResponse(
                id: 1,
                results: [
                    "US": TMDBWatchProvidersRegionDTO(
                        link: nil,
                        flatrate: nil,
                        rent: [
                            TMDBProviderDTO(providerId: 99, providerName: "iTunes", logoPath: nil, displayPriority: 1)
                        ],
                        buy: nil, free: nil
                    )
                ]
            )
        )
        let repo = TMDBMovieRepository(client: stub)
        let bundle = try await repo.availabilities(for: MovieID(1), in: .unitedStates)
        #expect(bundle.global.subscription.isEmpty)
        // Regional rent is still surfaced.
        #expect(bundle.regional.rent.map(\.id) == [ProviderID(99)])
    }
}

// MARK: - allProviders / cache

@Suite struct AllProvidersTests {

    @Test func passesWatchRegionWhenSpecified() async throws {
        let stub = StubTMDBClient()
        stub.providerListResult = .success(TMDBProviderListResponse(results: []))
        let repo = TMDBMovieRepository(client: stub)
        _ = try await repo.allProviders(in: .spain)
        #expect(stub.providerListLastWatchRegion == "ES")
    }

    @Test func omitsWatchRegionForWorldwide() async throws {
        let stub = StubTMDBClient()
        stub.providerListResult = .success(TMDBProviderListResponse(results: []))
        let repo = TMDBMovieRepository(client: stub)
        _ = try await repo.allProviders(in: nil)
        #expect(stub.providerListLastWatchRegion == nil)
    }

    /// The catalog should expose Prime Video once even if TMDB returns
    /// multiple variant ids — and the row should use the canonical id 9 +
    /// the plain "Amazon Prime Video" name (not "with Ads").
    @Test func collapsesAliasedProvidersIntoOneRow() async throws {
        let stub = StubTMDBClient()
        stub.providerListResult = .success(
            TMDBProviderListResponse(results: [
                TMDBProviderListItemDTO(providerId: 119, providerName: "Amazon Prime Video", logoPath: nil, displayPriority: 5),
                TMDBProviderListItemDTO(providerId: 2100, providerName: "Amazon Prime Video with Ads", logoPath: nil, displayPriority: 6),
                TMDBProviderListItemDTO(providerId: 9, providerName: "Amazon Prime Video", logoPath: nil, displayPriority: 2),
                TMDBProviderListItemDTO(providerId: 8, providerName: "Netflix", logoPath: nil, displayPriority: 1)
            ])
        )
        let repo = TMDBMovieRepository(client: stub)
        let providers = try await repo.allProviders(in: nil)

        #expect(providers.count == 2)
        let prime = try #require(providers.first(where: { $0.id == ProviderID(9) }))
        #expect(prime.name == "Amazon Prime Video")
        // No leftover entry for 119 or 2100.
        #expect(providers.first(where: { $0.id == ProviderID(119) }) == nil)
        #expect(providers.first(where: { $0.id == ProviderID(2100) }) == nil)
    }

    /// The adapter never caches — that's `CachingMovieRepository`'s job.
    /// Every call should reach the client.
    @Test func noCacheHitsWireEachTime() async throws {
        let stub = StubTMDBClient()
        stub.providerListResult = .success(
            TMDBProviderListResponse(results: [
                TMDBProviderListItemDTO(providerId: 8, providerName: "Netflix", logoPath: nil, displayPriority: 1)
            ])
        )
        let repo = TMDBMovieRepository(client: stub)
        _ = try await repo.allProviders(in: nil)
        _ = try await repo.allProviders(in: nil)
        _ = try await repo.allProviders(in: .spain)
        #expect(stub.providerListCallCount == 3)
    }
}
