//
//  Preferences.swift
//  Preferences
//
//  App-wide settings store. One instance lives for the app's lifetime (owned
//  by the composition root) and is injected wherever region or language is
//  needed. Persists to UserDefaults so choices survive app launches.
//

import Foundation
import Domain

@Observable
@MainActor
public final class Preferences {

    /// The user's streaming region (controls which providers are shown).
    public var region: Region {
        didSet { defaults.set(region.code, forKey: Self.regionKey) }
    }

    /// The user's preferred language (controls TMDB's localised output:
    /// titles, overviews, poster art).
    public var language: Language {
        didSet { defaults.set(language.code, forKey: Self.languageKey) }
    }

    /// A value type snapshot of both axes. Use this as the `id:` argument of
    /// `.task(id:)` in any view that needs to re-fire a query when either
    /// setting changes.
    public struct Snapshot: Hashable, Sendable {
        public let region: Region
        public let language: Language
        public init(region: Region, language: Language) {
            self.region = region
            self.language = language
        }
    }

    public var snapshot: Snapshot { Snapshot(region: region, language: language) }

    private let defaults: UserDefaults

    private static let regionKey   = "settings.region.code"
    private static let languageKey = "settings.language.code"

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
}
