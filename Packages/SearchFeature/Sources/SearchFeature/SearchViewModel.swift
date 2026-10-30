//
//  SearchViewModel.swift
//  SearchFeature
//
//  Created by Martín on 01/05/2026.
//

import Foundation
import Domain
import Preferences

@Observable
@MainActor
public final class SearchViewModel {

    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    private let prefs: Preferences

    private(set) var results: [Movie] = []
    /// Streaming availability per movie (home region and every other one),
    /// populated as the parallel fan-out completes. A missing key means "not
    /// fetched yet" or, with the ID in `failedAvailability`, "failed".
    private(set) var availability: [MovieID: AvailabilityBundle] = [:]
    /// Rows whose availability request failed; the next `search` for the
    /// same request retries them.
    private(set) var failedAvailability: Set<MovieID> = []
    private(set) var error: MovieError?
    private(set) var isLoading = false

    /// The inputs behind the results on screen. A `search` with the same inputs
    /// keeps them instead of reloading — that's what the results screen's
    /// `.task` does every time it reappears after Details is popped.
    private var loadedRequest: Request?

    /// True once a search has finished and `results` belong to it — so an
    /// empty `results` means "nothing found" rather than "not searched yet".
    var hasLoadedResults: Bool { loadedRequest != nil }

    private struct Request: Equatable {
        let query: String
        let region: Region
        let language: Language
    }

    public init(
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder,
        prefs: Preferences
    ) {
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        self.prefs = prefs
    }

    /// Searches `query` and fetches every result's streaming availability in
    /// `region`.
    ///
    /// `language` isn't sent from here (the client carries it), but it's part
    /// of what identifies the results: after a language change the titles on
    /// screen are stale and must be reloaded.
    public func search(query: String, region: Region, language: Language) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            reset()
            return
        }
        let request = Request(query: trimmed, region: region, language: language)

        if request == loadedRequest {
            // Already on screen. Only retry rows whose availability never
            // arrived (failed, or the fan-out was interrupted).
            let missing = results.filter { availability[$0.id] == nil }
            await fetchAvailability(for: missing, request: request)
            return
        }

        isLoading = true
        error = nil
        results = []
        availability = [:]
        failedAvailability = []
        loadedRequest = nil
        do {
            let page = try await repository.searchMovies(query: trimmed, page: 1)
            // Superseded while in flight (new query, region or language):
            // the run that replaced this one owns the state now.
            guard !Task.isCancelled else { return }
            results = page.results
            loadedRequest = request
            // Show the list right away; each row's providers fill in as the
            // fan-out below completes.
            isLoading = false
            await fetchAvailability(for: page.results, request: request)
        } catch {
            guard !Task.isCancelled else { return }
            self.error = (error as? MovieError) ?? .unknown
            results = []
            availability = [:]
            failedAvailability = []
            loadedRequest = nil
            isLoading = false
        }
    }

    /// What `movie`'s row shows, read live from the user's services so a
    /// change in Settings updates the rows without refetching.
    func rowProviders(for movie: Movie) -> SearchRowProviders {
        guard let bundle = availability[movie.id] else {
            return failedAvailability.contains(movie.id) ? .failed : .loading
        }
        let options = WatchOptions(
            bundle: bundle,
            home: bundle.regional.region,
            subscribed: prefs.subscribedProviderIDs
        )
        return .loaded(options.summary)
    }

    /// "2010", or `nil` without a release date.
    func releaseYear(for movie: Movie) -> String? {
        movie.releaseDate?.formatted(.dateTime.year())
    }

    /// What VoiceOver reads for the whole row: "Inception, 2010, On Netflix
    /// and Max". Every provider is named, including those behind "+N".
    func accessibilityLabel(for movie: Movie) -> String {
        let providers = switch rowProviders(for: movie) {
        case .loading: String(localized: .searchRowCheckingAvailability)
        case .failed: String(localized: .searchRowAvailabilityFailed)
        case .loaded(.atHome(let providers)): String(localized: .searchRowOnProviders(Self.names(providers)))
        case .loaded(.abroad(let providers)): String(localized: .searchRowAbroadProviders(Self.names(providers)))
        case .loaded(.othersAtHome(let providers)): String(localized: .searchRowOthersProviders(Self.names(providers)))
        case .loaded(.notStreamingHere): String(localized: .searchRowNotStreamingHere)
        }
        return [movie.title, releaseYear(for: movie), providers]
            .compactMap(\.self)
            .joined(separator: ", ")
    }

    private static func names(_ providers: [WatchProvider]) -> String {
        providers.map(\.name).formatted(.list(type: .and))
    }

    public func posterURL(for movie: Movie) -> URL? {
        movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func providerLogoURL(for provider: WatchProvider) -> URL? {
        provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
    }

    private func reset() {
        results = []
        availability = [:]
        failedAvailability = []
        error = nil
        isLoading = false
        loadedRequest = nil
    }

    /// Fan out one availability call per movie in parallel.
    ///
    /// Each child task runs nonisolated (it's `@Sendable`), so the network calls
    /// proceed concurrently on the cooperative thread pool. Results are funneled
    /// back to the main actor through the `for await` loop, which serializes the
    /// dictionary writes safely. A failed row is marked in `failedAvailability`
    /// and retried by the next `search` call for the same request; one the
    /// fan-out never finished (cancelled) stays loading.
    ///
    /// `availabilities` is the same TMDB request and cache entry as the
    /// home-only `availability`, so the rows' abroad logos cost nothing extra
    /// and Details opens from the cache.
    private func fetchAvailability(for movies: [Movie], request: Request) async {
        let region = request.region
        // Retried rows show loading again until their answer lands.
        failedAvailability.subtract(movies.map(\.id))
        await withTaskGroup(of: (MovieID, AvailabilityBundle?).self) { group in
            for movie in movies {
                group.addTask { [repository] in
                    (movie.id, try? await repository.availabilities(for: movie.id, in: region))
                }
            }
            for await (id, value) in group {
                // A newer search replaced these results; its fan-out owns
                // `availability` now.
                guard loadedRequest == request else { break }
                if let value {
                    availability[id] = value
                } else if !Task.isCancelled {
                    failedAvailability.insert(id)
                }
            }
        }
    }
}
