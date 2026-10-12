//
//  DetailsView.swift
//  DetailsFeature
//
//  Renders one movie's detail screen: backdrop, title, metadata strip,
//  overview, the cross-region "Watch with your subscriptions" section, and the
//  legacy per-region provider grid.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem

public struct DetailsView: View {

    @State private var model: DetailsViewModel
    /// Bumped by Retry so the load re-runs through `.task(id:)`.
    @State private var loadAttempt = 0
    @Environment(Preferences.self) private var prefs
    private let onEditSubscriptions: () -> Void

    /// - Parameter onEditSubscriptions: Opens the streaming-services picker.
    ///   Offered when the user hasn't picked any services, since the
    ///   subscription sections are empty without them.
    public init(model: DetailsViewModel, onEditSubscriptions: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onEditSubscriptions = onEditSubscriptions
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BackdropView(url: model.backdropURL())
                    // Use `aspectRatio` instead of a fixed height: backdrops
                    // are 16:9, and this scales correctly across phone sizes
                    // (iPhone SE through iPhone Pro Max) and iPad.
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
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

                    SubscribedAvailabilitySection(
                        model: model,
                        onEditSubscriptions: onEditSubscriptions,
                        onRetry: retry
                    )

                    if let failure = model.availabilityFailure {
                        // With services picked, the section above shows the
                        // error; without, it offers the picker and the error
                        // goes here.
                        if model.subscriptionsState == .needsSubscriptions {
                            Divider()
                            ErrorRetry(error: failure, onRetry: retry)
                        }
                    } else {
                        Divider()

                        ProvidersSection(model: model)

                        // A reload failed; the earlier results stay above.
                        if let error = model.error {
                            Divider()
                            ErrorRetry(error: error, onRetry: retry)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .toolbarTitleDisplayMode(.inline)
        // Loads on first render, and again when the language or region
        // changes or Retry is tapped. SwiftUI cancels the previous run, so
        // only the latest one writes to the model.
        .task(id: LoadTrigger(settings: prefs.snapshot, attempt: loadAttempt)) {
            await model.load(region: prefs.region)
        }
    }

    private func retry() {
        loadAttempt += 1
    }
}

private struct LoadTrigger: Hashable {
    let settings: Preferences.Snapshot
    let attempt: Int
}

// MARK: - Metadata strip

private struct MetadataRow: View {
    let model: DetailsViewModel

    var body: some View {
        HStack(spacing: 16) {
            if let year = model.formattedReleaseYear {
                Label(year, systemImage: Symbol.calendar)
            }
            if let runtime = model.formattedRuntime {
                Label(runtime, systemImage: Symbol.clock)
            }
            Label(model.formattedVoteAverage, systemImage: Symbol.starFill)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Subscribed availability (region-partitioned: home + other regions)

/// Top-level container. Just wraps `SubscribedAvailabilityContent` in a
/// `VStack` — the branching logic lives in the content view, which keeps
/// each state (loading / empty / no-matches / has-data) easy to read.
private struct SubscribedAvailabilitySection: View {
    let model: DetailsViewModel
    let onEditSubscriptions: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SubscribedAvailabilityContent(
                model: model,
                onEditSubscriptions: onEditSubscriptions,
                onRetry: onRetry
            )
        }
    }
}

/// Renders `DetailsViewModel.subscriptionsState`:
///   - no subscriptions configured → button to pick services
///   - loading (no availability yet) → spinner
///   - load failed → the error and Retry
///   - has subscriptions but no matches → "not available with your subs"
///   - has matches → `HomeRegionSubsection` + optional `OtherRegionsSubsection`
private struct SubscribedAvailabilityContent: View {
    let model: DetailsViewModel
    let onEditSubscriptions: () -> Void
    let onRetry: () -> Void

    var body: some View {
        switch model.subscriptionsState {
        case .needsSubscriptions:
            EmptyStateConfigure(onEditSubscriptions: onEditSubscriptions)
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        case .failed(let error):
            ErrorRetry(error: error, onRetry: onRetry)
        case .noMatches:
            Text(.detailsSubscriptionsNoMatches)
                .font(.callout)
                .foregroundStyle(.secondary)
        case .available:
            HomeRegionSubsection(model: model)
            // Render the "other regions" subsection only if there's anything
            // to show — otherwise an empty header is noise.
            if !model.providersAvailableElsewhere.isEmpty {
                OtherRegionsSubsection(model: model)
            }
        }
    }
}

/// Details has no Settings button of its own (Settings lives on each tab's
/// first screen), so this state links straight to the services picker —
/// the one setting the screen can't work without.
private struct EmptyStateConfigure: View {
    let onEditSubscriptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.detailsSubscriptionsEmptyConfigure)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button(.detailsSubscriptionsConfigureButton, action: onEditSubscriptions)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Section 1: home region

private struct HomeRegionSubsection: View {
    let model: DetailsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.providersAvailableAtHome.isEmpty {
                Text(.detailsSubscriptionsHomeNotAvailable(model.homeRegionLabel))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text(.detailsSubscriptionsHomeRegion(model.homeRegionLabel))
                    .font(.headline)
                ForEach(model.providersAvailableAtHome) { provider in
                    HomeProviderRow(provider: provider, model: model)
                }
            }
        }
    }
}

private struct HomeProviderRow: View {
    let provider: WatchProvider
    let model: DetailsViewModel

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.large

    var body: some View {
        HStack(spacing: 12) {
            ProviderLogo(
                url: model.providerLogoURL(for: provider),
                providerName: provider.name,
                size: logoSize,
                cornerRadius: Radius.large
            )
            Text(provider.name)
                .font(.subheadline)
                .bold()
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Section 2: other regions (VPN territory)

private struct OtherRegionsSubsection: View {
    let model: DetailsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(.detailsSubscriptionsOtherRegions)
                .font(.headline)
            ForEach(model.providersAvailableElsewhere, id: \.provider.id) { entry in
                OtherRegionProviderRow(entry: entry, model: model)
            }
        }
    }
}

private struct OtherRegionProviderRow: View {
    let entry: ProviderRegionalAvailability
    let model: DetailsViewModel

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.large

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ProviderLogo(
                    url: model.providerLogoURL(for: entry.provider),
                    providerName: entry.provider.name,
                    size: logoSize,
                    cornerRadius: Radius.large
                )
                Text(entry.provider.name)
                    .font(.subheadline)
                    .bold()
                Spacer(minLength: 0)
            }
            RegionFlagStrip(
                regions: entry.regions,
                providerName: entry.provider.name
            )
        }
    }
}

// MARK: - Region flag strip + overflow sheet

/// Inline horizontal strip of `flag + ISO-code` pills. Shows up to
/// `maxInline` entries; anything beyond surfaces as a `+N` pill at the end.
/// The whole strip (including whitespace between pills) is one tap target
/// that presents `RegionListSheet` — Fitts's law over tiny `+N` hit boxes.
private struct RegionFlagStrip: View {
    let regions: [Region]
    /// Used as the sheet's navigation title and for VoiceOver context.
    let providerName: String

    @State private var showAll = false

    /// Six entries fit comfortably on the smallest iPhone at default
    /// Dynamic Type. At larger Dynamic Type sizes the row wraps to a
    /// second line which is also fine.
    private static let maxInline = 6

    private var inlineRegions: [Region] {
        Array(regions.prefix(Self.maxInline))
    }

    private var overflow: Int {
        max(0, regions.count - Self.maxInline)
    }

    var body: some View {
        Button {
            showAll = true
        } label: {
            HStack(spacing: 8) {
                ForEach(inlineRegions) { region in
                    HStack(spacing: 3) {
                        Text(region.flag)
                        Text(region.code)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(region.displayName)
                }
                if overflow > 0 {
                    Text(verbatim: "+\(overflow)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: .capsule)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(.detailsRegionStripAccessibility(providerName, regions.count)))
        // No hint: SwiftUI auto-provides "Double-tap to activate" for buttons.
        .sheet(isPresented: $showAll) {
            RegionListSheet(regions: regions, title: providerName)
        }
    }
}

/// Full list of regions for one provider. Reached by tapping the flag strip.
/// Rows are `flag` + localized country name + ISO code. No interactivity per
/// row in v1 — pure reference.
private struct RegionListSheet: View {
    let regions: [Region]
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(regions) { region in
                HStack(spacing: 12) {
                    Text(region.flag)
                        .font(.title2)
                    Text(region.displayName)
                        .font(.body)
                    Spacer()
                    Text(region.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(region.displayName)
            }
            .navigationTitle(Text(verbatim: title))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.detailsRegionsSheetDone) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Providers (legacy region-scoped)

private struct ProvidersSection: View {
    let model: DetailsViewModel

    var body: some View {
        if let availability = model.homeAvailability {
            VStack(alignment: .leading, spacing: 14) {
                Text(.detailsWhereToWatch)
                    .font(.headline)

                ProviderCategoryRow(
                    title: String(localized: .detailsProvidersSubscription),
                    providers: availability.subscription,
                    model: model
                )
                ProviderCategoryRow(
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
        } else if model.error == nil {
            // Not loaded yet for this region. A failed load shows its error
            // instead (in place of this section, or below it after a reload).
            HStack {
                Spacer()
                ProgressView { Text(.detailsCheckingAvailability) }
                Spacer()
            }
        }
    }
}

/// A category-titled strip of provider logos (e.g. "Subscription: Netflix,
/// Prime, Disney+"). Renamed from `ProviderRow` to disambiguate from
/// `SettingsFeature.ProviderToggleRow`, which has a different shape and
/// purpose entirely.
private struct ProviderCategoryRow: View {
    let title: String
    let providers: [WatchProvider]
    let model: DetailsViewModel

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.hero

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
                            providerName: provider.name,
                            size: logoSize,
                            cornerRadius: Radius.large
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
                Rectangle().fill(.quaternary)
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle().fill(.quaternary)
                    .overlay {
                        Image(systemName: Symbol.photo).foregroundStyle(.tertiary)
                    }
            @unknown default:
                Rectangle().fill(.quaternary)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Available") {
    let prefs = previewPrefs(name: "available")
    NavigationStack {
        DetailsView(
            model: DetailsViewModel(
                movie: PreviewMovieRepository.inception,
                repository: PreviewMovieRepository(),
                imageURLBuilder: PreviewImageURLBuilder(),
                prefs: prefs
            ),
            onEditSubscriptions: {}
        )
        .environment(prefs)
    }
}

#Preview("Offline") {
    let prefs = previewPrefs(name: "offline")
    NavigationStack {
        DetailsView(
            model: DetailsViewModel(
                movie: PreviewMovieRepository.inception,
                repository: PreviewMovieRepository(availabilityError: .offline),
                imageURLBuilder: PreviewImageURLBuilder(),
                prefs: prefs
            ),
            onEditSubscriptions: {}
        )
        .environment(prefs)
    }
}

/// Subscribed to Netflix, in its own defaults suite so previews don't share state.
@MainActor
private func previewPrefs(name: String) -> Preferences {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "DetailsView.preview.\(name)")!)
    prefs.subscribedProviderIDs = [ProviderID(8)]
    return prefs
}

/// `load()` runs in the preview too (`.task` fires), so `movie(id:)` and
/// `availabilities(for:in:)` must return data.
private struct PreviewMovieRepository: MovieRepository {
    /// Makes `availabilities` fail, to preview the error state.
    var availabilityError: MovieError?

    static let inception = Movie(
        id: MovieID(27205),
        title: "Inception",
        originalTitle: "Inception",
        overview: "A thief who steals corporate secrets through dream-sharing technology…",
        releaseDate: nil,
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 8.4,
        runtime: .seconds(148 * 60),
        directors: [Person(id: PersonID(525), name: "Christopher Nolan", profilePath: nil)]
    )

    private static let netflix = WatchProvider(id: ProviderID(8), name: "Netflix", logoPath: nil, priority: 1)

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        fatalError("not used in preview")
    }
    func movie(id: MovieID) async throws -> Movie {
        Self.inception
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        fatalError("not used in preview")
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        if let availabilityError { throw availabilityError }
        return AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: [Self.netflix], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(
                movieID: id,
                subscription: [ProviderRegionalAvailability(provider: Self.netflix, regions: [region, .france, .germany])]
            )
        )
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
