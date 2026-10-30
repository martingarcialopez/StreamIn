//
//  WatchlistTab.swift
//  StreamIn
//
//  Watchlist-tab NavigationStack: saved movies, and Details for the one
//  tapped (`Movie` → `MovieDetailsDestination`, the same as Search).
//

import SwiftUI
import Domain
import DesignSystem
import Preferences
import Watchlist
import WatchlistFeature

struct WatchlistTab: View {
    /// Built once by `StreamInApp`, not here: this view is recreated every
    /// time `RootView` redraws.
    let model: WatchlistViewModel
    let watchlist: WatchlistStore
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    @Binding var showingSettings: Bool
    @Binding var showingStreamingServices: Bool

    var body: some View {
        NavigationStack {
            WatchlistView(model: model)
            .cinemaBackground()
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailsDestination(
                    movie: movie,
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    prefs: prefs,
                    watchlist: watchlist,
                    onEditSubscriptions: { showingStreamingServices = true }
                )
            }
            // Settings is app-wide, so it sits on the tab's first screen only;
            // pushed screens keep their toolbar for actions about their content.
            .toolbar {
                SettingsToolbar(showingSettings: $showingSettings)
            }
        }
    }
}
