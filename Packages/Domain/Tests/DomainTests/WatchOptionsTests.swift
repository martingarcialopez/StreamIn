import Testing
import Foundation
import Domain

@Suite struct WatchOptionsTests {

    private let netflix = provider(8, "Netflix")
    private let prime = provider(9, "Prime Video")
    private let disney = provider(337, "Disney+")
    private let rtve = provider(541, "RTVE Play")

    @Test func yoursAtHomeComeFromTheGlobalMatrix() {
        let options = WatchOptions(
            bundle: bundle(global: [
                ProviderRegionalAvailability(provider: prime, regions: [.spain, .france]),
                ProviderRegionalAvailability(provider: netflix, regions: [Region(code: "JP")]),
                ProviderRegionalAvailability(provider: disney, regions: [.spain]),
            ]),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(9)]
        )

        #expect(options.yoursAtHome == [prime])
    }

    @Test func watchNowListsYoursThenFreeWithoutDuplicates() {
        let options = WatchOptions(
            bundle: bundle(
                free: [rtve, prime],
                global: [
                    ProviderRegionalAvailability(provider: netflix, regions: [.spain]),
                    ProviderRegionalAvailability(provider: prime, regions: [.spain]),
                ]
            ),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(9)]
        )

        #expect(options.watchNow == [netflix, prime, rtve])
    }

    @Test func yoursAbroadDropHomeAndHomeOnlyServices() {
        let options = WatchOptions(
            bundle: bundle(global: [
                ProviderRegionalAvailability(provider: prime, regions: [.spain, .france, .germany]),
                ProviderRegionalAvailability(provider: netflix, regions: [.spain]),
            ]),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(9)]
        )

        #expect(options.yoursAbroad == [
            ProviderRegionalAvailability(provider: prime, regions: [.france, .germany])
        ])
    }

    @Test func othersAtHomeDropYoursAndFreeAndKeepOrder() {
        let options = WatchOptions(
            bundle: bundle(
                subscription: [disney, netflix, prime],
                free: [prime],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.spain])]
            ),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.othersAtHome == [disney])
        #expect(options.streamsAtHome)
    }

    /// After a region change, the old region's free and other services
    /// aren't home's.
    @Test func regionalProvidersOfAnotherRegionAreIgnored() {
        let options = WatchOptions(
            bundle: bundle(region: .spain, subscription: [disney], free: [rtve]),
            home: .unitedStates,
            subscribed: []
        )

        #expect(options.freeAtHome.isEmpty)
        #expect(options.othersAtHome.isEmpty)
        #expect(!options.streamsAtHome)
    }

    @Test func rentAndBuyDontCount() {
        let options = WatchOptions(
            bundle: bundle(rent: [netflix], buy: [prime]),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(9)]
        )

        #expect(options.watchNow.isEmpty)
        #expect(options.yoursAbroad.isEmpty)
        #expect(!options.streamsAtHome)
    }

    private func bundle(
        region: Region = .spain,
        subscription: [WatchProvider] = [],
        rent: [WatchProvider] = [],
        buy: [WatchProvider] = [],
        free: [WatchProvider] = [],
        global: [ProviderRegionalAvailability] = []
    ) -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: MovieID(1), region: region,
                subscription: subscription, rent: rent, buy: buy, free: free, externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: MovieID(1), subscription: global)
        )
    }
}

private func provider(_ id: Int, _ name: String) -> WatchProvider {
    WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
}
