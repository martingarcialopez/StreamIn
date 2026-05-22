//
//  SearchTab.swift
//  StreamIn
//
//  Search-tab NavigationStack and its two navigation destinations
//  (`SearchResultsRoute` → results, `Movie` → details). Owns the
//  `NavigationPath` so submissions from `LandingView` can push results.
//

import SwiftUI
import Domain
import Preferences
import SearchFeature
import DetailsFeature

struct SearchTab: View {
    let repository: MovieRepository
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    @Binding var showingSettings: Bool

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            SearchView(onSearch: { query in
                path.append(SearchResultsRoute(query: query))
            })
            .navigationDestination(for: SearchResultsRoute.self) { route in
                SearchResultsView(
                    model: SearchViewModel(
                        repository: repository,
                        imageURLBuilder: imageURLBuilder
                    ),
                    initialQuery: route.query
                )
            }
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
