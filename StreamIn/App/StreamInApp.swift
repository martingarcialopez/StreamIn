//
//  StreamInApp.swift
//  StreamIn
//
//  Created by Martín on 28/04/2026.
//
//  Composition root. This file holds the `@main` App entry point and
//  constructs the long-lived dependencies (TMDB client, repository, provider
//  catalog, image URL builder, Preferences). Concrete implementations are
//  wired up here exactly once and passed down as protocol-typed references.
//
//  All UI lives in `RootView` / the per-tab files — this file stays UI-free
//  on purpose.
//

import SwiftUI
import Domain
import TMDBClient
import Preferences
import ReferenceData

@main
struct StreamInApp: App {

    private let imageURLBuilder: ImageURLBuilder = TMDBImageURLBuilder()
    private let prefs: Preferences = Preferences()
    private let tmdbClient: LiveTMDBClient
    private let repository: MovieRepository
    private let providerCatalog: ProviderCatalog

    init() {
        let client = LiveTMDBClient(
            config: TMDBConfig(
                apiKey: AppConfig.tmdbAPIKey,
                language: prefs.language.code
            )
        )
        let liveRepository = TMDBMovieRepository(client: client)
        let repository: MovieRepository = AppConfig.isResponseCachingEnabled
            ? CachingMovieRepository(upstream: liveRepository, currentLanguage: { client.language })
            : liveRepository

        self.tmdbClient = client
        self.repository = repository
        self.providerCatalog = ProviderCatalog(repository: repository)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                imageURLBuilder: imageURLBuilder,
                prefs: prefs,
                repository: repository,
                providerCatalog: providerCatalog,
                tmdbClient: tmdbClient
            )
            .environment(prefs)
        }
    }
}
