import Foundation
import Domain

// MARK: - Adapter: TMDBClient -> MovieRepository
//
// This is where TMDB's vocabulary is translated into the Domain's vocabulary.
// Anything Domain code shouldn't have to know about (snake_case, nullable
// fields that are actually empty strings, the magic word "flatrate") dies here.

public struct TMDBMovieRepository: MovieRepository {
    private let client: TMDBClient

    // No caching here: every call reaches the client. Caching is layered on
    // by `CachingMovieRepository` so this adapter stays a pure translation.

    /// TMDB returns release dates as plain `yyyy-MM-dd` strings (no time, no zone).
    /// We parse them in UTC so a date doesn't shift by a day depending on where
    /// the device is. Modern `Date.ISO8601FormatStyle` covers this exactly: the
    /// builder `.year().month().day()` accepts the date-only form, and the
    /// default `timeZone: .gmt` makes the assumed midnight unambiguous.
    private static let releaseDateStrategy = Date.ISO8601FormatStyle(timeZone: .gmt)
        .year().month().day()

    public init(client: TMDBClient) {
        self.client = client
    }

    public func searchMovies(query: String, page: Int) async throws -> SearchPage {
        let response = try await mapErrors {
            try await client.searchMovies(query: query, page: page)
        }
        return SearchPage(
            query: query,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: response.results.map(map(dto:))
        )
    }

    public func movie(id: MovieID) async throws -> Movie {
        let dto = try await mapErrors {
            try await client.movieDetails(id: id.rawValue)
        }
        return Movie(
            id: MovieID(dto.id),
            title: dto.title,
            originalTitle: dto.originalTitle,
            overview: dto.overview,
            releaseDate: parseDate(dto.releaseDate),
            posterPath: dto.posterPath.map(ImagePath.init),
            backdropPath: dto.backdropPath.map(ImagePath.init),
            voteAverage: dto.voteAverage,
            runtime: dto.runtime.map { Duration.seconds($0 * 60) },
            directors: extractDirectors(from: dto.credits)
        )
    }

    public func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        let response = try await mapErrors {
            try await client.watchProviders(movieID: id.rawValue)
        }
        return mapRegional(response: response, id: id, region: region)
    }

    public func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        // One HTTP call. The response contains the full per-region matrix, so
        // we derive both the regional view and the cross-region aggregation
        // from the same payload.
        let response = try await mapErrors {
            try await client.watchProviders(movieID: id.rawValue)
        }
        return AvailabilityBundle(
            regional: mapRegional(response: response, id: id, region: region),
            global: aggregateGlobal(response: response, id: id)
        )
    }

    public func allProviders(in region: Region?) async throws -> [WatchProvider] {
        let response = try await mapErrors {
            try await client.providerList(watchRegion: region?.code)
        }
        // Aliased variants (e.g. Prime Video ids 9 / 119 / 2100) collapse into
        // a single row under the canonical id and name.
        let providers = response.results.map { dto in
            WatchProvider(
                id: ProviderID(dto.providerId),
                name: dto.providerName,
                logoPath: dto.logoPath.map(ImagePath.init),
                priority: dto.displayPriority
            )
        }
        return ProviderAliases.merging(providers).sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - Private mapping

    private func map(dto: TMDBMovieDTO) -> Movie {
        Movie(
            id: MovieID(dto.id),
            title: dto.title,
            originalTitle: dto.originalTitle,
            overview: dto.overview,
            releaseDate: parseDate(dto.releaseDate),
            posterPath: dto.posterPath.map(ImagePath.init),
            backdropPath: dto.backdropPath.map(ImagePath.init),
            voteAverage: dto.voteAverage,
            runtime: nil
        )
    }

    private func map(dto: TMDBProviderDTO) -> WatchProvider {
        WatchProvider(
            id: ProviderID(dto.providerId),
            name: dto.providerName,
            logoPath: dto.logoPath.map(ImagePath.init),
            priority: dto.displayPriority
        )
    }

    // MARK: - Watch-providers response mapping
    //
    // Both helpers consume the same raw TMDB response. Pulled out so the single-
    // call `availabilities(...)` and the still-supported `availability(...)`
    // share their logic without duplicating mapping code.

    private func mapRegional(
        response: TMDBWatchProvidersResponse,
        id: MovieID,
        region: Region
    ) -> WatchAvailability {
        let regional = response.results[region.code]
        return WatchAvailability(
            movieID: id,
            region: region,
            subscription: providers(regional?.flatrate),
            rent: providers(regional?.rent),
            buy: providers(regional?.buy),
            free: providers(regional?.free),
            externalLink: regional?.link.flatMap(URL.init(string:))
        )
    }

    /// One entry per brand: TMDB often lists aliased ids side by side in one
    /// region (Netflix 8 and "Netflix Standard with Ads" 1796), which would
    /// otherwise show the same logo twice.
    private func providers(_ dtos: [TMDBProviderDTO]?) -> [WatchProvider] {
        ProviderAliases.merging((dtos ?? []).map(map(dto:)))
    }

    /// Walk every region's flatrate list; accumulate per-provider region sets.
    /// Keyed by *canonical* provider id so aliased TMDB variants (Prime Video
    /// ids 9 / 119 / 2100) merge into a single entry whose `regions` covers
    /// every country where the brand appears under any variant.
    ///
    /// When two variants of the same brand appear, we keep the metadata
    /// (name, logo) from whichever DTO had the canonical id originally — the
    /// "Amazon Prime Video" entry beats "Amazon Prime Video with Ads" — and
    /// fall back to the first-seen DTO if no canonical-id DTO ever shows up.
    /// Lowest TMDB priority across regions wins for the per-provider sort key.
    private func aggregateGlobal(
        response: TMDBWatchProvidersResponse,
        id: MovieID
    ) -> GlobalWatchAvailability {
        struct Accumulator {
            var provider: WatchProvider
            /// True once we've seen a DTO whose original id matched the
            /// canonical — locks the metadata so a later variant-only DTO
            /// can't downgrade the name to e.g. "with Ads".
            var hasCanonicalMetadata: Bool
            var regions: Set<Region> = []
            var bestPriority: Int
        }
        var byCanonical: [ProviderID: Accumulator] = [:]

        for (regionCode, regional) in response.results {
            guard let flatrate = regional.flatrate, !flatrate.isEmpty else { continue }
            let region = Region(code: regionCode)
            for dto in flatrate {
                let originalID = ProviderID(dto.providerId)
                let canonicalID = ProviderAliases.canonical(originalID)
                let isCanonicalOriginal = (originalID == canonicalID)
                let provider = WatchProvider(
                    id: canonicalID,
                    name: dto.providerName,
                    logoPath: dto.logoPath.map(ImagePath.init),
                    priority: dto.displayPriority
                )
                if var existing = byCanonical[canonicalID] {
                    existing.regions.insert(region)
                    existing.bestPriority = min(existing.bestPriority, dto.displayPriority)
                    if isCanonicalOriginal && !existing.hasCanonicalMetadata {
                        existing.provider = provider
                        existing.hasCanonicalMetadata = true
                    }
                    byCanonical[canonicalID] = existing
                } else {
                    byCanonical[canonicalID] = Accumulator(
                        provider: provider,
                        hasCanonicalMetadata: isCanonicalOriginal,
                        regions: [region],
                        bestPriority: dto.displayPriority
                    )
                }
            }
        }

        let subscription: [ProviderRegionalAvailability] = byCanonical.values
            .sorted { lhs, rhs in
                if lhs.bestPriority != rhs.bestPriority {
                    return lhs.bestPriority < rhs.bestPriority
                }
                return lhs.provider.name.localizedStandardCompare(rhs.provider.name) == .orderedAscending
            }
            .map { acc in
                let regions = acc.regions.sorted { a, b in
                    a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
                }
                return ProviderRegionalAvailability(provider: acc.provider, regions: regions)
            }

        return GlobalWatchAvailability(movieID: id, subscription: subscription)
    }

    private func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return try? Date(raw, strategy: Self.releaseDateStrategy)
    }

    /// Pulls people whose `job == "Director"` out of the crew. Excludes
    /// related-but-different roles like "Director of Photography" or
    /// "Co-Director" — adjust the predicate here if you want a broader set.
    private func extractDirectors(from credits: TMDBCreditsDTO?) -> [Person] {
        (credits?.crew ?? [])
            .filter { $0.job == "Director" }
            .map { dto in
                Person(
                    id: PersonID(dto.id),
                    name: dto.name,
                    profilePath: dto.profilePath.map(ImagePath.init)
                )
            }
    }

    /// Translates URLError / cancellation / unknown errors into our domain enum
    /// so the repository surfaces only `MovieError`. View models depend on this.
    private func mapErrors<T>(_ block: () async throws -> T) async throws -> T {
        do {
            return try await block()
        } catch is CancellationError {
            throw MovieError.cancelled
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed: throw MovieError.offline
            case .timedOut: throw MovieError.timeout
            case .cancelled: throw MovieError.cancelled
            default: throw MovieError.unknown
            }
        } catch let movieError as MovieError {
            throw movieError
        } catch {
            throw MovieError.unknown
        }
    }
}
