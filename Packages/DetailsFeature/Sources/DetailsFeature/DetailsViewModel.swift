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
        imageURLBuilder: ImageURLBuilder
    ) {
        self.movie = movie
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
    }

    /// Fetches full detail and availability in parallel via `async let`.
    ///
    /// Both calls are issued at once and their continuations resume independently
    /// on the main actor. If either throws, the other is cancelled (Swift's
    /// structured concurrency guarantee). The whole load is cheap-failure: the
    /// previously-rendered summary stays on screen, and the error state surfaces
    /// for the user to retry.
    ///
    /// Region is passed per-call so a runtime change in Settings flows through
    /// to the next reload without rebuilding the view model.
    public func load(region: Region) async {
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

    // MARK: - Display strings
    //
    // Formatting lives here (not in the view) so it's unit-testable without
    // standing up a SwiftUI hierarchy. Modern `FormatStyle` API throughout —
    // never `DateFormatter`/`NumberFormatter`/`String(format:)`.

    /// "2010" — the release year, or `nil` if TMDB didn't provide a date.
    public var formattedReleaseYear: String? {
        movie.releaseDate?.formatted(.dateTime.year())
    }

    /// "148 min" — the runtime in whole minutes, or `nil` if not available.
    /// Formatted via `Duration.UnitsFormatStyle` so the unit label localizes
    /// alongside the number ("min" → "мин." in Russian, etc.).
    public var formattedRuntime: String? {
        movie.runtime?.formatted(.units(allowed: [.minutes], width: .abbreviated))
    }

    /// "8.4" — TMDB's vote average to one decimal place. Routed through
    /// `Double.formatted(.number...)` so the locale's decimal separator is
    /// respected (a Spanish user sees "8,4").
    public var formattedVoteAverage: String {
        movie.voteAverage.formatted(.number.precision(.fractionLength(1)))
    }

    /// "Directed by Christopher Nolan" — `nil` if the credits haven't been
    /// loaded yet. The full enrichment lands on `load()`; until then the
    /// summary movie has an empty `directors` array.
    public var formattedDirectors: String? {
        guard !movie.directors.isEmpty else { return nil }
        let names = movie.directors.map(\.name).formatted(.list(type: .and))
        return "Directed by \(names)"
    }
}
