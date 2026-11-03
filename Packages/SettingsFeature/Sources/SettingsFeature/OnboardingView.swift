//
//  OnboardingView.swift
//  SettingsFeature
//
//  First-launch picker that asks which streaming services the user pays
//  for. Wraps `StreamingServicesView` (the same grid Settings uses) with a
//  welcome above it, a credit line below it and a single "Done" button.
//
//  Shown once: the App target's `RootView` presents it until
//  `Preferences.hasCompletedOnboarding` is set, which Done does.
//

import SwiftUI
import Domain
import Preferences
import ReferenceData
import DesignSystem

public struct OnboardingView: View {

    @State private var model: StreamingServicesViewModel
    private let prefs: Preferences
    private let imageURLBuilder: ImageURLBuilder

    @Environment(\.dismiss) private var dismiss

    public init(
        prefs: Preferences,
        catalog: ProviderCatalog,
        imageURLBuilder: ImageURLBuilder
    ) {
        self.prefs = prefs
        self.imageURLBuilder = imageURLBuilder
        _model = State(
            initialValue: StreamingServicesViewModel(catalog: catalog, prefs: prefs)
        )
    }

    public var body: some View {
        NavigationStack {
            StreamingServicesView(
                model: model,
                imageURLBuilder: imageURLBuilder,
                title: .onboardingNavTitle
            ) {
                OnboardingWelcome()
            } footer: {
                OnboardingCredits()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Enabled with nothing picked: services can be added later.
                    Button(.onboardingDone) {
                        prefs.hasCompletedOnboarding = true
                        dismiss()
                    }
                }
            }
            .task(id: prefs.region) {
                await model.load()
            }
            .environment(prefs)
        }
    }
}

// MARK: - Welcome and credits

/// Scrolls away with the grid: the user is here to pick services, not read.
/// The globe says "here and abroad" before the subtitle does.
private struct OnboardingWelcome: View {
    @ScaledMetric(relativeTo: .largeTitle) private var globeDiameter: CGFloat = 88

    var body: some View {
        VStack(spacing: Spacing.comfortable) {
            SpinningGlobe(diameter: globeDiameter)
                .accessibilityHidden(true)
            Text(.onboardingHeaderTitle)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            Text(.onboardingHeaderSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sectionGap)
    }
}

/// TMDB's terms ask for credit wherever their data shows; one quiet line.
private struct OnboardingCredits: View {
    var body: some View {
        Text(.onboardingCredits)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.sectionGap)
    }
}

#Preview {
    let prefs = Preferences(defaultRegion: .spain, defaults: UserDefaults(suiteName: "OnboardingView.preview")!)
    prefs.region = .spain
    prefs.subscribedProviderIDs = []
    return OnboardingView(
        prefs: prefs,
        catalog: ProviderCatalog(repository: PreviewMovieRepository()),
        imageURLBuilder: PreviewImageURLBuilder()
    )
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
        [(8, "Netflix"), (119, "Prime Video"), (337, "Disney Plus"), (1899, "HBO Max"),
         (149, "Movistar Plus+"), (63, "Filmin"), (350, "Apple TV+"), (1773, "SkyShowtime")]
            .enumerated()
            .map { WatchProvider(id: ProviderID($1.0), name: $1.1, logoPath: nil, priority: $0) }
    }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
