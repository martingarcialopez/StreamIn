//
//  ContentView.swift
//  StreamFinder
//
//  TEMPORARY smoke-test screen — exists only to prove the wiring works end to
//  end (xcconfig → Info.plist → AppConfig → LiveTMDBClient → real network →
//  TMDBMovieRepository → Domain types in a SwiftUI view).
//
//  Once you see results from a real TMDB call here, delete this file and
//  replace it with the proper Feature_Search package.
//

import SwiftUI
import Domain

struct ContentView: View {

    let repository: MovieRepository

    @State private var results: [Movie] = []
    @State private var error: MovieError?
    @State private var isLoading = false

    var body: some View {
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
        } else if let error {
            VStack(spacing: 12) {
                Text("Error: \(String(describing: error))")
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task { await search() }
                }
            }
            .padding()
        } else if results.isEmpty {
            ContentUnavailableView(
                "Tap Search to verify wiring",
                systemImage: "movieclapper",
                description: Text("Smoke-test screen. Replace with Feature_Search once green.")
            )
        } else {
            List(results) { movie in
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
            results = page.results
            error = nil
        } catch let movieError as MovieError {
            error = movieError
            results = []
        } catch {
            self.error = .unknown
            results = []
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView(repository: PreviewMovieRepository())
}

/// Trivial fake used only for SwiftUI previews. Real test fakes will live in
/// the Feature_Search package once we get there.
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
