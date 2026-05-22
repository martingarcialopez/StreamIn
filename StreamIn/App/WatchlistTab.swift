//
//  WatchlistTab.swift
//  StreamIn
//
//  Watchlist-tab NavigationStack. The Watchlist screen itself is a
//  placeholder until Phase 3 (Persistence + Watchlist feature).
//

import SwiftUI
import WatchlistFeature

struct WatchlistTab: View {
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
