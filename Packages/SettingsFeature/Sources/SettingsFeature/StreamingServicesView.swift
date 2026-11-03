//
//  StreamingServicesView.swift
//  SettingsFeature
//
//  The "Streaming services" picker: a grid of app-icon logos, pushed from
//  Settings and shown in the services sheet and in Onboarding.
//
//  1. **Your services** — the picked ones, ringed, so unpicking is one tap.
//     Hidden when nothing is picked.
//  2. **Available in <region>** — the rest of the home region's catalog, or
//     the whole world's with the Worldwide switch beside the heading.
//
//  `.searchable` filters both sections. Onboarding adds its welcome above the
//  grid and its credits below through `header` and `footer`.
//

import SwiftUI
import Domain
import Preferences
import ReferenceData
import DesignSystem

struct StreamingServicesView<Header: View, Footer: View>: View {

    /// `@Bindable` (not `@State`) because the parent (`SettingsView`,
    /// `StreamingServicesSheet` or `OnboardingView`) owns the model.
    @Bindable var model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder
    /// Settings says "Streaming Services", Onboarding "Welcome".
    let title: LocalizedStringResource
    let header: Header
    let footer: Footer

    @Environment(Preferences.self) private var prefs

    /// On iPad the grid stays a block of about eight columns instead of
    /// stretching across the screen.
    private static var maxContentWidth: CGFloat { 720 }

    init(
        model: StreamingServicesViewModel,
        imageURLBuilder: ImageURLBuilder,
        title: LocalizedStringResource = .settingsStreamingServicesTitle,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.model = model
        self.imageURLBuilder = imageURLBuilder
        self.title = title
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                header
                if model.hasNoSearchMatches {
                    // Kept: a service missing here may exist abroad.
                    WorldwideToggle(model: model)
                    ContentUnavailableView.search(text: model.searchText)
                } else {
                    YourServicesSection(model: model, imageURLBuilder: imageURLBuilder)
                    AvailableSection(model: model, imageURLBuilder: imageURLBuilder, region: prefs.region)
                }
                footer
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.sectionGap)
            .frame(maxWidth: Self.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.immediately)
        // Here, not on the tile: a toggled tile moves to the other section,
        // so it's a new view whose `isSelected` never changes.
        .sensoryFeedback(.selection, trigger: model.selectedCount)
        // Here rather than at each call site: the grid is pushed from
        // Settings and shown in the services sheet and in Onboarding.
        .cinemaBackground()
        .navigationTitle(Text(title))
        .toolbarTitleDisplayMode(.inline)
        .searchable(
            text: $model.searchText,
            prompt: Text(.settingsMoreProvidersSearchPrompt)
        )
        // No `.task` here: the parent owns the model and loads the catalog
        // on its own appearance, so it's ready by the time the user gets here.
    }
}

extension StreamingServicesView where Header == EmptyView, Footer == EmptyView {
    init(
        model: StreamingServicesViewModel,
        imageURLBuilder: ImageURLBuilder,
        title: LocalizedStringResource = .settingsStreamingServicesTitle
    ) {
        self.init(model: model, imageURLBuilder: imageURLBuilder, title: title) {
            EmptyView()
        } footer: {
            EmptyView()
        }
    }
}

// MARK: - Sections

private struct YourServicesSection: View {
    let model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder

    var body: some View {
        let selected = model.visibleSelectedProviders
        if !selected.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.comfortable) {
                SectionHeading {
                    Text(verbatim: "🍿")
                } title: {
                    Text(.settingsStreamingServicesYourServices(model.selectedCount))
                }
                ProviderGrid(providers: selected, model: model, imageURLBuilder: imageURLBuilder)
            }
        }
    }
}

private struct AvailableSection: View {
    let model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder
    let region: Region

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.comfortable) {
            AvailableHeading(showWorldwide: model.showWorldwide, region: region)
            WorldwideToggle(model: model)

            if model.isInitialLoad {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sectionGap)
            } else if let error = model.loadError {
                LoadFailed(error: error) {
                    await model.load()
                }
            } else if model.hasPickedEveryService {
                Text(.settingsStreamingServicesAllPicked)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ProviderGrid(providers: model.availableProviders, model: model, imageURLBuilder: imageURLBuilder)
            }
        }
    }
}

private struct AvailableHeading: View {
    let showWorldwide: Bool
    let region: Region

    var body: some View {
        SectionHeading {
            Text(verbatim: showWorldwide ? "🌍" : region.flag)
        } title: {
            Text(showWorldwide
                 ? .settingsStreamingServicesAvailableWorldwide
                 : .settingsStreamingServicesAvailableInRegion(region.displayName))
        }
    }
}

/// The catalog couldn't load, e.g. on a first launch offline. Onboarding's
/// `.task` won't run again on its own, so the retry is a button.
private struct LoadFailed: View {
    let error: MovieError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.settingsStreamingServicesLoadFailed)
            } icon: {
                Image(systemName: Symbol.exclamationmarkTriangle)
            }
        } description: {
            Text(error.userMessage)
        } actions: {
            Button(.settingsRetry) {
                Task { await retry() }
            }
            .buttonStyle(.bordered)
        }
    }
}

/// A settings-style switch: the title, why you'd want it under it, the
/// switch on the right. Beside the heading it only fit at small sizes.
private struct WorldwideToggle: View {
    @Bindable var model: StreamingServicesViewModel

    var body: some View {
        Toggle(isOn: $model.showWorldwide) {
            Text(.settingsMoreProvidersWorldwideToggle)
                .font(.subheadline)
            Text(.settingsStreamingServicesWorldwideFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

/// Phase 4's headline style: an emoji, then a semibold title. The emoji is
/// decoration; VoiceOver reads the title as a heading.
private struct SectionHeading<Icon: View, Title: View>: View {
    @ViewBuilder let icon: Icon
    @ViewBuilder let title: Title

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.default) {
            icon
                .accessibilityHidden(true)
            title
                .bold()
        }
        .font(.headline)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Tiles in as many columns as fit; at accessibility text sizes the tiles
/// grow, so fewer fit.
private struct ProviderGrid: View {
    let providers: [WatchProvider]
    let model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder

    @ScaledMetric(relativeTo: .body) private var minimumTileWidth: CGFloat = 76

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: Spacing.comfortable, alignment: .top)],
            spacing: Spacing.sectionGap
        ) {
            ForEach(providers) { provider in
                ProviderTile(
                    provider: provider,
                    isSelected: model.isSubscribed(provider.id),
                    imageURLBuilder: imageURLBuilder,
                    toggle: { model.toggle(provider.id) }
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("None picked") {
    previewPicker("none")
}

#Preview("Three picked") {
    previewPicker("three", subscribedTo: [8, 119, 337])
}

#Preview("Search") {
    previewPicker("search", subscribedTo: [8, 337], search: "dis")
}

#Preview("No match") {
    previewPicker("no-match", subscribedTo: [8], search: "zzz")
}

#Preview("Worldwide") {
    previewPicker("worldwide", subscribedTo: [8], worldwide: true)
}

/// Each preview gets its own defaults suite so previews don't share state.
@MainActor
private func previewPicker(
    _ name: String,
    subscribedTo ids: [Int] = [],
    search: String = "",
    worldwide: Bool = false
) -> some View {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "StreamingServicesView.preview.\(name)")!)
    prefs.region = .spain
    prefs.subscribedProviderIDs = Set(ids.map(ProviderID.init))
    let model = StreamingServicesViewModel(catalog: ProviderCatalog(repository: PreviewMovieRepository()), prefs: prefs)
    model.searchText = search
    model.showWorldwide = worldwide
    return NavigationStack {
        StreamingServicesView(model: model, imageURLBuilder: PreviewImageURLBuilder())
            .task { await model.load() }
    }
    .environment(prefs)
    .preferredColorScheme(.dark)
}

/// `load()` runs in the preview, so `allProviders` answers every scope.
private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        fatalError("not used in preview")
    }
    func movie(id: MovieID) async throws -> Movie {
        fatalError("not used in preview")
    }
    func trendingMovies() async throws -> [Movie] {
        fatalError("not used in preview")
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        fatalError("not used in preview")
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        fatalError("not used in preview")
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        let spain = [
            (8, "Netflix"), (119, "Prime Video"), (337, "Disney Plus"), (1899, "HBO Max"),
            (149, "Movistar Plus+"), (63, "Filmin"), (350, "Apple TV+"), (2241, "Movistar Plus+ Ficción Total"),
            (541, "rtve"), (1773, "SkyShowtime"), (283, "Crunchyroll"), (11, "MUBI")
        ]
        let elsewhere = [(15, "Hulu"), (386, "Peacock"), (531, "Paramount Plus"), (39, "NOW"), (381, "Canal+")]
        return (region == nil ? spain + elsewhere : spain).enumerated().map { index, provider in
            WatchProvider(id: ProviderID(provider.0), name: provider.1, logoPath: nil, priority: index)
        }
    }
    func watchRegions() async throws -> [Region] { [] }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
