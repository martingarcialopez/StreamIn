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

    var body: some View {
        TabView {
            Tab("Search", systemImage: "magnifyingglass") {
                SearchTab(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    showingSettings: $showingSettings
                )
            }
            Tab("Watchlist", systemImage: "bookmark") {
                WatchlistTab(showingSettings: $showingSettings)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(prefs: prefs)
            }
        }
        .onChange(of: prefs.language) { _, newLanguage in
            tmdbClient.updateLanguage(newLanguage.code)
        }
    }
}

// MARK: - Tabs

private struct SearchTab: View {
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
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
                        imageURLBuilder: imageURLBuilder
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
