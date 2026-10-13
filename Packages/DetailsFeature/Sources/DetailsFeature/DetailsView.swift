//
//  DetailsView.swift
//  DetailsFeature
//
//  Renders one movie's detail screen around the question it's opened for:
//  a "Where to watch" card that leads with one verdict (watch now, on your
//  services abroad, or go read a book), then the overview.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem

public struct DetailsView: View {

    @State private var model: DetailsViewModel
    /// Bumped by Retry so the load re-runs through `.task(id:)`.
    @State private var loadAttempt = 0
    /// Whether the backdrop has scrolled out from under the navigation bar.
    @State private var isPastBackdrop = false
    @Environment(Preferences.self) private var prefs
    private let onEditSubscriptions: () -> Void

    /// - Parameter onEditSubscriptions: Opens the streaming-services picker.
    ///   The "Where to watch" card offers it when the user hasn't picked any
    ///   services, since its verdict depends on them.
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
                    // Fades into the page, so the title sits on the image's edge.
                    .overlay {
                        LinearGradient(
                            colors: [.clear, AppPalette.background],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }

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

                    WhereToWatchCard(
                        model: model,
                        onEditSubscriptions: onEditSubscriptions,
                        onRetry: retry
                    )
                    // Room for the legends that sit on its top border.
                    .padding(.top, Spacing.comfortable)
                    .padding(.bottom, Spacing.default)

                    if !model.movie.overview.isEmpty {
                        Text(model.movie.overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        // Full-bleed hero: the backdrop runs behind the status bar and the
        // back button. The scroll-edge blur stays off over the image and
        // comes back once text scrolls under the bar.
        .ignoresSafeArea(edges: .top)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // About when the title reaches the bar: half the 16:9 backdrop.
            geometry.contentOffset.y > geometry.containerSize.width * 9 / 16 / 2
        } action: { _, isPast in
            isPastBackdrop = isPast
        }
        .scrollEdgeEffectHidden(!isPastBackdrop, for: .top)
        // Same page color as Search, so pushing Details doesn't flash white.
        .background(AppPalette.background)
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

// MARK: - Where to watch card

/// Renders `DetailsViewModel.verdict`: one headline that answers "can I
/// watch this?" and the logos behind it. The home region's title and its
/// other services sit on the top border, so the card itself holds only the
/// answer.
private struct WhereToWatchCard: View {
    let model: DetailsViewModel
    let onEditSubscriptions: () -> Void
    let onRetry: () -> Void

    @ScaledMetric(relativeTo: .body) private var heroLogoSize: CGFloat = LogoSize.hero
    /// About the size of the emoji beside the other verdicts.
    @ScaledMetric(relativeTo: .title) private var globeSize: CGFloat = LogoSize.medium

    /// The verdict's color; loading, failures and the services prompt stay neutral.
    private var tint: Color? {
        switch model.verdict {
        case .watchNow: AppPalette.positive
        case .abroad: AppPalette.accent
        case .unavailable: AppPalette.unavailable
        case .loading, .failed, .chooseServices: nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.comfortable) {
            switch model.verdict {
            case .loading:
                ProgressView { Text(.detailsCheckingAvailability) }
                    .frame(maxWidth: .infinity)
            case .failed(let error):
                ErrorRetry(error: error, onRetry: onRetry)
            case .watchNow:
                VerdictHeadline(title: .detailsVerdictWatchNow) {
                    Text(verbatim: "🍿")
                }
                ProviderLogoGrid(providers: model.watchNowProviders, model: model, logoSize: heroLogoSize)
                if model.offersServicePicker {
                    Button(.detailsSubscriptionsConfigureButton, action: onEditSubscriptions)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            case .abroad:
                VerdictHeadline(title: .detailsVerdictAbroad) {
                    SpinningGlobe(diameter: globeSize)
                }
                ForEach(model.providersAvailableElsewhere, id: \.provider.id) { entry in
                    AbroadProviderRow(entry: entry, model: model)
                }
            case .chooseServices:
                EmptyStateConfigure(onEditSubscriptions: onEditSubscriptions)
            case .unavailable:
                VerdictHeadline(title: .detailsVerdictUnavailable) {
                    Text(verbatim: "📖")
                }
                if model.homeSubscriptionsOthers.isEmpty {
                    UnavailableReason(text: .detailsUnavailableNowhere)
                } else {
                    UnavailableReason(text: .detailsUnavailableNotOnYours)
                }
            }

            // A reload failed; the earlier results stay above.
            if let error = model.reloadError {
                ErrorRetry(error: error, onRetry: onRetry)
            }
        }
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if let tint {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(VerdictTint.fill(tint))
                    .mask { LegendCutout { BorderLegends(model: model, layer: .tintFade) } }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(tint.map(VerdictTint.border) ?? AppPalette.separator)
                .mask { LegendCutout { BorderLegends(model: model, layer: .borderGap) } }
        }
        .overlay(alignment: .top) {
            BorderLegends(model: model, layer: .content)
        }
        // Crossfades from the spinner to the verdict, tint included.
        .animation(.smooth, value: model.verdict)
        .accessibilityElement(children: .contain)
    }
}

/// "Where to watch · 🇪🇸" sitting on the card's top border, like a form
/// legend: everything in the card is seen from the home region.
private struct CardLegend: View {
    let model: DetailsViewModel

    var body: some View {
        Text(.detailsWhereToWatchTitle(model.homeRegion.flag))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.tight)
            .lineLimit(1)
            .accessibilityLabel(Text(.detailsWhereToWatchRegion(model.homeRegion.displayName)))
            .accessibilityAddTraits(.isHeader)
            // Read before the card's content, not after it as overlays are.
            .accessibilitySortPriority(1)
    }
}

/// The verdict's emoji, a size up from the answer beside it in plain text:
/// the card's color carries the state, the text stays readable.
private struct VerdictHeadline<Icon: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder let icon: Icon

    var body: some View {
        HStack(spacing: Spacing.comfortable) {
            icon
                .font(.title)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// The title on the left of the card's top border and the other services'
/// logos on the right, centered on the line. Laid out once for the legends
/// themselves and again, identically, for the holes they leave in the card,
/// so the legends stay on the card's own plane instead of sitting on top.
private struct BorderLegends: View {
    let model: DetailsViewModel
    let layer: LegendLayer

    var body: some View {
        HStack(spacing: 0) {
            // The title keeps its line; the logos take what's left.
            CardLegend(model: model)
                .modifier(LegendFootprint(layer: layer, fadesTint: true))
                .layoutPriority(2)
            Spacer(minLength: Spacing.comfortable)
            OtherServicesLegend(model: model)
                .modifier(LegendFootprint(layer: layer, fadesTint: false))
                .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.comfortable)
        // The legends take no layout space, so they can't grow without limit:
        // above this size they'd overlap the lines around the border.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        // Centers the legends on the border line.
        .alignmentGuide(.top) { $0[VerticalAlignment.center] }
    }
}

private enum LegendLayer {
    /// The legends as the user sees them.
    case content
    /// Their footprints, to cut a crisp gap in the border.
    case borderGap
    /// The title's footprint, feathered and half-strength: the card's tint
    /// still runs under it, a shade lighter, so the card acknowledges it.
    case tintFade
}

/// Draws a legend itself, or the hole it leaves in the given layer.
private struct LegendFootprint: ViewModifier {
    let layer: LegendLayer
    let fadesTint: Bool

    func body(content: Content) -> some View {
        switch layer {
        case .content:
            content
        case .borderGap:
            content
                .opacity(0)
                .background(.black)
        case .tintFade:
            content
                .opacity(0)
                .background {
                    if fadesTint {
                        Capsule()
                            .fill(.black.opacity(0.55))
                            .padding(-Spacing.tight / 2)
                            .blur(radius: Spacing.tight)
                    }
                }
        }
    }
}

/// A mask that keeps everything except the legends' footprints.
private struct LegendCutout<Legends: View>: View {
    @ViewBuilder let legends: Legends

    var body: some View {
        Rectangle()
            .overlay(alignment: .top) {
                legends.blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}

/// How the verdict's color shows on the card: strongest behind the headline,
/// fading out towards the bottom.
private enum VerdictTint {
    static func fill(_ tint: Color) -> LinearGradient {
        LinearGradient(colors: [tint.opacity(0.18), tint.opacity(0.04)], startPoint: .top, endPoint: .bottom)
    }
    static func border(_ tint: Color) -> Color { tint.opacity(0.25) }
}

private struct UnavailableReason: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
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

/// The home region's services the user doesn't have, as small logos on the
/// card's top border opposite the title. No label: the title's flag already
/// says where (VoiceOver gets "Also on" / "In Spain"). They matter less than
/// the verdict, so they stay out of the card. Hidden while loading, after a
/// failure, or when there are none.
private struct OtherServicesLegend: View {
    let model: DetailsViewModel

    @ScaledMetric(relativeTo: .footnote) private var logoSize: CGFloat = LogoSize.small

    private var label: LocalizedStringResource? {
        switch model.verdict {
        case .loading, .failed:
            nil
        case .watchNow:
            .detailsAlsoOn
        case .abroad, .chooseServices, .unavailable:
            // The title already carries the flag.
            .detailsInRegion(model.homeRegion.displayName)
        }
    }

    var body: some View {
        let providers = model.homeSubscriptionsOthers
        if let label, !providers.isEmpty {
            // As many logos as fit beside the title; the rest show as "+N".
            ViewThatFits(in: .horizontal) {
                LogoStrip(providers: providers, maxLogos: 5, logoSize: logoSize, model: model)
                LogoStrip(providers: providers, maxLogos: 3, logoSize: logoSize, model: model)
                LogoStrip(providers: providers, maxLogos: 1, logoSize: logoSize, model: model)
            }
            .padding(.horizontal, Spacing.tight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(label))
            .accessibilityValue(providers.map(\.name).formatted(.list(type: .and)))
        }
    }
}

/// Up to `maxLogos` small logos, then "+N" for the rest.
private struct LogoStrip: View {
    let providers: [WatchProvider]
    let maxLogos: Int
    let logoSize: CGFloat
    let model: DetailsViewModel

    var body: some View {
        HStack(spacing: Spacing.tight) {
            ForEach(providers.prefix(maxLogos)) { provider in
                ProviderLogo(
                    url: model.providerLogoURL(for: provider),
                    providerName: provider.name,
                    size: logoSize,
                    cornerRadius: Radius.small
                )
            }
            if providers.count > maxLogos {
                Text(verbatim: "+\(providers.count - maxLogos)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Provider logos that wrap onto as many rows as the width needs.
private struct ProviderLogoGrid: View {
    let providers: [WatchProvider]
    let model: DetailsViewModel
    let logoSize: CGFloat

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: logoSize, maximum: logoSize), spacing: Spacing.default)],
            alignment: .leading,
            spacing: Spacing.default
        ) {
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

// MARK: - Abroad rows + region sheet

/// One of the user's services and where it carries the film. The whole row
/// is one tap target that presents `RegionListSheet`.
private struct AbroadProviderRow: View {
    let entry: ProviderRegionalAvailability
    let model: DetailsViewModel

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.large
    @State private var showAll = false

    var body: some View {
        Button {
            showAll = true
        } label: {
            HStack(spacing: Spacing.comfortable) {
                ProviderLogo(
                    url: model.providerLogoURL(for: entry.provider),
                    providerName: entry.provider.name,
                    size: logoSize,
                    cornerRadius: Radius.large
                )
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    Text(entry.provider.name)
                        .font(.subheadline)
                        .bold()
                    RegionFlags(regions: entry.regions)
                }
                Spacer(minLength: 0)
                Image(systemName: Symbol.chevronRight)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.comfortable)
            // Opaque cells on the tinted card, like an inset grouped list,
            // lifted by a soft shadow where the tint has faded out.
            .background(AppPalette.secondaryBackground, in: .rect(cornerRadius: Radius.large, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Combined, so the button keeps its trait and its double-tap action.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(.detailsRegionStripAccessibility(entry.provider.name, entry.regions.count)))
        .sheet(isPresented: $showAll) {
            RegionListSheet(regions: entry.regions, title: entry.provider.name)
        }
    }
}

/// The first few flags, then `+N` for the rest.
private struct RegionFlags: View {
    let regions: [Region]

    /// Popular VPN locations come first (`PopularRegions`), so three
    /// flags already show the useful ones.
    private static let maxInline = 3

    private var overflow: Int {
        max(0, regions.count - Self.maxInline)
    }

    var body: some View {
        HStack(spacing: Spacing.tight) {
            ForEach(regions.prefix(Self.maxInline)) { region in
                Text(region.flag)
            }
            if overflow > 0 {
                Text(verbatim: "+\(overflow)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: .capsule)
            }
        }
    }
}

/// Full list of regions for one provider. Reached by tapping an abroad row.
/// Rows are `flag` + localized country name + ISO code. No interactivity per
/// row in v1 — pure reference.
private struct RegionListSheet: View {
    let regions: [Region]
    let title: String

    @Environment(\.dismiss) private var dismiss

    /// A to Z: this list is for looking a country up; the row that opens it
    /// already leads with the popular ones.
    private var alphabetical: [Region] {
        regions
            .map { (region: $0, name: $0.displayName) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map(\.region)
    }

    var body: some View {
        NavigationStack {
            List(alphabetical) { region in
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
        .frame(maxWidth: .infinity)
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
//
// Every preview loads Spain as the home region.

#Preview("Watch now") {
    previewDetails(
        "watch-now",
        subscribedTo: [.netflix, .primeVideo],
        repository: PreviewMovieRepository(
            free: [.rtvePlay, .plutoTV],
            subscription: [.netflix, .movistarPlus, .disneyPlus, .hboMax, .filmin, .appleTVPlus,
                           .skyShowtime, .rakutenTV, .atresplayer, .mubi, .flixOle],
            // Netflix carries it at home, so Prime Video abroad isn't shown.
            global: [
                ProviderRegionalAvailability(provider: .netflix, regions: [.spain, .france]),
                ProviderRegionalAvailability(provider: .primeVideo, regions: [.unitedStates, .unitedKingdom]),
            ]
        )
    )
}

#Preview("Watch now, free only") {
    previewDetails(
        "free-only",
        subscribedTo: [],
        repository: PreviewMovieRepository(
            free: [.rtvePlay],
            subscription: [.movistarPlus, .disneyPlus]
        )
    )
}

#Preview("Abroad") {
    previewDetails(
        "abroad",
        subscribedTo: [.netflix, .primeVideo],
        repository: PreviewMovieRepository(
            subscription: [.disneyPlus, .hboMax, .movistarPlus],
            global: [
                ProviderRegionalAvailability(
                    provider: .netflix,
                    regions: ["AD", "AG", "AR", "BR", "CA", "FR", "GB", "IT", "JP", "MX", "US"].map(Region.init(code:))
                ),
                ProviderRegionalAvailability(provider: .primeVideo, regions: [Region(code: "AO"), Region(code: "ZA")]),
            ]
        )
    )
}

#Preview("Read a book, others here") {
    previewDetails(
        "book-others",
        subscribedTo: [.netflix],
        repository: PreviewMovieRepository(
            subscription: [.disneyPlus],
            global: [ProviderRegionalAvailability(provider: .disneyPlus, regions: [.spain, .france])]
        )
    )
}

#Preview("Read a book, nowhere") {
    previewDetails(
        "book-nowhere",
        subscribedTo: [.netflix],
        repository: PreviewMovieRepository()
    )
}

#Preview("No services") {
    previewDetails(
        "no-services",
        subscribedTo: [],
        repository: PreviewMovieRepository(
            subscription: [.netflix, .movistarPlus, .disneyPlus]
        )
    )
}

#Preview("Offline") {
    previewDetails(
        "offline",
        subscribedTo: [.netflix],
        repository: PreviewMovieRepository(error: .offline)
    )
}

/// Each preview gets its own defaults suite so previews don't share state.
@MainActor
private func previewDetails(
    _ name: String,
    subscribedTo providers: [WatchProvider],
    repository: PreviewMovieRepository
) -> some View {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "DetailsView.preview.\(name)")!)
    prefs.region = .spain
    prefs.subscribedProviderIDs = Set(providers.map(\.id))
    return NavigationStack {
        DetailsView(
            model: DetailsViewModel(
                movie: PreviewMovieRepository.inception,
                repository: repository,
                imageURLBuilder: PreviewImageURLBuilder(),
                prefs: prefs
            ),
            onEditSubscriptions: {}
        )
        .environment(prefs)
    }
}

/// `load()` runs in the preview too (`.task` fires), so every method returns
/// the configured data.
private struct PreviewMovieRepository: MovieRepository {
    /// Home-region providers.
    var free: [WatchProvider] = []
    var subscription: [WatchProvider] = []
    /// Subscription providers worldwide, with every region that carries the film.
    var global: [ProviderRegionalAvailability] = []
    /// Makes `availabilities` fail, to preview the error state.
    var error: MovieError?

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

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        SearchPage(query: query, page: page, totalPages: 1, totalResults: 1, results: [Self.inception])
    }
    func movie(id: MovieID) async throws -> Movie {
        Self.inception
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        try await availabilities(for: id, in: region).regional
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        if let error { throw error }
        return AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: subscription, rent: [], buy: [], free: free, externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: global)
        )
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        free + subscription
    }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}

private extension WatchProvider {
    static let netflix = preview(8, "Netflix")
    static let primeVideo = preview(119, "Prime Video")
    static let disneyPlus = preview(337, "Disney Plus")
    static let hboMax = preview(1899, "HBO Max")
    static let movistarPlus = preview(149, "Movistar Plus+")
    static let filmin = preview(63, "Filmin")
    static let appleTVPlus = preview(350, "Apple TV+")
    static let skyShowtime = preview(1773, "SkyShowtime")
    static let rakutenTV = preview(35, "Rakuten TV")
    static let atresplayer = preview(62, "Atresplayer")
    static let mubi = preview(11, "MUBI")
    static let flixOle = preview(393, "FlixOlé")
    static let rtvePlay = preview(541, "RTVE Play")
    static let plutoTV = preview(300, "Pluto TV")

    static func preview(_ id: Int, _ name: String) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: nil, priority: 1)
    }
}
