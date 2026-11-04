//
//  StreamInApp.swift
//  StreamIn
//
//  Created by Martín on 28/04/2026.
//
//  Composition root. This file holds the `@main` App entry point and
//  constructs the long-lived dependencies (TMDB client, repository, provider
//  and region catalogs, image URL builder, Preferences, watchlist, and the models of the
//  Search landing page and the Watchlist tab, which live as long as their
//  tabs do). Concrete implementations are wired up here exactly once and
//  passed down as protocol-typed references.
//
//  All UI lives in `RootView` / the per-tab files — this file stays UI-free
//  on purpose.
//

import SwiftUI
import OSLog
import Domain
import TMDBClient
import Preferences
import ReferenceData
import Persistence
import Watchlist
import SearchFeature
import WatchlistFeature

private let logger = Logger(subsystem: "StreamIn", category: "watchlist")

@main
struct StreamInApp: App {

    private let imageURLBuilder: ImageURLBuilder = TMDBImageURLBuilder()
    private let prefs: Preferences = Preferences()
    private let tmdbClient: LiveTMDBClient
    private let repository: MovieRepository
    private let providerCatalog: ProviderCatalog
    private let regionCatalog: RegionCatalog
    private let watchlist: WatchlistStore
    private let watchlistModel: WatchlistViewModel
    private let landingModel: LandingViewModel

    init() {
        let usesFixtures = AppConfig.isUsingUITestFixtures
        let client = LiveTMDBClient(
            config: TMDBConfig(
                // CI has only the placeholder key.
                apiKey: usesFixtures ? "" : AppConfig.tmdbAPIKey,
                language: prefs.contentLanguage.code
            )
        )
        self.tmdbClient = client
        self.repository = Self.makeMovieRepository(client: client, usesFixtures: usesFixtures)
        let repository = self.repository

        self.providerCatalog = ProviderCatalog(repository: repository)
        self.regionCatalog = RegionCatalog(repository: repository)
        let watchlist = WatchlistStore(repository: Self.makeWatchlistRepository())
        self.watchlist = watchlist
        self.watchlistModel = WatchlistViewModel(
            store: watchlist,
            repository: repository,
            imageURLBuilder: imageURLBuilder,
            prefs: prefs
        )
        self.landingModel = LandingViewModel(
            repository: repository,
            catalog: providerCatalog,
            prefs: prefs,
            imageURLBuilder: imageURLBuilder
        )
    }

    /// TMDB behind the response cache, or canned data for UI tests.
    private static func makeMovieRepository(client: LiveTMDBClient, usesFixtures: Bool) -> MovieRepository {
        #if DEBUG
        if usesFixtures { return FixtureMovieRepository() }
        #endif
        let liveRepository = TMDBMovieRepository(client: client)
        return AppConfig.isResponseCachingEnabled
            ? CachingMovieRepository(upstream: liveRepository, currentLanguage: { client.language })
            : liveRepository
    }

    /// The on-disk store, or a throwaway in-memory one when the launch
    /// environment asks for it. If the store can't be opened, the app still
    /// launches: this session's watchlist lives in memory and the failure is
    /// logged, rather than crashing on every launch.
    private static func makeWatchlistRepository() -> any WatchlistRepository {
        let storage: WatchlistStorage = AppConfig.isWatchlistInMemory ? .inMemory : .appDefault
        do {
            return try WatchlistPersistence.makeRepository(storage: storage)
        } catch {
            logger.error("Couldn't open the watchlist store (\(String(describing: error), privacy: .public)); using an in-memory one for this launch.")
            do {
                return try WatchlistPersistence.makeRepository(storage: .inMemory)
            } catch {
                preconditionFailure("Couldn't create even an in-memory watchlist store: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                imageURLBuilder: imageURLBuilder,
                prefs: prefs,
                repository: repository,
                providerCatalog: providerCatalog,
                regionCatalog: regionCatalog,
                watchlist: watchlist,
                watchlistModel: watchlistModel,
                landingModel: landingModel,
                tmdbClient: tmdbClient
            )
            .environment(prefs)
        }
    }
}
