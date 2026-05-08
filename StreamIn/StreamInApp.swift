//
//  StreamInApp.swift
//  StreamIn
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
struct StreamInApp: App {

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

/// Hosts the bottom tab bar and the settings sheet. The repository is derived
/// directly from `settings.language` in `body` so that when the language
/// changes, the new repository and the new `.id` on SearchView are produced
/// in the same render pass — the recreated SearchView always gets the correct
/// client. Using `@State` + `onChange` caused a race where the .id changed
/// one frame before the repository did, so the new SearchView was built with
/// the stale language.
private struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let settings: SettingsViewModel

    @State private var showingSettings = false

    var body: some View {
        let repository = Self.makeRepository(language: settings.language)
        TabView {
            Tab("Search", systemImage: "magnifyingglass") {
                SearchTab(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    settings: settings,
                    showingSettings: $showingSettings
                )
            }
            Tab("Watchlist", systemImage: "bookmark") {
                WatchlistTab(showingSettings: $showingSettings)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(model: settings)
            }
        }
    }

    // MARK: Repository factory

    /// `LiveTMDBClient` holds config + `URLSession.shared` — a cheap allocation,
    /// safe to call on each body evaluation triggered by a settings change.
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

// MARK: - Tabs
//
// Each tab lives in its own `View` struct (per the project convention against
// breaking views up via computed properties).

private struct SearchTab: View {
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let settings: SettingsViewModel
    @Binding var showingSettings: Bool

    var body: some View {
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
            // Per the SwiftUI guideline, image-only buttons declare their text
            // alongside the system image. SwiftUI renders just the icon in a
            // toolbar context; the text becomes the accessibility label.
            Button("Settings", systemImage: "gear") {
                showingSettings = true
            }
        }
    }
}
