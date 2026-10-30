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
import SearchFeature
import SettingsFeature
import DesignSystem
import Watchlist
import WatchlistFeature

struct RootView: View {
    let imageURLBuilder: ImageURLBuilder
    let prefs: Preferences
    let repository: MovieRepository
    let providerCatalog: ProviderCatalog
    let watchlist: WatchlistStore
    let watchlistModel: WatchlistViewModel
    let landingModel: LandingViewModel
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
                    landingModel: landingModel,
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
                WatchlistTab(
                    model: watchlistModel,
                    watchlist: watchlist,
                    repository: repository,
                    imageURLBuilder: imageURLBuilder,
                    prefs: prefs,
                    showingSettings: $showingSettings,
                    showingStreamingServices: $showingStreamingServices
                )
            } label: {
                Label {
                    Text(.tabWatchlist)
                } icon: {
                    Image(systemName: Symbol.heart)
                }
            }
        }
        .tint(AppPalette.accent)
        // StreamIn is always dark: every screen sits on the cinema background.
        .preferredColorScheme(.dark)
        // A heart or a swipe whose write failed was undone; say so once,
        // whichever tab it came from.
        .watchlistWriteFailureAlert(watchlist)
        // The two sheets and `.fullScreenCover(showingOnboarding)` coexist
        // intentionally. They're coordinated by their bindings:
        //   - `showingOnboarding` is flipped exactly once per launch by the
        //     `.task` below, only until onboarding has been completed.
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
                .cinemaBackground()
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
        // First launch only: Done in onboarding sets the flag, even with no
        // services picked.
        .task {
            if !prefs.hasCompletedOnboarding {
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
