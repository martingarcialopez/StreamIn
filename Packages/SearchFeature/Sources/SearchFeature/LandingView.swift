import SwiftUI
import Domain
import Preferences
import ReferenceData
import DesignSystem

/// The Search tab's first screen: the slot machine, the app's name and
/// promise, and the search bar.
struct LandingView: View {
    let model: LandingViewModel
    @Binding var searchText: String
    let onSubmit: () -> Void

    @State private var creditsHeight: CGFloat = 0

    /// A little above the middle, so the bar stays clear of the keyboard.
    private static let contentAnchor = UnitPoint(x: 0.5, y: 0.4)
    /// Keeps the bar a comfortable width on iPad and in landscape.
    private static let maxContentWidth: CGFloat = 560

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionGap) {
                SlotMachine(model: model)
                VStack(spacing: Spacing.tight) {
                    Text(verbatim: Self.appName)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(.searchLandingTagline)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                SearchBar(text: $searchText, onSubmit: onSubmit)
            }
            .frame(maxWidth: Self.maxContentWidth)
            .padding(Spacing.screenPadding)
            .frame(maxWidth: .infinity)
        }
        // Centred while it fits; at large text sizes it scrolls instead of
        // running under the credits and the tab bar.
        .defaultScrollAnchor(Self.contentAnchor, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaPadding(.bottom, creditsHeight)
        .overlay(alignment: .bottom) {
            // TMDB's terms ask for credit, and for JustWatch's on watch-provider data.
            Text(.searchLandingCredits)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenPadding)
                // Clear of the floating tab bar, not resting on it.
                .padding(.bottom, Spacing.sectionGap)
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { creditsHeight = $0 }
                .frame(maxHeight: .infinity, alignment: .bottom)
                // The keyboard covers the credits rather than pushing them into the bar.
                .ignoresSafeArea(.keyboard)
        }
        .cinemaBackground()
        .task { await model.load() }
    }

    // Pulled from Info.plist so the localized display name (en/es) flows
    // through automatically — same source iOS uses for the Home Screen icon.
    private static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "StreamIn"
    }
}

extension LandingViewModel {
    /// For previews, which can't reach TMDB: the reels show their stand-ins.
    static func preview() -> LandingViewModel {
        let repository = PreviewMovieRepository()
        return LandingViewModel(
            repository: repository,
            catalog: ProviderCatalog(repository: repository),
            prefs: Preferences(defaults: UserDefaults(suiteName: "LandingView.preview") ?? .standard),
            imageURLBuilder: PreviewImageURLBuilder()
        )
    }
}

#Preview {
    @Previewable @State var text = ""
    NavigationStack {
        LandingView(model: .preview(), searchText: $text, onSubmit: {})
    }
}

#Preview("Accessibility text") {
    @Previewable @State var text = ""
    NavigationStack {
        LandingView(model: .preview(), searchText: $text, onSubmit: {})
    }
    .dynamicTypeSize(.accessibility3)
}

/// Trending fails and there are no providers, as when offline.
private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.offline }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.offline }
    func trendingMovies() async throws -> [Movie] { throw MovieError.offline }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.offline }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle { throw MovieError.offline }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
