//
//  StreamInApp.swift
//  StreamIn
//
//  Created by Martín on 28/04/2026.
//
//  Composition root. This file holds the `@main` App entry point and
//  constructs the long-lived dependencies (TMDB client, repository, image
//  URL builder, Preferences). Concrete implementations are wired up here
//  exactly once and passed down as protocol-typed references.
//
//  All UI lives in `RootView` / the per-tab files — this file stays UI-free
//  on purpose.
//

import SwiftUI
import Domain
import TMDBClient
import Preferences

@main
struct StreamInApp: App {

    private let imageURLBuilder: ImageURLBuilder = TMDBImageURLBuilder()
    private let prefs: Preferences = Preferences()
    private let tmdbClient: LiveTMDBClient
    private let repository: MovieRepository

    init() {
        let client = LiveTMDBClient(
            config: TMDBConfig(
                apiKey: AppConfig.tmdbAPIKey,
                language: prefs.language.code
            )
        )
        self.tmdbClient = client
        self.repository = TMDBMovieRepository(client: client)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                imageURLBuilder: imageURLBuilder,
                prefs: prefs,
                repository: repository,
                tmdbClient: tmdbClient
            )
            .environment(prefs)
        }
    }
}
