//
//  MovieDetailsDestination.swift
//  StreamIn
//
//  Details for a movie pushed from any tab. Search and Watchlist both push a
//  `Movie`; building the view model here keeps their destinations identical.
//

import SwiftUI
import Domain
import Preferences
import Watchlist
import DetailsFeature

struct MovieDetailsDestination: View {
    let movie: Movie
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    let watchlist: WatchlistStore
    /// Opens the streaming-services picker, presented by `RootView`.
    let onEditSubscriptions: () -> Void

    var body: some View {
        DetailsView(
            model: DetailsViewModel(
                movie: movie,
                repository: repository,
                imageURLBuilder: imageURLBuilder,
                prefs: prefs,
                watchlist: watchlist
            ),
            onEditSubscriptions: onEditSubscriptions
        )
    }
}
