//
//  SearchFeatureView.swift
//  SearchFeature
//
//  TEMPORARY smoke-test screen — exists only to prove the wiring works end to
//  end (xcconfig → Run Script → GeneratedSecrets → AppConfig → LiveTMDBClient
//  → real network → TMDBMovieRepository → Domain types in a SwiftUI view).
//
//  Will be replaced by the proper Search feature (debounced search field,
//  view model, tests) shortly.
//

import SwiftUI
import Domain

public struct SearchFeatureView: View {

    let repository: MovieRepository

    @State private var viewModel: SearchFeatureViewModel
    @State private var isLoading = false

    public init(repository: MovieRepository) {
        self.repository = repository
        self.viewModel = .init()
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("StreamFinder")
                .toolbar {
                    Button("Search 'Inception'") {
                        Task { await search() }
                    }
                    .disabled(isLoading)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Searching…")
        } else if let error = viewModel.error {
            VStack(spacing: 12) {
                Text("Error: \(String(describing: error))")
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task { await search() }
                }
            }
            .padding()
        } else if viewModel.results.isEmpty {
            ContentUnavailableView(
                "Tap Search to verify wiring",
                systemImage: "movieclapper",
                description: Text("Smoke-test screen. Replace with the real search view soon.")
            )
        } else {
            List(viewModel.results) { movie in
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title).font(.headline)
                    if let date = movie.releaseDate {
                        Text(date.formatted(.dateTime.year()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(movie.overview)
                        .font(.callout)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func search() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await repository.searchMovies(query: "Inception", page: 1)
            viewModel.results = page.results
            viewModel.error = nil
        } catch let movieError as MovieError {
            viewModel.error = movieError
            viewModel.results = []
        } catch {
            viewModel.error = .unknown
            viewModel.results = []
        }
    }
}

// MARK: - Preview

#Preview {
    SearchFeatureView(repository: PreviewMovieRepository())
}

/// Trivial fake used only for SwiftUI previews. Real test fakes will live in
/// `SearchFeatureTests` once we add the view model.
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
        fatalError("not used in preview")
    }
}
