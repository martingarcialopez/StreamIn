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
                ProviderRegionalAvailability(provider: netflix, regions: [.spain, .unitedStates, .japan]),
                ProviderRegionalAvailability(provider: disney, regions: [.spain]),
            ]),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(337)]
        )

        #expect(options.yoursAbroad == [
            ProviderRegionalAvailability(provider: netflix, regions: [.unitedStates, .japan])
        ])
    }

    // MARK: - Catalogue scope

    /// Netflix's catalogue follows where you connect from.
    @Test func locationScopedServiceAbroadCounts() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: netflix, regions: [.unitedStates])]),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.yoursAbroad == [ProviderRegionalAvailability(provider: netflix, regions: [.unitedStates])])
    }

    /// Prime Video's catalogue follows the Amazon account's country.
    @Test func accountScopedServiceAbroadDoesntCount() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: prime, regions: [.unitedStates])]),
            home: .spain,
            subscribed: [ProviderID(9)]
        )

        #expect(options.yoursAbroad.isEmpty)
        #expect(options.summary == .notStreamingHere)
    }

    @Test func onlyLocationScopedServicesCountWhenBothCarryIt() {
        let options = WatchOptions(
            bundle: bundle(global: [
                ProviderRegionalAvailability(provider: prime, regions: [.unitedStates]),
                ProviderRegionalAvailability(provider: netflix, regions: [.japan]),
            ]),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(9)]
        )

        #expect(options.summary == .abroad([netflix]))
    }

    /// A service nobody has checked might be account-scoped, so it isn't
    /// promised abroad.
    @Test func unknownServiceAbroadDoesntCount() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: rtve, regions: [.unitedStates])]),
            home: .spain,
            subscribed: [ProviderID(541)]
        )

        #expect(options.yoursAbroad.isEmpty)
    }

    /// The scope only matters abroad: at home the account's country is home.
    @Test func accountScopedServiceAtHomeIsWatchNow() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: prime, regions: [.spain, .unitedStates])]),
            home: .spain,
            subscribed: [ProviderID(9)]
        )

        #expect(options.summary == .atHome([prime]))
        #expect(options.yoursAbroad.isEmpty)
    }

    // MARK: - EU portability

    /// From an EEA home, the rest of the EEA shows the home catalogue.
    @Test func otherEEARegionsDontCountFromAnEEAHome() {
        let options = WatchOptions(
            bundle: bundle(global: [
                ProviderRegionalAvailability(provider: netflix, regions: [.france, .germany, .unitedKingdom]),
            ]),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.yoursAbroad == [ProviderRegionalAvailability(provider: netflix, regions: [.unitedKingdom])])
    }

    @Test func onlyEEARegionsFromAnEEAHomeIsNotAbroad() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: netflix, regions: [.france])]),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.summary == .notStreamingHere)
    }

    /// Portability is for EEA residents; the UK left with Brexit.
    @Test func eeaRegionsCountFromOutsideTheEEA() {
        let options = WatchOptions(
            bundle: bundle(global: [ProviderRegionalAvailability(provider: netflix, regions: [.france, .germany])]),
            home: .unitedKingdom,
            subscribed: [ProviderID(8)]
        )

        #expect(options.yoursAbroad == [ProviderRegionalAvailability(provider: netflix, regions: [.france, .germany])])
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

    // MARK: - Summary

    @Test func summaryIsWatchNowWhenYoursOrFreeCarryItAtHome() {
        let options = WatchOptions(
            bundle: bundle(
                free: [rtve],
                global: [
                    ProviderRegionalAvailability(provider: netflix, regions: [.spain]),
                    ProviderRegionalAvailability(provider: disney, regions: [.unitedStates]),
                ]
            ),
            home: .spain,
            subscribed: [ProviderID(8), ProviderID(337)]
        )

        #expect(options.summary == .atHome([netflix, rtve]))
    }

    @Test func summaryIsFreeAtHomeWithoutServices() {
        let options = WatchOptions(bundle: bundle(free: [rtve]), home: .spain, subscribed: [])

        #expect(options.summary == .atHome([rtve]))
    }

    @Test func summaryIsAbroadWhenOnlyYourServicesElsewhereCarryIt() {
        let options = WatchOptions(
            bundle: bundle(
                subscription: [disney],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.unitedStates])]
            ),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.summary == .abroad([netflix]))
    }

    @Test func summaryIsOthersAtHomeWhenOnlyOthersCarryItAtHome() {
        let options = WatchOptions(
            bundle: bundle(subscription: [disney, prime]),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.summary == .othersAtHome([disney, prime]))
    }

    /// Yours abroad beat the others at home.
    @Test func summaryIsAbroadEvenWhenOthersCarryItAtHome() {
        let options = WatchOptions(
            bundle: bundle(
                subscription: [disney],
                global: [ProviderRegionalAvailability(provider: netflix, regions: [.unitedStates])]
            ),
            home: .spain,
            subscribed: [ProviderID(8)]
        )

        #expect(options.summary == .abroad([netflix]))
    }

    @Test func summaryIsOthersAtHomeWithoutServices() {
        let options = WatchOptions(bundle: bundle(subscription: [disney]), home: .spain, subscribed: [])

        #expect(options.summary == .othersAtHome([disney]))
    }

    @Test func summaryIsNotStreamingHereWhenNothingCarriesItAtHome() {
        let options = WatchOptions(bundle: bundle(rent: [netflix]), home: .spain, subscribed: [ProviderID(8)])

        #expect(options.summary == .notStreamingHere)
    }

    /// A bundle fetched for the old region says nothing about the new one.
    @Test func summaryIgnoresAnotherRegionsProviders() {
        let options = WatchOptions(
            bundle: bundle(region: .spain, subscription: [disney], free: [rtve]),
            home: .unitedStates,
            subscribed: []
        )

        #expect(options.summary == .notStreamingHere)
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

private extension Region {
    static let japan = Region(code: "JP")
}

private func provider(_ id: Int, _ name: String) -> WatchProvider {
    WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
}
