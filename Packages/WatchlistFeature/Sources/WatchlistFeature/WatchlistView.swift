//
//  WatchlistView.swift
//  WatchlistFeature
//
//  Placeholder. The real watchlist will read from a SwiftData store and render
//  saved movies grouped by some sensible axis (date added, status, etc.).
//  Adding the package + tab wiring now so the App's navigation skeleton is
//  complete and we can tackle the actual feature in a focused PR later.
//

import SwiftUI
import DesignSystem
import TMDBClient

public struct WatchlistView: View {

    private let images = TMDBImageURLBuilder()

    public init() {}

    public var body: some View {
        ContentUnavailableView {
            Label { Text(.watchlistEmptyTitle) } icon: { Image(systemName: Symbol.bookmark) }
        } description: {
            Text(.watchlistEmptyDescription)
                .foregroundColor(.secondary)
                .font(.system(size: 13))
        } actions: {
            Text("Your saved movies will show up here")
        }
        .navigationTitle(Text(.watchlistTitle))
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
    }
}
