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

public struct WatchlistView: View {

    public init() {}

    public var body: some View {
        ContentUnavailableView {
            Label { Text(.watchlistEmptyTitle) } icon: { Image(systemName: "bookmark") }
        } description: {
            Text(.watchlistEmptyDescription)
        }
        .navigationTitle(Text(.watchlistTitle))
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
    }
}
