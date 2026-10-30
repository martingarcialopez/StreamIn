import Testing
import Foundation
import Domain
import ReferenceData
@testable import SearchFeature

@MainActor
@Suite("LandingViewModel")
struct LandingViewModelTests {

    private func makeModel(
        trending: Result<[Movie], MovieError> = .success([]),
        providers: [WatchProvider] = [],
        seed: UInt64 = 1
    ) -> LandingViewModel {
        let repository = FakeMovieRepository(trending: trending, providers: providers)
        return LandingViewModel(
            repository: repository,
            catalog: ProviderCatalog(repository: repository),
            prefs: makePrefs(),
            imageURLBuilder: TestImageURLBuilder(),
            random: SeededGenerator(seed: seed),
            imageWait: .zero
        )
    }

    private static let featured: [WatchProvider] = [.netflix, .disneyPlus, .filmin, .fixture(9, "Prime Video"),
                                                    .fixture(1899, "Max"), .fixture(350, "Apple TV+")]

    @Test func movieReelShowsTrendingPostersByTitle() async {
        let model = makeModel(trending: .success([
            .withPoster(1, "Dune"), .fixture(2), .withPoster(3, "Wicked"),
        ]))

        await model.load()

        #expect(Set(model.reels[0].map(\.name)) == ["Dune", "Wicked"])
        #expect(model.reels[0].allSatisfy { if case .poster = $0.face { true } else { false } })
    }

    @Test func movieReelKeepsAtMostTwelvePosters() async {
        let movies = (1...20).map { Movie.withPoster($0, "Movie \($0)") }
        let model = makeModel(trending: .success(movies))

        await model.load()

        #expect(model.reels[0].count == LandingViewModel.maximumPosters)
    }

    @Test func movieReelFallsBackToGlyphsWhenTrendingFails() async {
        let model = makeModel(trending: .failure(.offline))

        await model.load()

        #expect(!model.reels[0].isEmpty)
        #expect(model.reels[0].allSatisfy { if case .glyph = $0.face { true } else { false } })
    }

    @Test func serviceReelShowsFeaturedServices() async {
        let model = makeModel(providers: Self.featured + [.rtvePlay])

        await model.load()

        #expect(Set(model.reels[1].map(\.name)) == Set(Self.featured.map(\.name)))
    }

    @Test func serviceReelFillsUpFromTheCatalog() async {
        let others = (1...10).map { WatchProvider.fixture(10_000 + $0, "Other \($0)") }
        let model = makeModel(providers: [.netflix, .disneyPlus] + others)

        await model.load()

        let names = model.reels[1].map(\.name)
        #expect(names.count == LandingViewModel.minimumServices)
        #expect(names.contains("Netflix"))
        #expect(names.contains("Disney Plus"))
    }

    @Test func serviceReelFallsBackToGlyphsWithoutACatalog() async {
        let model = makeModel(providers: [])

        await model.load()

        #expect(model.reels[1].allSatisfy { if case .glyph = $0.face { true } else { false } })
    }

    @Test func countryReelShowsFlags() async {
        let model = makeModel()

        await model.load()

        #expect(model.reels[2].count == LandingViewModel.countries.count)
        #expect(model.reels[2].contains { $0.face == .flag(Region.spain.flag) })
    }

    @Test func loadGivesTheFirstSpinOnce() async {
        let model = makeModel(providers: Self.featured)

        await model.load()
        let stops = model.stops
        await model.load()

        #expect(model.spinCount == 1)
        #expect(model.stops == stops)
    }

    @Test(arguments: [1, 2, 3] as [UInt64])
    func spinNeverRepeatsTheCombinationShowing(seed: UInt64) async {
        let model = makeModel(providers: Self.featured, seed: seed)
        await model.load()

        for _ in 0..<50 {
            let before = model.stops
            model.spin()
            #expect(model.stops != before)
        }
        #expect(model.spinCount == 51)
    }

    @Test func landedNamesTheSymbolsOnTheLine() async {
        let model = makeModel(trending: .success([.withPoster(1, "Dune")]), providers: [.netflix])

        await model.load()

        let expected = zip(model.reels, model.stops).map { $0[$1].name }
        #expect(model.landed == expected)
        #expect(model.landed[0] == "Dune")
    }

    @Test func spinBeforeTheFirstLoadDoesNothing() async {
        let model = makeModel(providers: Self.featured)

        model.spin()
        #expect(model.spinCount == 0)
        #expect(model.stops == [0, 0, 0])

        await model.load()
        #expect(model.spinCount == 1)
    }

    @Test func offlineLoadRunsAgainOnTheNextAppearance() async {
        let model = makeModel(trending: .failure(.offline), providers: Self.featured)

        await model.load()
        await model.load()

        #expect(model.spinCount == 2)
    }

    @Test func cancelledLoadRunsAgainOnTheNextAppearance() async {
        let model = makeModel(providers: Self.featured)

        let leftEarly = Task { await model.load() }
        leftEarly.cancel()
        await leftEarly.value
        #expect(model.spinCount == 0)

        await model.load()
        #expect(model.spinCount == 1)
    }
}

/// URLs no session can load, so prefetching fails fast and offline.
private struct TestImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? {
        URL(string: "test://image\(path.rawValue)")
    }
}

/// SplitMix64: a deterministic generator, so a failing seed reproduces.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private extension Movie {
    static func withPoster(_ id: Int, _ title: String) -> Movie {
        Movie(
            id: MovieID(id),
            title: title,
            originalTitle: title,
            overview: "",
            releaseDate: nil,
            posterPath: ImagePath("/\(id).jpg"),
            backdropPath: nil,
            voteAverage: 0,
            runtime: nil
        )
    }
}
