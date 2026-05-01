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
    let region: Region

    private(set) var results: [Movie] = []
    /// Streaming availability per movie, populated as the parallel fan-out completes.
    /// A missing key means "not yet fetched"; an empty `WatchAvailability` means
    /// "fetched, but nothing available in this region."
    private(set) var availability: [MovieID: WatchAvailability] = [:]
    private(set) var error: MovieError?
    private(set) var isLoading = false

    public init(
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder,
        region: Region = .currentLocale
    ) {
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        self.region = region
    }

    public func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            availability = [:]
            error = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await repository.searchMovies(query: trimmed, page: 1)
            results = page.results
            availability = [:]      // clear stale entries before fanning out
            error = nil
            await fetchAvailability(for: page.results)
        } catch let movieError as MovieError {
            error = movieError
            results = []
            availability = [:]
        } catch {
            self.error = .unknown
            results = []
            availability = [:]
        }
    }

    public func posterURL(for movie: Movie) -> URL? {
        movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func providerLogoURL(for provider: WatchProvider) -> URL? {
        provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
    }

    /// Fan out one availability call per movie in parallel.
    ///
    /// Each child task runs nonisolated (it's `@Sendable`), so the network calls
    /// proceed concurrently on the cooperative thread pool. Results are funneled
    /// back to the main actor through the `for await` loop, which serializes the
    /// dictionary writes safely. Per-movie failures are silently dropped — that
    /// row will keep its "loading" placeholder until the next search.
    private func fetchAvailability(for movies: [Movie]) async {
        await withTaskGroup(of: (MovieID, WatchAvailability?).self) { group in
            for movie in movies {
                group.addTask { [repository, region] in
                    do {
                        let value = try await repository.availability(for: movie.id, in: region)
                        return (movie.id, value)
                    } catch {
                        return (movie.id, nil)
                    }
                }
            }
            for await (id, value) in group {
                if let value {
                    availability[id] = value
                }
            }
        }
    }
}
