//
//  SettingsViewModel.swift
//  SettingsFeature
//
//  App-wide settings store. Single instance owned by the App's composition
//  root and shared with both `SettingsView` (for editing) and `RootView`
//  (which uses `region` and `language` to construct the per-screen view models
//  and the data-layer client).
//
//  Persists to UserDefaults so choices survive app launches.
//

import Foundation
import Domain

@Observable
@MainActor
public final class SettingsViewModel {

    /// Currently-selected region (controls which streaming services are
    /// shown). Mutating triggers observation + persistence.
    public var region: Region {
        didSet { persistRegion() }
    }

    /// Currently-selected language (controls TMDB's localized output:
    /// movie titles, overviews, poster art). Mutating triggers observation
    /// + persistence, AND in `RootView` rebuilds the data-layer client so
    /// subsequent calls go out with the new `language=` parameter.
    public var language: Language {
        didSet { persistLanguage() }
    }

    /// Injected so tests can pass an isolated `UserDefaults(suiteName:)` and
    /// verify the round-trip without polluting the standard suite.
    private let defaults: UserDefaults

    public init(
        defaultRegion: Region = .currentLocale,
        defaultLanguage: Language = .currentLocale,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults

        if let stored = defaults.string(forKey: Self.regionKey), !stored.isEmpty {
            self.region = Region(code: stored)
        } else {
            self.region = defaultRegion
        }

        if let stored = defaults.string(forKey: Self.languageKey), !stored.isEmpty {
            self.language = Language(code: stored)
        } else {
            self.language = defaultLanguage
        }
    }

    // MARK: - Persistence

    private static let regionKey = "settings.region.code"
    private static let languageKey = "settings.language.code"

    private func persistRegion() {
        defaults.set(region.code, forKey: Self.regionKey)
    }

    private func persistLanguage() {
        defaults.set(language.code, forKey: Self.languageKey)
    }
}
