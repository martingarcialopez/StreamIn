//
//  DetailsView.swift
//  DetailsFeature
//
//  Renders one movie's detail screen: backdrop, title, metadata strip,
//  overview, and the per-category provider grid (subscription / rent / buy / free).
//

import SwiftUI
import Domain

public struct DetailsView: View {

    @State private var model: DetailsViewModel

    public init(model: DetailsViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BackdropView(url: model.backdropURL())
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    Text(model.movie.title)
                        .font(.title)
                        .fontWeight(.bold)

                    metadataRow

                    if !model.movie.directors.isEmpty {
                        Text("Directed by \(model.movie.directors.map(\.name).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !model.movie.overview.isEmpty {
                        Text(model.movie.overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    providersSection

                    if let error = model.error {
                        Divider()
                        VStack(spacing: 8) {
                            Text("Couldn't load full details: \(String(describing: error))")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Button("Retry") {
                                Task { await model.load() }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load()
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 16) {
            if let date = model.movie.releaseDate {
                Label(date.formatted(.dateTime.year()), systemImage: "calendar")
            }
            if let runtime = model.movie.runtime {
                let minutes = Int(runtime.components.seconds / 60)
                Label("\(minutes) min", systemImage: "clock")
            }
            Label(String(format: "%.1f", model.movie.voteAverage), systemImage: "star.fill")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var providersSection: some View {
        if let availability = model.availability {
            VStack(alignment: .leading, spacing: 14) {
                Text("Where to watch")
                    .font(.headline)

                providerRow(title: "Streaming", providers: availability.subscription)
                //providerRow(title: "Rent",      providers: availability.rent)
                //providerRow(title: "Buy",       providers: availability.buy)
                providerRow(title: "Free",      providers: availability.free)

                if availability.isEmpty {
                    Text("Not available in your region.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
            }
        } else if model.isLoading {
            HStack {
                Spacer()
                ProgressView("Checking availability…")
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func providerRow(title: String, providers: [WatchProvider]) -> some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(providers, id: \.id) { provider in
                        ProviderLogo(url: model.providerLogoURL(for: provider))
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

private struct BackdropView: View {
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
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DetailsView(model: DetailsViewModel(
            movie: Movie(
                id: MovieID(27205),
                title: "Inception",
                originalTitle: "Inception",
                overview: "A thief who steals corporate secrets through dream-sharing technology…",
                releaseDate: nil,
                posterPath: nil,
                backdropPath: nil,
                voteAverage: 8.4,
                runtime: nil
            ),
            repository: PreviewMovieRepository(),
            imageURLBuilder: PreviewImageURLBuilder(),
            region: .unitedStates
        ))
    }
}

private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        fatalError("not used in preview")
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
