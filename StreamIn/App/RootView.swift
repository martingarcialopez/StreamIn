//
//  RootView.swift
//  StreamIn
//
//  Top-level container under `WindowGroup`. Owns the tab structure, the
//  Settings sheet, the Onboarding cover, and the launch-time task that
//  decides whether to surface onboarding.
//
//  Composition lives in `StreamInApp` — this view only wires what's already
//  been constructed.
//

import SwiftUI
import Domain
import TMDBClient
import Preferences
import SettingsFeature
import DesignSystem

struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    let repository: MovieRepository
    let tmdbClient: LiveTMDBClient

    @State private var showingSettings = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView {
            Tab {
                SearchTab(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    prefs: prefs,
                    showingSettings: $showingSettings
                )
            } label: {
                Label {
                    Text(.tabSearch)
                } icon: {
                    Image(systemName: Symbol.magnifyingglass)
                }
            }
            Tab {
                WatchlistTab(showingSettings: $showingSettings)
            } label: {
                Label {
                    Text(.tabWatchlist)
                } icon: {
                    Image(systemName: Symbol.bookmark)
                }
            }
        }
        .tint(AppPalette.accent)
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
