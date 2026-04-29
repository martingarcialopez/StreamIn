//
//  StreamFinderApp.swift
//  StreamFinder
//
//  Created by Martín on 28/04/2026.
//

import SwiftUI
import Domain
import TMDBClient

@main
struct StreamFinderApp: App {

    /// Composition root.
    ///
    /// This is the ONLY place in the entire app where concrete implementations
    /// (`LiveTMDBClient`, `TMDBMovieRepository`) are constructed. Everything
    /// downstream depends on the `MovieRepository` protocol from Domain, never
    /// on the concrete types. That's what makes features unit-testable without
    /// a network and lets us swap data sources later without touching feature code.
    private let repository: MovieRepository

    init() {
        let client = LiveTMDBClient(
            config: TMDBConfig(apiKey: AppConfig.tmdbAPIKey)
        )
        self.repository = TMDBMovieRepository(client: client)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
        }
    }
}
