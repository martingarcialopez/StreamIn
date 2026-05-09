//
//  DetailsView.swift
//  DetailsFeature
//
//  Renders one movie's detail screen: backdrop, title, metadata strip,
//  overview, and the per-category provider grid (subscription / free).
//

import SwiftUI
import Domain
import Preferences

public struct DetailsView: View {

    @State private var model: DetailsViewModel
    @Environment(Preferences.self) private var prefs

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
                        .bold()

                    MetadataRow(model: model)

                    if let directors = model.formattedDirectors {
                        Text(directors)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !model.movie.overview.isEmpty {
                        Text(model.movie.overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    ProvidersSection(model: model)

                    if let error = model.error {
                        Divider()
                        ErrorRetry(error: error) {
                            Task { await model.load(region: prefs.region) }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .toolbarTitleDisplayMode(.inline)
        // Reload whenever language or region changes; the initial render also
        // hits this once so the view doesn't need a separate `.task { ... }`.
        .task(id: prefs.snapshot) {
            await model.load(region: prefs.region)
        }
    }
}

// MARK: - Metadata strip

private struct MetadataRow: View {
    let model: DetailsViewModel

    var body: some View {
        HStack(spacing: 16) {
            if let year = model.formattedReleaseYear {
                Label(year, systemImage: "calendar")
            }
            if let runtime = model.formattedRuntime {
                Label(runtime, systemImage: "clock")
            }
            Label(model.formattedVoteAverage, systemImage: "star.fill")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Providers

private struct ProvidersSection: View {
    let model: DetailsViewModel

    var body: some View {
        if let availability = model.availability {
            VStack(alignment: .leading, spacing: 14) {
                Text(.detailsWhereToWatch)
                    .font(.headline)

                ProviderRow(
                    title: String(localized: .detailsProvidersSubscription),
                    providers: availability.subscription,
                    model: model
                )
                ProviderRow(
                    title: String(localized: .detailsProvidersFree),
                    providers: availability.free,
                    model: model
                )

                if availability.isEmpty {
                    Text(.detailsNotAvailable)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
            }
        } else if model.isLoading {
            HStack {
                Spacer()
                ProgressView { Text(.detailsCheckingAvailability) }
                Spacer()
            }
        }
    }
}

private struct ProviderRow: View {
    let title: String
    let providers: [WatchProvider]
    let model: DetailsViewModel

    var body: some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(providers) { provider in
                        ProviderLogo(
                            url: model.providerLogoURL(for: provider),
                            providerName: provider.name
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Error block

private struct ErrorRetry: View {
    let error: MovieError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(.detailsLoadFailed(error.userMessage))
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button(.detailsRetry, action: onRetry)
        }
    }
}

// MARK: - Image subviews

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
                    .overlay {
                        Image(systemName: "photo").foregroundStyle(.tertiary)
                    }
            @unknown default:
                Color.gray.opacity(0.15)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProviderLogo: View {
    let url: URL?
    let providerName: String

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 44

    var body: some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityLabel(providerName)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DetailsView(
            model: DetailsViewModel(
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
                imageURLBuilder: PreviewImageURLBuilder()
            )
        )
        .environment(Preferences())
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
