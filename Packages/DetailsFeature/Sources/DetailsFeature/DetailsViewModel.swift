//
//  DetailsViewModel.swift
//  DetailsFeature
//
//  Owns the state for one movie's detail screen: the movie itself (initially the
//  summary passed in from search, then enriched with full detail) and its
//  region-specific watch availability.
//

import Foundation
import Domain

@Observable
@MainActor
public final class DetailsViewModel {

    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let region: Region

    /// Starts with the summary that the search screen already had (so the title,
    /// year, and poster render instantly), then gets replaced by the richer
    /// detail object once `load()` completes.
    private(set) var movie: Movie
    private(set) var availability: WatchAvailability?
    private(set) var error: MovieError?
    private(set) var isLoading = false

    public init(
        movie: Movie,
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder,
        region: Region = .currentLocale
    ) {
        self.movie = movie
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        self.region = region
    }

    /// Fetches full detail and availability in parallel via `async let`.
    ///
    /// Both calls are issued at once and their continuations resume independently
    /// on the main actor. If either throws, the other is cancelled (Swift's
    /// structured concurrency guarantee). The whole load is cheap-failure: the
    /// previously-rendered summary stays on screen, and the error state surfaces
    /// for the user to retry.
    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let detailTask = repository.movie(id: movie.id)
            async let availabilityTask = repository.availability(for: movie.id, in: region)
            let (detail, avail) = try await (detailTask, availabilityTask)
            self.movie = detail
            self.availability = avail
            self.error = nil
        } catch let movieError as MovieError {
            self.error = movieError
        } catch {
            self.error = .unknown
        }
    }

    public func backdropURL() -> URL? {
        movie.backdropPath.flatMap { imageURLBuilder.url(for: $0, size: .backdrop) }
    }

    public func posterURL() -> URL? {
        movie.posterPath.flatMap { imageURLBuilder.url(for: $0, size: .poster) }
    }

    public func providerLogoURL(for provider: WatchProvider) -> URL? {
        provider.logoPath.flatMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
    }
}
