//
//  AppConfig.swift
//  StreamIn
//
//  Single source of truth for runtime configuration values that come from the
//  build environment (xcconfig → Run Script Phase → GeneratedSecrets.swift).
//  Route every such read through here so misconfiguration surfaces in one place.
//

import Foundation

enum AppConfig {

    /// TMDB API key, sourced from `Secrets.xcconfig` via a build-time Run Script
    /// that writes `GeneratedSecrets.swift`. Crashes early on misconfiguration:
    /// shipping a build with a missing or placeholder key would manifest as
    /// confusing 401s deep in the call stack, so we'd rather fail loudly at startup.
    static var tmdbAPIKey: String {
        let key = GeneratedSecrets.tmdbAPIKey
        guard !key.isEmpty, key != "your_tmdb_api_key_here" else {
            preconditionFailure(
                """
                Missing or placeholder TMDB_API_KEY.

                1. Get a free key at https://developer.themoviedb.org/
                2. Paste it into Secrets.xcconfig (replace the placeholder).
                3. Confirm the "Generate Secrets" Run Script Phase is present
                   on the StreamIn target, BEFORE "Compile Sources".
                4. Clean build folder (⇧⌘K) and rebuild.
                """
            )
        }
        return key
    }
}
