//
//  RootView.swift
//  StreamIn
//
//  Top-level container under `WindowGroup`. Owns the tab structure, the
//  Settings sheet, the Onboarding cover, and the launch-time tasks that
//  preload provider reference data and decide whether to surface onboarding.
//
//  Composition lives in `StreamInApp` — this view only wires what's already
//  been constructed.
//

import SwiftUI
import Domain
import TMDBClient
import Preferences
import ReferenceData
import SettingsFeature
import DesignSystem
import Watchlist

struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    let repository: MovieRepository
    let providerCatalog: ProviderCatalog
    let watchlist: WatchlistStore
    let tmdbClient: LiveTMDBClient

    @State private var showingSettings = false
    @State private var showingStreamingServices = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView {
            Tab {
                SearchTab(
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    prefs: prefs,
                    watchlist: watchlist,
                    showingSettings: $showingSettings,
                    showingStreamingServices: $showingStreamingServices
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
        // The two sheets and `.fullScreenCover(showingOnboarding)` coexist
        // intentionally. They're coordinated by their bindings:
        //   - `showingOnboarding` is flipped exactly once per launch by the
        //     `.task` below, only when the user has no subscriptions.
        //   - `showingSettings` is flipped only via the gear button on a
        //     tab's first screen, and `showingStreamingServices` only via a
        //     button on Details — both unreachable while the onboarding
        //     cover is up, and never on screen at the same time.
        // If a future change ever makes two fire simultaneously, chain them
        // (e.g. open Settings on the `OnboardingView` dismiss) rather than
        // racing.
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    prefs: prefs,
                    catalog: providerCatalog,
                    imageURLBuilder: imageURLBuilder
                )
            }
        }
        .sheet(isPresented: $showingStreamingServices) {
            StreamingServicesSheet(
                prefs: prefs,
                catalog: providerCatalog,
                imageURLBuilder: imageURLBuilder
            )
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(
                prefs: prefs,
                catalog: providerCatalog,
                imageURLBuilder: imageURLBuilder
            )
        }
        .onChange(of: prefs.language) { _, newLanguage in
            tmdbClient.updateLanguage(newLanguage.code)
        }
        // Provider reference data is loaded at launch (and for each new
        // region), so Settings and Onboarding render complete on their first
        // frame. Doesn't block launch: the tabs are usable meanwhile.
        .task(id: prefs.region) {
            await providerCatalog.load(region: prefs.region)
            prefetchSubscribedProviderLogos()
        }
        // Saved movies load at launch, so Details' heart and the Watchlist
        // tab are right on their first frame.
        .task {
            await watchlist.load()
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

    /// Warms the image store with the logos of the user's services — the
    /// ones Settings shows in its summary row — so they appear without a
    /// placeholder flash.
    private func prefetchSubscribedProviderLogos() {
        let urls = prefs.subscribedProviderIDs
            .compactMap { providerCatalog.provider(id: $0)?.logoPath }
            .compactMap { imageURLBuilder.url(for: $0, size: .providerLogo) }
        RemoteImageStore.shared.prefetch(urls)
    }
}
