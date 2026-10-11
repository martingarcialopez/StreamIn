//
//  SearchViewModel.swift
//  SearchFeature
//
//  Created by Martín on 01/05/2026.
//

import Foundation
import Domain

@Observable
@MainActor
public final class SearchViewModel {

    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder

    private(set) var results: [Movie] = []
    /// Streaming availability per movie, populated as the parallel fan-out completes.
    /// A missing key means "not yet fetched"; an empty `WatchAvailability` means
    /// "fetched, but nothing available in this region."
    private(set) var availability: [MovieID: WatchAvailability] = [:]
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
        imageURLBuilder: ImageURLBuilder
    ) {
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
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
            loadedRequest = nil
            isLoading = false
        }
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
        error = nil
        isLoading = false
        loadedRequest = nil
    }

    /// Fan out one availability call per movie in parallel.
    ///
    /// Each child task runs nonisolated (it's `@Sendable`), so the network calls
    /// proceed concurrently on the cooperative thread pool. Results are funneled
    /// back to the main actor through the `for await` loop, which serializes the
    /// dictionary writes safely. A failed row keeps its "loading" placeholder and
    /// is retried by the next `search` call for the same request.
    private func fetchAvailability(for movies: [Movie], request: Request) async {
        let region = request.region
        await withTaskGroup(of: (MovieID, WatchAvailability?).self) { group in
            for movie in movies {
                group.addTask { [repository] in
                    (movie.id, try? await repository.availability(for: movie.id, in: region))
                }
            }
            for await (id, value) in group {
                // A newer search replaced these results; its fan-out owns
                // `availability` now.
                guard loadedRequest == request else { break }
                if let value {
                    availability[id] = value
                }
            }
        }
    }
}
