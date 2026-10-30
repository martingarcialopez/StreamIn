import Foundation
import Observation
import Domain
import Preferences
import ReferenceData
import DesignSystem

/// The landing page's slot machine: three reels (a trending movie, a
/// streaming service, a country) and where each one stops.
///
/// The reels are a generic mix, the same for everyone; only where they stop
/// is random, and a spin never lands on the combination already showing.
/// Nothing here fails loudly: without trending movies or provider logos, a
/// reel falls back to glyphs.
@MainActor
@Observable
public final class LandingViewModel {

    /// Movie, service and country, in that order.
    private(set) var reels: [[SlotSymbol]]
    /// The symbol index each reel shows on the winning line.
    private(set) var stops: [Int]
    /// Goes up with every spin, so the view knows to roll the reels.
    private(set) var spinCount = 0

    private let repository: MovieRepository
    private let catalog: ProviderCatalog
    private let prefs: Preferences
    private let imageURLBuilder: ImageURLBuilder
    private var random: AnyRandomNumberGenerator
    /// How long the first spin waits for its posters and logos before rolling anyway.
    private let imageWait: Duration
    private var hasLoaded = false

    /// Well-known services, by TMDB provider ID: Netflix, Prime Video,
    /// Disney+, Max, Apple TV+, Hulu, Paramount+, Peacock, Movistar Plus+,
    /// Filmin, MUBI, Crunchyroll.
    static let featuredServiceIDs: [ProviderID] = [
        8, 9, 337, 1899, 350, 15, 531, 386, 149, 63, 11, 283,
    ].map(ProviderID.init)
    /// Below this many featured services, the reel fills up from the
    /// worldwide catalog's most prominent ones.
    static let minimumServices = 6
    static let maximumPosters = 12
    static let countries: [Region] = [
        "US", "GB", "ES", "FR", "DE", "IT", "JP", "KR", "BR", "MX", "CA", "AU", "IN", "SE",
    ].map(Region.init(code:))

    public convenience init(
        repository: MovieRepository,
        catalog: ProviderCatalog,
        prefs: Preferences,
        imageURLBuilder: ImageURLBuilder
    ) {
        self.init(
            repository: repository,
            catalog: catalog,
            prefs: prefs,
            imageURLBuilder: imageURLBuilder,
            random: SystemRandomNumberGenerator(),
            imageWait: .seconds(1.5)
        )
    }

    init(
        repository: MovieRepository,
        catalog: ProviderCatalog,
        prefs: Preferences,
        imageURLBuilder: ImageURLBuilder,
        random: any RandomNumberGenerator,
        imageWait: Duration
    ) {
        self.repository = repository
        self.catalog = catalog
        self.prefs = prefs
        self.imageURLBuilder = imageURLBuilder
        self.random = AnyRandomNumberGenerator(base: random)
        self.imageWait = imageWait
        self.reels = [Self.movieGlyphs, Self.serviceGlyphs, Self.countrySymbols]
        self.stops = [0, 0, 0]
    }

    /// The names on the winning line: movie, service, country.
    var landed: [String] {
        zip(reels, stops).map { reel, stop in reel[stop].name }
    }

    /// Fills the reels and gives them a spin. Once trending movies have
    /// loaded, later calls do nothing, so returning to the page doesn't
    /// re-roll it. A load cancelled by leaving the page early, or one that
    /// fell back to glyphs because trending failed (offline), runs again on
    /// the next appearance.
    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        let trending = try? await repository.trendingMovies()
        await catalog.load(region: prefs.region)

        var movies = movieSymbols(from: trending ?? [])
        movies.shuffle(using: &random)
        var services = serviceSymbols()
        services.shuffle(using: &random)
        var countries = Self.countrySymbols
        countries.shuffle(using: &random)
        let filled = [
            movies.isEmpty ? Self.movieGlyphs : movies,
            services.isEmpty ? Self.serviceGlyphs : services,
            countries,
        ]
        let firstStops = nextStops(on: filled)
        await waitForImages(on: filled, at: firstStops)
        guard !Task.isCancelled else {
            hasLoaded = false
            return
        }

        // All at once, so the page swaps its stand-in reels for the real ones
        // as they start rolling.
        reels = filled
        stops = firstStops
        spinCount += 1
        if trending == nil {
            hasLoaded = false
        }
    }

    /// Rolls to a new combination, never the one showing now. Does nothing
    /// before the first load lands: the reels are stand-ins until then, about
    /// to be swapped for the real ones mid-roll.
    func spin() {
        guard spinCount > 0 else { return }
        stops = nextStops(on: reels)
        spinCount += 1
    }

    private func nextStops(on reels: [[SlotSymbol]]) -> [Int] {
        let canChange = reels.contains { $0.count > 1 }
        var next: [Int]
        repeat {
            next = reels.map { Int.random(in: $0.indices, using: &random) }
        } while canChange && next == stops
        return next
    }

    // MARK: - Reels

    private func movieSymbols(from movies: [Movie]) -> [SlotSymbol] {
        let withPosters = movies.compactMap { movie -> SlotSymbol? in
            guard let path = movie.posterPath,
                  let url = imageURLBuilder.url(for: path, size: .poster) else { return nil }
            return SlotSymbol(face: .poster(url), name: movie.title)
        }
        return Array(withPosters.prefix(Self.maximumPosters))
    }

    private func serviceSymbols() -> [SlotSymbol] {
        var providers = Self.featuredServiceIDs.compactMap(catalog.provider(id:))
        if providers.count < Self.minimumServices, let worldwide = catalog.providers(in: nil) {
            let missing = Self.minimumServices - providers.count
            let featured = Set(providers.map(\.id))
            providers += worldwide.filter { !featured.contains($0.id) }.prefix(missing)
        }
        return providers.map { provider in
            SlotSymbol(
                face: .logo(provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }),
                name: provider.name
            )
        }
    }

    private static var countrySymbols: [SlotSymbol] {
        countries.map { SlotSymbol(face: .flag($0.flag), name: $0.displayName) }
    }

    private static var movieGlyphs: [SlotSymbol] {
        [Symbol.film, Symbol.popcornFill, Symbol.ticketFill, Symbol.movieclapper].map {
            SlotSymbol(face: .glyph($0), name: String(localized: .searchLandingSlotAnyMovie))
        }
    }

    private static var serviceGlyphs: [SlotSymbol] {
        [Symbol.playTVFill, Symbol.tvFill].map {
            SlotSymbol(face: .glyph($0), name: String(localized: .searchLandingSlotAnyService))
        }
    }

    // MARK: - Images

    /// Starts loading every image on the reels, then waits (briefly) for the
    /// ones the first spin lands on, so it doesn't stop on a placeholder.
    private func waitForImages(on reels: [[SlotSymbol]], at stops: [Int]) async {
        let all = reels.flatMap { $0.compactMap(\.imageURL) }
        RemoteImageStore.shared.prefetch(all)

        let landing = zip(reels, stops).compactMap { reel, stop in reel[stop].imageURL }
        let deadline = ContinuousClock.now + imageWait
        while landing.contains(where: { RemoteImageStore.shared.image(for: $0) == nil }),
              ContinuousClock.now < deadline {
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return
            }
        }
    }
}

/// Lets an injected generator (seeded in tests) drive the standard library's
/// `random(in:using:)` and `shuffle(using:)`, which need a concrete type.
private struct AnyRandomNumberGenerator: RandomNumberGenerator {
    var base: any RandomNumberGenerator

    mutating func next() -> UInt64 {
        base.next()
    }
}

private extension SlotSymbol {
    var imageURL: URL? {
        switch face {
        case .poster(let url), .logo(let url): url
        case .flag, .glyph: nil
        }
    }
}
