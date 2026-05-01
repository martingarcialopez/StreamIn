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
        NavigationStack {
            content
                .navigationTitle("StreamFinder")
                .searchable(text: $searchText, prompt: "Search a movie")
                .onSubmit(of: .search) {
                    Task { await model.search(query: searchText) }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView("Searching…")
        } else if let error = model.error {
            VStack(spacing: 12) {
                Text("Error: \(String(describing: error))")
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task { await model.search(query: searchText) }
                }
            }
            .padding()
        } else if model.results.isEmpty {
            ContentUnavailableView(
                "Search a movie",
                systemImage: "movieclapper",
                description: Text("Type a title and press Return.")
            )
        } else {
            List(model.results) { movie in
                row(for: movie)
            }
        }
    }

    @ViewBuilder
    private func row(for movie: Movie) -> some View {
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

                providerStrip(for: movie)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func providerStrip(for movie: Movie) -> some View {
        if let availability = model.availability[movie.id] {
            let providers = availability.subscription
            if providers.isEmpty {
                Text("Not on streaming in your region")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 6) {
                    ForEach(providers.prefix(5), id: \.id) { provider in
                        ProviderLogo(url: model.providerLogoURL(for: provider))
                    }
                }
            }
        } else {
            ProgressView()
                .controlSize(.mini)
        }
    }
}

// MARK: - Subviews

private struct PosterView: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.15)
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
            @unknown default:
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ProviderLogo: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview {
    SearchView(
        model: SearchViewModel(
            repository: PreviewMovieRepository(),
            imageURLBuilder: PreviewImageURLBuilder(),
            region: .unitedStates
        )
    )
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
