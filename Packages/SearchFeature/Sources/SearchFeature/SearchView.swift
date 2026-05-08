//
//  SearchView.swift
//  SearchFeature
//
//  TEMPORARY smoke-test screen — proves the wiring works end to end.
//  Next iteration: real search field with debounce + cancellation, plus tests.
//

import SwiftUI
import Domain

public struct SearchView: View {

    @State private var model: SearchViewModel
    @State private var searchText = ""

    public init(model: SearchViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        // The NavigationStack lives one level up (in the App target's
        // composition root), so this view simply contributes content + the
        // search bar + the submit handler. Rows below use NavigationLink(value:)
        // to push movies onto whichever stack contains us.
        SearchContent(model: model, onRetry: retry)
            .navigationTitle("StreamIn")
            .searchable(text: $searchText, prompt: "Search a movie")
            .onSubmit(of: .search, retry)
    }

    private func retry() {
        Task { await model.search(query: searchText) }
    }
}

// MARK: - Content branching
//
// Per the project's view-structure convention, the content branches live in
// their own `View` structs rather than `@ViewBuilder` computed properties on
// `SearchView`. The struct receives the view model directly — `@Observable`
// invalidation is automatic when its body reads observable properties.

private struct SearchContent: View {
    let model: SearchViewModel
    let onRetry: () -> Void

    var body: some View {
        if model.isLoading {
            ProgressView("Searching…")
        } else if let error = model.error {
            ErrorState(error: error, onRetry: onRetry)
        } else if model.results.isEmpty {
            ContentUnavailableView(
                "Search a movie",
                systemImage: "movieclapper",
                description: Text("Type a title and press Return.")
            )
        } else {
            List(model.results) { movie in
                NavigationLink(value: movie) {
                    SearchResultRow(movie: movie, model: model)
                }
            }
        }
    }
}

private struct ErrorState: View {
    let error: MovieError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(error.userMessage)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Retry", action: onRetry)
        }
        .padding()
    }
}

private struct SearchResultRow: View {
    let movie: Movie
    let model: SearchViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PosterView(url: model.posterURL(for: movie))

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let date = movie.releaseDate {
                    Text(date.formatted(.dateTime.year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProviderStrip(movie: movie, model: model)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct ProviderStrip: View {
    let movie: Movie
    let model: SearchViewModel

    var body: some View {
        if let availability = model.availability[movie.id] {
            if availability.subscription.isEmpty {
                Text("Not on streaming in your region")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(availability.subscription.prefix(5)) { provider in
                        ProviderLogo(
                            url: model.providerLogoURL(for: provider),
                            providerName: provider.name
                        )
                    }
                }
            }
        } else {
            ProgressView()
                .controlSize(.mini)
        }
    }
}

// MARK: - Image subviews

private struct PosterView: View {
    let url: URL?

    /// Scales with Dynamic Type so the row stays in proportion when the user
    /// bumps text size up. The 2:3 aspect ratio is the TMDB poster standard.
    @ScaledMetric(relativeTo: .headline) private var width: CGFloat = 60

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.15)
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray.opacity(0.15)
                    .overlay {
                        Image(systemName: "photo").foregroundStyle(.tertiary)
                    }
            @unknown default:
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(.rect(cornerRadius: 6))
        // The row's title/subtitle already announce the movie; the poster is
        // decorative and would be redundant noise to VoiceOver.
        .accessibilityHidden(true)
    }
}

private struct ProviderLogo: View {
    let url: URL?
    let providerName: String

    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 28

    var body: some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityLabel(providerName)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView(
            model: SearchViewModel(
                repository: PreviewMovieRepository(),
                imageURLBuilder: PreviewImageURLBuilder(),
                region: .unitedStates
            )
        )
    }
}

/// Trivial fake used only for SwiftUI previews. Real test fakes will live in
/// `SearchFeatureTests` once we add the view model tests.
private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        SearchPage(
            query: query,
            page: 1,
            totalPages: 1,
            totalResults: 1,
            results: [
                Movie(
                    id: MovieID(27205),
                    title: "Inception",
                    originalTitle: "Inception",
                    overview: "A thief who steals corporate secrets through dream-sharing technology…",
                    releaseDate: nil,
                    posterPath: nil,
                    backdropPath: nil,
                    voteAverage: 8.4,
                    runtime: nil
                )
            ]
        )
    }
    func movie(id: MovieID) async throws -> Movie {
        fatalError("not used in preview")
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        WatchAvailability(
            movieID: id,
            region: region,
            subscription: [],
            rent: [],
            buy: [],
            free: [],
            externalLink: nil
        )
    }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
