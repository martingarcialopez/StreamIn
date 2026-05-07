//
//  StreamFinderApp.swift
//  StreamFinder
//
//  Created by Martín on 28/04/2026.
//

import SwiftUI
import Domain
import TMDBClient
import SearchFeature
import DetailsFeature
import WatchlistFeature
import SettingsFeature

@main
struct StreamFinderApp: App {

    /// Composition root.
    ///
    /// Owns the long-lived dependencies that don't depend on user-mutable
    /// settings: the image URL builder, and the settings store itself.
    /// The data-layer repository depends on `language` (a settings value) so
    /// it's constructed inside `RootView` and refreshed when language changes.
    private let imageURLBuilder: ImageURLBuilder = TMDBImageURLBuilder()
    private let settings: SettingsViewModel = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(
                imageURLBuilder: imageURLBuilder,
                settings: settings
            )
        }
    }
}

// MARK: - Root view (tabs + settings sheet)

/// Hosts the bottom tab bar and the settings sheet, AND owns the data-layer
/// repository (because the repository depends on `language`, a settings value
/// that can change at runtime). When language changes we rebuild the
/// repository; when either region OR language changes we force-rebuild the
/// SearchView via `.id` so its view model is reconstructed fresh.
private struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let settings: SettingsViewModel

    @State private var repository: MovieRepository
    @State private var showingSettings = false

    init(imageURLBuilder: ImageURLBuilder, settings: SettingsViewModel) {
        self.imageURLBuilder = imageURLBuilder
        self.settings = settings
        _repository = State(initialValue: Self.makeRepository(language: settings.language))
    }

    var body: some View {
        TabView {
            searchTab
            watchlistTab
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(model: settings)
            }
        }
        // Language change → rebuild the repository so the new `language=`
        // parameter rides on every subsequent TMDB call.
        .onChange(of: settings.language) { _, newLanguage in
            repository = Self.makeRepository(language: newLanguage)
        }
    }

    // MARK: Tabs

    private var searchTab: some View {
        NavigationStack {
            SearchView(model: SearchViewModel(
                repository: repository,
                imageURLBuilder: imageURLBuilder,
                region: settings.region
            ))
            // Combined identity: rebuild SearchView (and its view model)
            // whenever EITHER region OR language changes. Stale results based
            // on the previous settings would be misleading; clean refresh is
            // the right behavior.
            .id([settings.region.code, settings.language.code])
            .navigationDestination(for: Movie.self) { movie in
                DetailsView(model: DetailsViewModel(
                    movie: movie,
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    region: settings.region
                ))
            }
            .toolbar { settingsToolbar }
        }
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
    }

    private var watchlistTab: some View {
        NavigationStack {
            WatchlistView()
                .toolbar { settingsToolbar }
        }
        .tabItem {
            Label("Watchlist", systemImage: "bookmark")
        }
    }

    // MARK: Shared toolbar

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: Repository factory

    /// Builds a fresh data-layer client + repository for the given language.
    /// Called on launch and whenever the user changes language in Settings.
    private static func makeRepository(language: Language) -> MovieRepository {
        let client = LiveTMDBClient(
            config: TMDBConfig(
                apiKey: AppConfig.tmdbAPIKey,
                language: language.code
            )
        )
        return TMDBMovieRepository(client: client)
    }
}
