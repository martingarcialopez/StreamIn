//
//  StreamInApp.swift
//  StreamIn
//
//  Created by Martín on 28/04/2026.
//

import SwiftUI
import Domain
import TMDBClient
import Preferences
import SearchFeature
import DetailsFeature
import WatchlistFeature
import SettingsFeature

@main
struct StreamInApp: App {

    /// Composition root. All long-lived dependencies live here.
    ///
    /// The TMDB client is held as a single instance for the app's lifetime; its
    /// `language` parameter is mutated in place via `updateLanguage(_:)` when
    /// the user changes the setting, so subsequent requests automatically pick
    /// up the new value.
    private let imageURLBuilder: ImageURLBuilder = TMDBImageURLBuilder()
    private let prefs: Preferences = Preferences()
    private let tmdbClient: LiveTMDBClient
    private let repository: MovieRepository

    init() {
        let client = LiveTMDBClient(
            config: TMDBConfig(
                apiKey: AppConfig.tmdbAPIKey,
                language: prefs.language.code
            )
        )
        self.tmdbClient = client
        self.repository = TMDBMovieRepository(client: client)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                imageURLBuilder: imageURLBuilder,
                prefs: prefs,
                repository: repository,
                tmdbClient: tmdbClient
            )
            .environment(prefs)
        }
    }
}

// MARK: - Root view (tabs + settings sheet)

private struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    let repository: MovieRepository
    let tmdbClient: LiveTMDBClient

    @State private var showingSettings = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView {
            Tab("Search", systemImage: "magnifyingglass") {
                SearchTab(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    prefs: prefs,
                    showingSettings: $showingSettings
                )
            }
            Tab("Watchlist", systemImage: "bookmark") {
                WatchlistTab(showingSettings: $showingSettings)
            }
        }
        // `.sheet(showingSettings)` and `.fullScreenCover(showingOnboarding)`
        // coexist intentionally. They're coordinated by their bindings:
        //   - `showingOnboarding` is flipped exactly once per launch by the
        //     `.task` below, only when the user has no subscriptions.
        //   - `showingSettings` is flipped only via the user tapping the
        //     gear button in the toolbar — unreachable while the onboarding
        //     cover is up.
        // If a future change ever makes both fire simultaneously, chain them
        // (e.g. open Settings on the `OnboardingView` dismiss) rather than
        // racing.
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    prefs: prefs,
                    repository: repository,
                    imageURLBuilder: imageURLBuilder
                )
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(
                prefs: prefs,
                repository: repository,
                imageURLBuilder: imageURLBuilder
            )
        }
        .onChange(of: prefs.language) { _, newLanguage in
            tmdbClient.updateLanguage(newLanguage.code)
        }
        // TODO: ship-time trigger should be a first-launch flag persisted in
        // `Preferences` (e.g. `hasCompletedOnboarding: Bool`). The current
        // "empty subscriptions" rule re-triggers the sheet every launch
        // until the user picks at least one service, which is exactly what
        // we want during the test phase to make the flow easy to retrigger.
        // See CLAUDE.md "TODO: onboarding trigger".
        .task {
            if prefs.subscribedProviderIDs.isEmpty {
                showingOnboarding = true
            }
        }
    }
}

// MARK: - Tabs

private struct SearchTab: View {
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    @Binding var showingSettings: Bool

    var body: some View {
        NavigationStack {
            SearchView(
                model: SearchViewModel(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder
                )
            )
            .navigationDestination(for: Movie.self) { movie in
                DetailsView(
                    model: DetailsViewModel(
                        movie: movie,
                        repository: repository,
                        imageURLBuilder: imageURLBuilder,
                        prefs: prefs
                    )
                )
            }
            .toolbar {
                SettingsToolbar(showingSettings: $showingSettings)
            }
        }
    }
}

private struct WatchlistTab: View {
    @Binding var showingSettings: Bool

    var body: some View {
        NavigationStack {
            WatchlistView()
                .toolbar {
                    SettingsToolbar(showingSettings: $showingSettings)
                }
        }
    }
}

// MARK: - Shared toolbar

private struct SettingsToolbar: ToolbarContent {
    @Binding var showingSettings: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gear") {
                showingSettings = true
            }
        }
    }
}
